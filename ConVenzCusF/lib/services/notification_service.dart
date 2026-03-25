import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/shared_prefs.dart';
import 'api_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  // Check notification type
  String? type = message.data['type'];
  
  if (type == 'otp') {
    String? otp = message.data['otp'] ?? message.notification?.body;
    print('🔐 OTP Received: $otp');
    await NotificationService.showOtpNotification(message);
  } else if (type == 'BOOKING_STATUS_UPDATE' || type == 'booking_status_update') {
    print('📋 Background: Booking Status Update');
    await NotificationService.showBookingNotification(message);
  } else if (type == 'VENDOR_ASSIGNED' || type == 'vendor_assigned') {
    print('👤 Background: Vendor Assigned');
    await NotificationService.showVendorAssignedNotification(message);
  } else {
    await NotificationService.showNotification(message);
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _fcmToken;
  
  // Android notification channels
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );
  
  static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
    'default',
    'Default Notifications',
    description: 'Default notification channel for general messages.',
    importance: Importance.defaultImportance,
    playSound: true,
  );
  
  static const AndroidNotificationChannel otpChannel = AndroidNotificationChannel(
    'otp_channel',
    'OTP Notifications',
    description: 'Channel for OTP verification codes.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Initialize Firebase Messaging and Local Notifications
  static Future<void> initialize() async {
    try {
      // Request Android 13+ notification permission
      await Permission.notification.request();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Create Android notification channels
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.createNotificationChannel(_channel);
      await androidImplementation?.createNotificationChannel(_defaultChannel);
      await androidImplementation?.createNotificationChannel(otpChannel);

      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Delete old token and get a fresh one
        try {
          await _firebaseMessaging.deleteToken();
        } catch (e) {
          // Ignore delete errors
        }
        
        // Get fresh FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null) {
          print('FCM Token: $_fcmToken');
          await _saveFcmTokenToBackend(_fcmToken!);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          print('FCM Token Refreshed: $newToken');
          _fcmToken = newToken;
          _saveFcmTokenToBackend(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background message clicks (onMessageOpenedApp)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);

        // Check if app was opened from a terminated state
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageClick(initialMessage);
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on payload
    if (response.payload != null) {
      // Add navigation logic here if needed
    }
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Check notification type
    String? type = message.data['type'];
    
    if (type == 'otp') {
      String? otp = message.data['otp'] ?? message.notification?.body;
      print('🔐 OTP Received: $otp');
      await showOtpNotification(message);
    } else if (type == 'BOOKING_STATUS_UPDATE' || type == 'booking_status_update') {
      print('📋 Booking Status Update: ${message.data}');
      await showBookingNotification(message);
    } else if (type == 'VENDOR_ASSIGNED' || type == 'vendor_assigned') {
      print('👤 Vendor Assigned: ${message.data}');
      await showVendorAssignedNotification(message);
    } else {
      await showNotification(message);
    }
  }

  /// Show local notification
  static Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    String? type = message.data['type'];
    
    // Default values
    String title = notification?.title ?? 'New Message';
    String body = notification?.body ?? '';

    // Customize based on type
    if (type == 'otp') {
      title = notification?.title ?? 'OTP Verification';
      body = notification?.body ?? 'Your verification code has arrived';
    } else if (type == 'welcome') {
      title = notification?.title ?? 'Welcome!';
      body = notification?.body ?? 'Welcome to Convenz!';
    } else if (type == 'profile_update') {
      title = notification?.title ?? 'Profile Updated';
      body = notification?.body ?? 'Your profile has been updated successfully';
    } else if (type == 'location_update') {
      title = notification?.title ?? 'Location Update';
      body = notification?.body ?? 'Location information updated';
    }

    // Show notification if we have title or body
    if (title.isNotEmpty || body.isNotEmpty) {
      await _localNotifications.show(
        notification.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: type ?? '',
      );
    }
  }

  /// Show booking status update notification
  static Future<void> showBookingNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    String? bookingId = message.data['bookingId'];
    String? status = message.data['status'] ?? message.data['bookingStatus'];
    
    String title = notification?.title ?? 'Booking Update';
    String body = notification?.body ?? 'Your booking status has been updated to: $status';
    
    await _localNotifications.show(
      bookingId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'booking_update:$bookingId',
    );
  }

  /// Show vendor assigned notification
  static Future<void> showVendorAssignedNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    String? vendorName = message.data['vendorName'];
    String? bookingId = message.data['bookingId'];
    
    String title = notification?.title ?? '👤 Vendor Assigned!';
    String body = notification?.body ?? 
        (vendorName != null 
            ? '$vendorName has accepted your booking!' 
            : 'A vendor has accepted your booking!');
    
    await _localNotifications.show(
      bookingId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ticker: 'Vendor Accepted Booking',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'vendor_assigned:$bookingId',
    );
  }

  /// Show OTP local notification with max priority
  static Future<void> showOtpNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    
    String title = notification?.title ?? 'OTP Verification';
    String body = notification?.body ?? message.data['otp'] ?? 'Your verification code has arrived';
    
    // Show notification with max importance for OTP
    await _localNotifications.show(
      0, // Use ID 0 for OTP notifications
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'otp_channel',
          'OTP Notifications',
          channelDescription: 'Channel for OTP verification codes',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ticker: 'OTP Code Received',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'otp',
    );
  }

  /// Handle notification clicks
  static void _handleMessageClick(RemoteMessage message) {
    String? type = message.data['type'];
    
    // Navigate based on type
    switch (type) {
      case 'otp':
        // Navigation to OTP screen if needed
        break;
      case 'welcome':
        // Navigation to home or welcome screen
        break;
      case 'profile_update':
        // Navigation to profile screen
        break;
      case 'location_update':
        // Navigation to location screen
        break;
      default:
        // Default navigation
        break;
    }
  }

  /// Save FCM token to backend with retry logic
  static Future<void> _saveFcmTokenToBackend(String token, {int retryCount = 0}) async {
    try {
      String? userId = SharedPrefs.getUserId();
      if (userId == null || userId.isEmpty) {
        // Retry after 2 seconds if no userId (user might be logging in)
        if (retryCount < 3) {
          await Future.delayed(Duration(seconds: 2));
          await _saveFcmTokenToBackend(token, retryCount: retryCount + 1);
        }
        return;
      }

      final response = await ApiService.post('/user/update-fcm-token', {
        'userId': int.parse(userId),
        'fcmToken': token,
      });
      
      if (response['success'] == true) {
        print('✅ FCM Token saved successfully');
      } else {
        print('❌ FCM Token save failed: ${response['message']}');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
      // Retry once on error
      if (retryCount < 1) {
        await Future.delayed(Duration(seconds: 1));
        await _saveFcmTokenToBackend(token, retryCount: retryCount + 1);
      }
    }
  }

  /// Get current FCM token
  static String? getFcmToken() {
    return _fcmToken;
  }
  
  /// Refresh and send FCM token to backend (call after user login/register)
  static Future<void> refreshAndSendToken() async {
    try {
      // Get current or new token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _fcmToken = token;
        print('Refreshing FCM Token: $token');
        await _saveFcmTokenToBackend(token);
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      // Silent fail
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      // Silent fail
    }
  }
}
