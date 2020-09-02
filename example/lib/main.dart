import 'package:flutter/material.dart';
import 'google_web_login.dart';
import 'google_oauth_credentials.dart';
import 'route_generator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      onGenerateRoute: RouteGenerator.generateRoute,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // home: MyHomePage(this.responseQueryParameters),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GoogleLoginWebWidget(
      googleClientId: googleClientId,
      googleClientSecret: googleClientSecret,
      googleScopes: googleScopes,
      responseQueryParameters: null,
    );
    // return FacebookLoginWebWidget(
    //   facebookClientId: facebookClientId,
    //   facebookClientSecret: facebookClientSecret,
    //   facebookScopes: facebookScopes,
    //   responseQueryParameters: null,
    // );
    // return FacebookLogin();
  }
}
