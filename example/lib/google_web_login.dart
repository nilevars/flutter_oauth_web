import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_oauth_web/flutter_oauth_web.dart' as oauth2;
import 'dart:html' as html;
import 'package:flutter_session/flutter_session.dart';
import 'dart:async';
import 'package:flutter/services.dart';

final _authorizationEndpoint = Uri.parse(
    'https://accounts.google.com/o/oauth2/v2/auth?access_type=offline&prompt=consent&ux_mode=popup');
final _tokenEndpoint = Uri.parse('https://www.googleapis.com/oauth2/v4/token');

class GoogleLoginWebWidget extends StatefulWidget {
  GoogleLoginWebWidget(
      {@required this.googleClientId,
      @required this.googleClientSecret,
      @required this.googleScopes,
      @required this.responseQueryParameters});
  final String googleClientId;
  final String googleClientSecret;
  final Map<String, String> responseQueryParameters;
  final List<String> googleScopes;
  @override
  _GoogleLoginWebWidgetState createState() => _GoogleLoginWebWidgetState();
}

class _GoogleLoginWebWidgetState extends State<GoogleLoginWebWidget> {
  Future<oauth2.Client> _client;
  oauth2.Oauth2Web grant;
  Uri _authorizationUrl;
  var _redirectUrl =
      Uri.parse('http://localhost:7357'); //whitelist it in google console
  @override
  void initState() {
    super.initState();
    if (widget.googleClientId.isEmpty || widget.googleClientSecret.isEmpty) {
      print("client id and secret null");
      throw const GoogleLoginException(
          'googleClientId and googleClientSecret must be not empty. '
          'See `lib/google_oauth_credentials.dart` for more detail.');
    }
    grant = oauth2.Oauth2Web(
      widget.googleClientId,
      _authorizationEndpoint,
      _tokenEndpoint,
      secret: widget.googleClientSecret,
      httpClient: _JsonAcceptingHttpClient(),
    );
  }

  Future<oauth2.Client> _getClient() async {
    String codeVerifier = await FlutterSession().get("codeVerifier");
    var client = await grant.handleAuthorizationResponse(
        widget.responseQueryParameters,
        codeVerifier: codeVerifier,
        redirect: _redirectUrl);
    return client;
  }

  Widget displayClient() {
    return FutureBuilder<oauth2.Client>(
      future: _client,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cardinal'),
            ),
            body: Center(
              child: Column(
                children: [
                  Text(
                    'You are logged in to google!',
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SelectableText(
                    snapshot.data.credentials.toJson(),
                    style: TextStyle(fontSize: 10),
                    onTap: () {
                      Clipboard.setData(new ClipboardData(
                              text: snapshot.data.credentials.toJson()))
                          .then((_) {
                        Scaffold.of(context).showSnackBar(SnackBar(
                            content:
                                Text("Email address copied to clipboard")));
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.responseQueryParameters != null) {
      String code = widget.responseQueryParameters['code'];
      setState(() {
        _client = _getClient();
      });
      return displayClient();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cardinal'),
      ),
      body: Center(
        child: RaisedButton(
          onPressed: () async {
            _goToAuth(_redirectUrl);
          },
          child: const Text('Login to Google'),
        ),
      ),
    );
  }

  void _goToAuth(Uri redirectUrl) async {
    if (widget.googleClientId.isEmpty || widget.googleClientSecret.isEmpty) {
      print("client id and secret null");
      throw const GoogleLoginException(
          'googleClientId and googleClientSecret must be not empty. '
          'See `lib/google_oauth_credentials.dart` for more detail.');
    }
    oauth2.CodeVerifier _codeVerfier = new oauth2.CodeVerifier();
    String cv = await FlutterSession()
        .set("codeVerifier", _codeVerfier.getCodeVerifier());
    _authorizationUrl = grant.getAuthorizationUrl(_redirectUrl,
        scopes: widget.googleScopes,
        codeVerifier: _codeVerfier.getCodeVerifier());

    print(cv);
    await _redirect(_authorizationUrl);
  }

  Future<void> _redirect(Uri authorizationUrl) async {
    var url = authorizationUrl.toString();
    print("AuthorizationUrl is $url");
    var popup = html.window.open(url, "_self");
    print(popup.parent);
  }
}

class _JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}

class GoogleLoginException implements Exception {
  const GoogleLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}
