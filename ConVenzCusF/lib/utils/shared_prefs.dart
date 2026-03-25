import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPreferences? _prefs;

  static Future init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---------------- PHONE ----------------
  static Future savePhone(String phone) async => await _prefs?.setString("phone", phone);
  static String? getPhone() => _prefs?.getString("phone");

  // ---------------- USER ID ----------------
  static Future saveUserId(String id) async => await _prefs?.setString("userId", id);
  static String? getUserId() => _prefs?.getString("userId");

  // ---------------- JWT TOKEN ----------------
  static Future saveToken(String token) async => await _prefs?.setString("jwt_token", token);
  static String? getToken() => _prefs?.getString("jwt_token");

  // ---------------- NAME ----------------
  static Future saveUserName(String name) async => await _prefs?.setString("userName", name);
  static String? getUserName() => _prefs?.getString("userName");

  // ---------------- GENDER ----------------
  static Future saveGender(String gender) async => await _prefs?.setString("gender", gender);
  static String? getGender() => _prefs?.getString("gender");

  // ---------------- NEW / EXISTING USER ----------------
  static Future saveIsNewUser(bool value) async => await _prefs?.setBool("isNewUser", value);
  static bool getIsNewUser() => _prefs?.getBool("isNewUser") ?? true;

  // ----------------------------------------------------------
  // 📍 LAST SYNCED LOCATION (For 2km Tracking)
  // ----------------------------------------------------------
  static Future saveLastSyncedLocation(double lat, double lng) async {
    await _prefs?.setDouble('last_synced_lat', lat);
    await _prefs?.setDouble('last_synced_lng', lng);
  }

  static Map<String, double>? getLastSyncedLocation() {
    final lat = _prefs?.getDouble('last_synced_lat');
    final lng = _prefs?.getDouble('last_synced_lng');
    if (lat != null && lng != null) {
      return {'lat': lat, 'lng': lng};
    }
    return null;
  }

  // ----------------------------------------------------------
  // 🚀 CLEAR ALL SAVED DATA (Used for Logout)
  // ----------------------------------------------------------
  static Future clear() async {
    await _prefs?.clear(); // Clears ALL stored user info
  }
}
