import 'package:shared_preferences/shared_preferences.dart';

enum PrefKey {
  currencySymbol,
  pin,
  password,
}

class SharedPreferenceHelper {
  static Future<void> save({
    required String value,
    required PrefKey prefKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(prefKey.name, value);
  }

  static Future<String?> get({required PrefKey prefKey}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefKey.name);
  }

  static Future<bool> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(PrefKey.pin.name, pin);
  }

  static Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKey.pin.name);
  }

  static Future<bool> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(PrefKey.password.name, password);
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKey.password.name);
  }

  static Future<void> deleteSpecific({required PrefKey prefKey}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefKey.name);
  }
}
