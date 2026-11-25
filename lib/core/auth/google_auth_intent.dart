import 'package:shared_preferences/shared_preferences.dart';

enum GoogleAuthIntent { login, signup }

abstract final class GoogleAuthFlow {
  static const _key = 'google_auth_intent';

  static Future<void> start(GoogleAuthIntent intent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, intent.name);
  }

  static Future<GoogleAuthIntent?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_key)) {
      'signup' => GoogleAuthIntent.signup,
      'login' => GoogleAuthIntent.login,
      _ => null,
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
