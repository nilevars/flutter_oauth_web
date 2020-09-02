import 'dart:math';

class CodeVerifier {
  String _codeVerifier;
  static const String _charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  CodeVerifier() {
    _codeVerifier = _createCodeVerifier();
  }

  String getCodeVerifier() {
    return _codeVerifier;
  }

  static String _createCodeVerifier() {
    return List.generate(
        128, (i) => _charset[Random.secure().nextInt(_charset.length)]).join();
  }
}
