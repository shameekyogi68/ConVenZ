import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/blocking_service.dart';

class BlockingHelper {
  
  // ============================================
  // HANDLE API RESPONSE FOR BLOCKING
  // ============================================
  // Call this after every API request to check if user is blocked
  static void handleBlockingResponse(
    BuildContext context,
    Map<String, dynamic> response,
  ) {
    if (BlockingService.isUserBlocked(response)) {
      final blockReason = BlockingService.getBlockReason(response);
      
      // Navigate to blocked screen using GoRouter
      context.go('/blocked', extra: blockReason);
    }
  }

  // ============================================
  // CHECK USER STATUS ON APP LAUNCH
  // ============================================
  // Call this in main screen or splash screen
  static Future<bool> checkUserStatusOnLaunch(BuildContext context) async {
    try {
      final response = await BlockingService.checkUserStatus();
      
      if (response['success'] == true && response['data'] != null) {
        final isBlocked = response['data']['isBlocked'] ?? false;
        
        if (isBlocked) {
          final blockReason = response['data']['blockReason'] ?? 
                             'Your account has been blocked by admin.';
          
          if (context.mounted) {
            context.go('/blocked', extra: blockReason);
          }
          
          return true; // User is blocked
        }
      }
      
      return false; // User is not blocked
    } catch (e) {
      print("❌ Error checking user status: $e");
      return false;
    }
  }

  // ============================================
  // WRAPPER FOR API CALLS WITH BLOCKING CHECK
  // ============================================
  // Wraps any API call and automatically handles blocking
  static Future<Map<String, dynamic>> safeApiCall(
    BuildContext context,
    Future<Map<String, dynamic>> Function() apiCall,
  ) async {
    try {
      final response = await apiCall();
      
      // Check if user is blocked in response
      if (context.mounted) {
        handleBlockingResponse(context, response);
      }
      
      return response;
    } catch (e) {
      return {
        "success": false,
        "message": "API call failed: $e"
      };
    }
  }
}
