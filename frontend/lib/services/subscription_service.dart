import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/subscription_plan.dart';
import '../utils/shared_prefs.dart';
import '../config/app_constants.dart';

class SubscriptionService {
  // Use centralized configuration
  static const baseUrl = AppConstants.subscriptionBaseUrl;

  /// Fetch all active plans from the backend
  static Future<List<SubscriptionPlan>> getActivePlans() async {
    try {
      // Call GET /api/user/plans/all?planType=customer from backend
      final String url = "${AppConstants.userBaseUrl}/plans/all?planType=customer";
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      print("📥 Plans Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> plansData = jsonData['data'] as List<dynamic>;
          return plansData
              .map((plan) => SubscriptionPlan.fromJson(plan as Map<String, dynamic>))
              .toList();
        } else {
          print("❌ API Error: ${jsonData['message']}");
          return [];
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Network error: $e");
      return [];
    }
  }

  /// Purchase a subscription plan
  static Future<Map<String, dynamic>> purchaseSubscription({
    required String planId,
  }) async {
    try {
      // Get current user ID from SharedPrefs
      String? userIdStr = SharedPrefs.getUserId();
      if (userIdStr == null || userIdStr.isEmpty) {
        return {"success": false, "message": "User not logged in"};
      }

      // Convert userId to number (backend expects numeric user_id)
      int? userId = int.tryParse(userIdStr);
      if (userId == null) {
        return {"success": false, "message": "Invalid user ID format"};
      }

      final String url = "$baseUrl/purchase";
      print("🔗 Purchase URL: $url");
      print("📤 Request Body: userId=$userId, planId=$planId");

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "planId": planId,
        }),
      );

      print("📥 Purchase Response Status: ${response.statusCode}");
      print("📥 Purchase Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else if (response.statusCode == 400) {
        // User already has active subscription
        final errorBody = jsonDecode(response.body);
        return errorBody;
      } else {
        final errorBody = jsonDecode(response.body);
        return errorBody;
      }
    } catch (e) {
      print("❌ Network error: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }

  /// Get user's current subscription
  static Future<Map<String, dynamic>> getUserSubscription(String userId) async {
    try {
      final String url = "$baseUrl/user/$userId";
      print("🔗 Fetching subscription from: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 10));

      print("📥 User Subscription Status: ${response.statusCode}");
      print("📥 User Subscription Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else if (response.statusCode == 404) {
        // No active subscription found
        print("⚠️ No active subscription (404)");
        return {"success": false, "message": "No active subscription"};
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        return {"success": false, "message": "Failed to fetch subscription"};
      }
    } on TimeoutException catch (e) {
      print("⏱️ Request timeout: $e");
      return {"success": false, "message": "Request timeout"};
    } catch (e) {
      print("❌ Network error: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }
}
