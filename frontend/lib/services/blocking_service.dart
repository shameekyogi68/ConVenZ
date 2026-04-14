import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/shared_prefs.dart';

class BlockingService {
  
  // ============================================
  // CHECK USER BLOCK STATUS
  // ============================================
  // Endpoint: GET /api/user/admin/check-status/:userId
  static Future<Map<String, dynamic>> checkUserStatus() async {
    try {
      final String? userId = SharedPrefs.getUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not logged in'
        };
      }

      final Map<String, dynamic> response = await ApiService.get('/user/admin/check-status/$userId');
      
      // Response structure:
      // {
      //   "success": true,
      //   "data": {
      //     "userId": "15",
      //     "isBlocked": true,
      //     "blockReason": "Violation of terms",
      //     "blockedAt": "2025-12-04T10:25:30.000Z"
      //   }
      // }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error checking block status: $e');
      return {
        'success': false,
        'message': 'Failed to check status: $e'
      };
    }
  }

  // ============================================
  // CHECK IF RESPONSE INDICATES BLOCKED USER
  // ============================================
  static bool isUserBlocked(Map<String, dynamic> response) {
    final dynamic data = response['data'];
    return response['blocked'] == true || 
           response['statusCode'] == 403 ||
           (data is Map<String, dynamic> && data['isBlocked'] == true);
  }

  // ============================================
  // GET BLOCK REASON FROM RESPONSE
  // ============================================
  static String getBlockReason(Map<String, dynamic> response) {
    // Check direct blockReason field
    final dynamic blockReason = response['blockReason'];
    if (blockReason != null && blockReason.toString().isNotEmpty) {
      return blockReason.toString();
    }
    
    // Check data.blockReason field
    final dynamic data = response['data'];
    if (data is Map<String, dynamic>) {
      final dynamic reason = data['blockReason'];
      if (reason != null && reason.toString().isNotEmpty) {
        return reason.toString();
      }
    }
    
    // Default message
    return 'Your account has been blocked by admin. Please contact support.';
  }

  // ============================================
  // ADMIN: BLOCK USER
  // ============================================
  // Endpoint: POST /api/user/admin/block-user
  static Future<Map<String, dynamic>> blockUser(String userId, String reason) async {
    try {
      final Map<String, dynamic> response = await ApiService.post('/user/admin/block-user', {
        'userId': userId,
        'blockReason': reason,
      });
      
      return response;
    } catch (e) {
      debugPrint('❌ Error blocking user: $e');
      return {
        'success': false,
        'message': 'Failed to block user: $e'
      };
    }
  }

  // ============================================
  // ADMIN: UNBLOCK USER
  // ============================================
  // Endpoint: POST /api/user/admin/unblock-user
  static Future<Map<String, dynamic>> unblockUser(String userId) async {
    try {
      final Map<String, dynamic> response = await ApiService.post('/user/admin/unblock-user', {
        'userId': userId,
      });
      
      return response;
    } catch (e) {
      debugPrint('❌ Error unblocking user: $e');
      return {
        'success': false,
        'message': 'Failed to unblock user: $e'
      };
    }
  }
}
