import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/subscription_plan.dart';
import '../utils/shared_prefs.dart';
import '../config/app_constants.dart';

class SubscriptionService {
  static String get _baseUrl => AppConstants.subscriptionBaseUrl;

  // ─────────────────────────────────────────────
  /// Fetch all active customer subscription plans
  // ─────────────────────────────────────────────
  static Future<List<SubscriptionPlan>> getActivePlans() async {
    try {
      final url = "$_baseUrl/plans?planType=customer";
      final response = await http
          .get(Uri.parse(url), headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> plansData = jsonData['data'];
          return plansData
              .map((plan) =>
                  SubscriptionPlan.fromJson(plan as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on TimeoutException {
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  /// Purchase a subscription plan
  /// ✅ FIX: userId is NOT sent in body — backend reads it from JWT token
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> purchaseSubscription({
    required String planId,
  }) async {
    try {
      final String? token = SharedPrefs.getToken();
      if (token == null || token.isEmpty) {
        return {"success": false, "message": "User not logged in"};
      }

      final url = "$_baseUrl/purchase";
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            // ✅ Only send planId — userId is extracted from token on backend
            body: jsonEncode({"planId": planId}),
          )
          .timeout(const Duration(seconds: 30));

      final result = jsonDecode(response.body);
      return result;
    } on TimeoutException {
      return {"success": false, "message": "Request timed out. Please try again."};
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // ─────────────────────────────────────────────
  /// Get user's current active subscription
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getUserSubscription(
      String userId) async {
    try {
      final String? token = SharedPrefs.getToken();
      final url = "$_baseUrl/user/$userId";

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              if (token != null) "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return {"success": false, "message": "No active subscription"};
      } else {
        return {
          "success": false,
          "message": "Failed to fetch subscription (${response.statusCode})"
        };
      }
    } on TimeoutException {
      return {"success": false, "message": "Request timed out"};
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }
}
