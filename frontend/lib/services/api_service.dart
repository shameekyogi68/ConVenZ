import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';
import '../utils/shared_prefs.dart';

class ApiService {
  // Use centralized configuration from AppConstants
  static String get baseUrl => AppConstants.userBaseUrl;


  // -----------------------
  // POST REQUEST
  // -----------------------
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {

    final String url = "$baseUrl$endpoint";
    final String? token = SharedPrefs.getToken();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // -----------------------
  // GET REQUEST
  // -----------------------
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final String url = "$baseUrl$endpoint";
    final String? token = SharedPrefs.getToken();

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // -----------------------
  // RESPONSE HANDLER
  // -----------------------
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> body = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return body;
      } else if (response.statusCode == 403) {
        // Handle blocked user response
        return {
          "success": false,
          "blocked": body['blocked'] ?? false,
          "blockReason": body['blockReason'] ?? 'Your account has been blocked by admin.',
          "message": body['message'] ?? 'Account blocked',
          "statusCode": 403,
        };
      } else {
        return {
          "success": false,
          "message": body['message'] ?? "Server error: ${response.statusCode}",
          "statusCode": response.statusCode,
        };
      }
    } catch (e) {
      return {"success": false, "message": "Invalid server response"};
    }
  }
}
