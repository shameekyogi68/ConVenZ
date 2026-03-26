import '../utils/shared_prefs.dart';
import '../core/network/api_client.dart';
import 'package:dio/dio.dart';

class ProfileService {
  // 🔹 GET USER PROFILE
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final userId = SharedPrefs.getUserId();

      if (userId == null) {
        return {"success": false, "message": "❌ User ID not found"};
      }

      print("📡 Fetching Profile for User ID: $userId");
      // Calls /api/user/profile/1
      final response = await ApiClient.instance.get("/user/profile/$userId");
      
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      return {"success": true, "data": response.data};
      
    } on DioException catch (e) {
      print("❌ Profile Service Error: ${e.message}");
      return {
        "success": false,
        "message": "Failed to fetch profile: ${e.response?.statusMessage ?? e.message}"
      };
    } catch (e) {
      print("❌ Profile Service Error: $e");
      return {
        "success": false,
        "message": "Failed to fetch profile: $e"
      };
    }
  }

  // 🔹 UPDATE PROFILE
  static Future<Map<String, dynamic>> updateProfile({required String name}) async {
    try {
      final userId = SharedPrefs.getUserId();
      final phone = SharedPrefs.getPhone();

      if (userId == null) {
        return {"success": false, "message": "❌ User ID not found"};
      }

      final response = await ApiClient.instance.post(
        "/profile/$userId",
        data: {
          "name": name,
          "phone": phone,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData["success"] == true && responseData["data"] != null) {
        await SharedPrefs.saveUserName(responseData["data"]["name"]);
      }

      return responseData;
    } on DioException catch (e) {
      return {
        "success": false,
        "message": "Failed to update profile: ${e.message}"
      };
    } catch (e) {
      return {"success": false, "message": "Failed to update profile: $e"};
    }
  }
}