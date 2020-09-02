import 'oauth2/lib/oauth2.dart' as oauth2;
import 'oauth2/lib/src/utils.dart';
import 'oauth2/lib/src/client.dart';
import 'oauth2/lib/src/authorization_exception.dart';
import 'oauth2/lib/src/handle_access_token_response.dart';
import 'oauth2/lib/src/parameters.dart';
import 'oauth2/lib/src/credentials.dart';
import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class Oauth2Web extends oauth2.AuthorizationCodeGrant {
  List<String> _scopes;
  Uri _redirectEndpoint;
  final http.Client httpClient;
  final GetParameters _getParameters = parseJsonParameters;

  /// Whether to use HTTP Basic authentication for authorizing the client.
  final bool _basicAuth = true;
  final String _delimiter = ' ';

  /// Callback to be invoked whenever the credentials are refreshed.
  ///
  /// This will be passed as-is to the constructed [Client].
  final CredentialsRefreshedCallback _onCredentialsRefreshed = null;

  Oauth2Web(
    String identifier,
    Uri authorizationEndpoint,
    Uri tokenEndpoint, {
    String secret,
    this.httpClient,
  }) : super(identifier, authorizationEndpoint, tokenEndpoint,
            secret: secret, httpClient: null);

  Uri getAuthorizationUrl(Uri redirect,
      {Iterable<String> scopes, String state, String codeVerifier}) {
    if (scopes == null) {
      scopes = [];
    } else {
      scopes = scopes.toList();
    }

    // _codeVerifier = _createCodeVerifier();
    var codeChallenge = base64Url
        .encode(sha256.convert(ascii.encode(codeVerifier)).bytes)
        .replaceAll('=', '');

    _redirectEndpoint = redirect;
    _scopes = scopes;
    var parameters = {
      'response_type': 'code',
      'client_id': identifier,
      'redirect_uri': redirect.toString(),
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256'
    };
    if (scopes.isNotEmpty) parameters['scope'] = scopes.join(_delimiter);
    print(parameters);

    return addQueryParameters(authorizationEndpoint, parameters);
  }

  Future<Client> handleAuthorizationResponse(Map<String, String> parameters,
      {String codeVerifier, Uri redirect}) async {
    if (parameters.containsKey('error')) {
      var description = parameters['error_description'];
      var uriString = parameters['error_uri'];
      var uri = uriString == null ? null : Uri.parse(uriString);
      throw AuthorizationException(parameters['error'], description, uri);
    } else if (!parameters.containsKey('code')) {
      throw FormatException('Invalid OAuth response for '
          '"$authorizationEndpoint": did not contain required parameter '
          '"code".');
    }

    return await _handleAuthorizationCode(
        parameters['code'], codeVerifier, redirect);
  }

  Future<Client> handleAuthorizationCode(String authorizationCode,
      {String codeVerifier, Uri redirect}) async {
    return await _handleAuthorizationCode(
        authorizationCode, codeVerifier, redirect);
  }

  Future<Client> _handleAuthorizationCode(
      String authorizationCode, String codeVerifier, Uri redirect) async {
    print("In handle auth code");
    var startTime = DateTime.now();

    var headers = <String, String>{};
    _redirectEndpoint = redirect;
    var body = {
      'grant_type': 'authorization_code',
      'code': authorizationCode,
      'redirect_uri': _redirectEndpoint.toString(),
      'code_verifier': codeVerifier
    };

    if (_basicAuth && secret != null) {
      headers['Authorization'] = basicAuthHeader(identifier, secret);
    } else {
      // The ID is required for this request any time basic auth isn't being
      // used, even if there's no actual client authentication to be done.
      body['client_id'] = identifier;
      if (secret != null) body['client_secret'] = secret;
    }
    try {
      var response = await httpClient.post(tokenEndpoint,
          headers: headers, body: json.encode(body));
      var credentials = handleAccessTokenResponse(
          response, tokenEndpoint, startTime, _scopes, _delimiter,
          getParameters: _getParameters);
      return Client(credentials,
          identifier: identifier,
          secret: secret,
          basicAuth: _basicAuth,
          httpClient: httpClient,
          onCredentialsRefreshed: _onCredentialsRefreshed);
    } catch (e) {
      throw new Exception(e);
    }
  }
}
