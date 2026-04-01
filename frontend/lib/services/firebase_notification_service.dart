import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/shared_prefs.dart';
import 'api_service.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    try {
      print('🔔 === FIREBASE MESSAGING INITIALIZATION ===');

      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        print('🔑 FCM Token: $_fcmToken');

        if (_fcmToken != null) {
          // Save token to backend
          await _saveFcmTokenToBackend(_fcmToken!);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          print('🔄 FCM Token refreshed: $newToken');
          _fcmToken = newToken;
          _saveFcmTokenToBackend(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background message clicks
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);

        // Check if app was opened from a terminated state
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          print('📩 App opened from terminated state via notification');
          _handleMessageClick(initialMessage);
        }

        print('✅ Firebase Messaging initialized successfully');
      } else {
        print('❌ User denied notification permission');
      }

      print('=' * 50);
    } catch (e) {
      print('❌ Firebase Messaging initialization error: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  static void _handleForegroundMessage(RemoteMessage message) {
    print('\\n🔔 === FOREGROUND NOTIFICATION RECEIVED ===');
    print('📨 Title: ${message.notification?.title}');
    print('📝 Body: ${message.notification?.body}');
    print('📦 Data: ${message.data}');
    print('=' * 50);

    // You can show a local notification or in-app alert here
    // For now, just logging
  }

  /// Handle notification clicks (background/terminated)
  static void _handleMessageClick(RemoteMessage message) {
    print('\\n👆 === NOTIFICATION CLICKED ===');
    print('📨 Title: ${message.notification?.title}');
    print('📝 Body: ${message.notification?.body}');
    print('📦 Data: ${message.data}');
    print('=' * 50);

    // Navigate to specific screen based on notification data
    // You can use Navigator or routing logic here
  }

  /// Save FCM token to backend
  static Future<void> _saveFcmTokenToBackend(String token) async {
    try {
      String? userId = SharedPrefs.getUserId();
      if (userId == null || userId.isEmpty) {
        print('⚠️ No user ID found, skipping token save');
        return;
      }

      print('📤 Saving FCM token to backend for user: $userId');

      final response = await ApiService.post('/user/update-fcm-token', {
        'userId': int.parse(userId),
        'fcmToken': token,
      });

      if (response['success'] == true) {
        print('✅ FCM token saved to backend successfully');
      } else {
        print('⚠️ Failed to save FCM token: ${response['message']}');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Get current FCM token
  static String? getFcmToken() {
    return _fcmToken;
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('\\n🔔 === BACKGROUND NOTIFICATION RECEIVED ===');
  print('📨 Title: ${message.notification?.title}');
  print('📝 Body: ${message.notification?.body}');
  print('📦 Data: ${message.data}');
  print('=' * 50);
}
