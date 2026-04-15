import '../config/app_constants.dart';
import '../models/subscription_plan.dart';
import '../utils/shared_prefs.dart';
import 'api_service.dart';

class SubscriptionService {
  static String get _base => AppConstants.subscriptionBaseUrl;

  // ─────────────────────────────────────────────
  /// Fetch all active customer subscription plans
  // ─────────────────────────────────────────────
  static Future<List<SubscriptionPlan>> getActivePlans() async {
    final Map<String, dynamic> res = await ApiService.getUrl('$_base/plans?planType=customer');
    if (res['success'] == true && res['data'] != null) {
      final plansData = res['data'] as List<dynamic>;
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
      return {'success': false, 'message': 'User not logged in'};
    }
    return ApiService.postUrl('$_base/purchase', {'planId': planId});
  }

  // ─────────────────────────────────────────────
  /// Get user's current active subscription
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getUserSubscription(String userId) async {
    // `userId` kept for API compatibility at call sites; backend resolves
    // identity from JWT and `/my` avoids param/token mismatch issues.
    return ApiService.getUrl('$_base/my');
  }
}
