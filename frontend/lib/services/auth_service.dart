import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/shared_prefs.dart';
import '../utils/address_formatter.dart';

class AuthService {
  /// Register user with phone and FCM token
  static Future<Map<String, dynamic>> registerUser(String phone) async {
    final String? fcmToken = NotificationService.getFcmToken();

    final res = await ApiService.post("/user/register", {
      "phone": phone,
      if (fcmToken != null && fcmToken.isNotEmpty) "fcmToken": fcmToken,
    });

    if (res["success"] == true) {
      await SharedPrefs.savePhone(phone);
      if (res["userId"] != null) {
        await SharedPrefs.saveUserId(res["userId"].toString());
      }
      await SharedPrefs.saveIsNewUser(res["isNewUser"] ?? true);
      // Refresh and send FCM token as a backup after registration
      NotificationService.refreshAndSendToken().catchError((_) {});
    }
    return res;
  }

  /// Verify OTP and save auth token
  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp) async {
    final res = await ApiService.post(
        "/user/verify-otp", {"phone": phone, "otp": otp});

    if (res["success"] == true) {
      if (res["token"] != null) {
        await SharedPrefs.saveToken(res["token"]);
      }

      final userId = res["userId"]?.toString() ??
          res["user"]?["user_id"]?.toString();
      if (userId != null) {
        await SharedPrefs.saveUserId(userId);
      }

      await SharedPrefs.saveIsNewUser(res["isNewUser"] ?? true);
      NotificationService.refreshAndSendToken().catchError((_) {});
    }
    return res;
  }

  /// Update user profile details (name, gender)
  static Future<Map<String, dynamic>> updateUserDetails(
      String _, String name, String gender) async {
    final res = await ApiService.post("/update-user", {
      "name": name,
      "gender": gender,
    });

    if (res["success"] == true) {
      await SharedPrefs.saveUserName(name);
      await SharedPrefs.saveGender(gender);
      await SharedPrefs.saveIsNewUser(false);
    }
    return res;
  }

  /// Get the user's full profile from the backend
  static Future<Map<String, dynamic>> getUserDetails(String userId) async {
    return ApiService.get("/user/profile/$userId");
  }

  /// Update the user's current location (with reverse geocoding)
  static Future<Map<String, dynamic>> updateUserLocation(
      String userId, double latitude, double longitude) async {
    final String cleanAddress =
        await AddressFormatter.getCleanAddress(latitude, longitude);

    return ApiService.post("/user/update-location", {
      "latitude": latitude,
      "longitude": longitude,
      "address": cleanAddress,
    });
  }
}