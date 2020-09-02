import 'package:flutter/material.dart';
import 'main.dart';
import 'google_oauth_credentials.dart';
import 'google_web_login.dart';
import 'dart:html' as html;

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    print("Settings is ${settings.name}");
    switch (settings.name) {
      case '/':
        if (html.window.location.href.contains("code") &&
            (html.window.location.href.contains("google"))) {
          String url = html.window.location.href
              .replaceFirst("#/", ""); // workaround for readable redirect url
          Uri uri = Uri.parse(url);
          if (uri.queryParameters.keys.contains("code")) {
            return MaterialPageRoute(
              builder: (_) {
                return GoogleLoginWebWidget(
                  googleClientId: googleClientId,
                  googleClientSecret: googleClientSecret,
                  googleScopes: googleScopes,
                  responseQueryParameters: uri.queryParameters,
                );
              },
            );
          }
        } else {
          return MaterialPageRoute(
              builder: (_) {
                return MyHomePage();
              },
              settings: settings);
        }
        return MaterialPageRoute(
            builder: (_) {
              return MyHomePage();
            },
            settings: settings);
        break;
      case '/googlecallback':
        if (html.window.location.href.contains("code")) {
          String url = html.window.location.href
              .replaceFirst("#/", ""); // workaround for readable redirect url
          Uri uri = Uri.parse(url);
          if (uri.queryParameters != null) {
            return MaterialPageRoute(
                builder: (_) {
                  return GoogleLoginWebWidget(
                    googleClientId: googleClientId,
                    googleClientSecret: googleClientSecret,
                    googleScopes: googleScopes,
                    responseQueryParameters: uri.queryParameters,
                  );
                },
                settings: settings);
          }
        }
        return _errorRoute(settings);
      default:
        return _errorRoute(settings);
    }
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Error Route"),
        ),
        body: Center(
          child: Text("Error Route. No route defines for ${settings.name}"),
        ),
      );
    });
  }
}
