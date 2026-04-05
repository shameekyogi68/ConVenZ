import '../config/app_constants.dart';
import '../utils/shared_prefs.dart';
import 'api_service.dart';
import '../models/subscription_plan.dart';

class SubscriptionService {
  static String get _base => AppConstants.subscriptionBaseUrl;

  // ─────────────────────────────────────────────
  /// Fetch all active customer subscription plans
  // ─────────────────────────────────────────────
  static Future<List<SubscriptionPlan>> getActivePlans() async {
    final res = await ApiService.getUrl("$_base/plans?planType=customer");
    if (res['success'] == true && res['data'] != null) {
      final List<dynamic> plansData = res['data'];
      return plansData
          .map((plan) => SubscriptionPlan.fromJson(plan as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ─────────────────────────────────────────────
  /// Purchase a subscription plan
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> purchaseSubscription({
    required String planId,
  }) async {
    final String? token = SharedPrefs.getToken();
    if (token == null || token.isEmpty) {
      return {"success": false, "message": "User not logged in"};
    }
    return ApiService.postUrl("$_base/purchase", {"planId": planId});
  }

  // ─────────────────────────────────────────────
  /// Get user's current active subscription
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getUserSubscription(String userId) async {
    return ApiService.getUrl("$_base/user/$userId");
  }
}
