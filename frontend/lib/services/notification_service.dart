import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/shared_prefs.dart';
import 'api_service.dart';
import '../../firebase_options.dart';
import '../core/router/app_router.dart';

// ─────────────────────────────────────────────────────────────
// Canonical notification type strings — single source of truth.
// All comparisons go through these constants.
// ─────────────────────────────────────────────────────────────
class _NotifType {
  static const otp               = 'otp';
  static const bookingConfirm    = 'BOOKING_CONFIRMATION';
  static const bookingStatus     = 'BOOKING_STATUS_UPDATE';
  static const vendorAssigned    = 'VENDOR_ASSIGNED';
  static const vendorUpdate      = 'VENDOR_UPDATE';
  static const newBooking        = 'NEW_BOOKING';
  static const marketing         = 'MARKETING_NUDGE';

  /// Returns true for any type that should deep-link to the Bookings tab.
  static bool isBookingRelated(String? type) {
    if (type == null) return false;
    return const {
      bookingConfirm,
      bookingStatus,
      vendorAssigned,
      vendorUpdate,
      newBooking,
      // Legacy variants from older backend versions
      'STATUS_UPDATE',
      'booking_status_update',
      'vendor_assigned',
    }.contains(type);
  }
}

// ─────────────────────────────────────────────────────────────
// Background handler — must be a top-level function.
// Runs in a separate isolate; Firebase must be re-initialised.
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService._dispatchLocalNotification(message);
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static String? _fcmToken;

  // ── Android channels ──────────────────────────────────────
  static const _highChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Service Updates',
    description: 'Booking confirmations, vendor updates and status changes.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const _otpChannel = AndroidNotificationChannel(
    'otp_channel',
    'OTP Codes',
    description: 'One-time password verification codes.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const _marketingChannel = AndroidNotificationChannel(
    'marketing_channel',
    'Offers & Reminders',
    description: 'Promotions, tips and service reminders.',
    importance: Importance.defaultImportance,
    playSound: false,
    enableVibration: false,
  );

  // ── Public API ────────────────────────────────────────────

  static Future<void> initialize() async {
    try {
      await Permission.notification.request();
      await _initLocalNotifications();
      await _createAndroidChannels();

      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        await _saveTokenToBackend(_fcmToken!);
      }

      _fcm.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _saveTokenToBackend(token);
      });

      FirebaseMessaging.onMessage.listen(_dispatchLocalNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      final initial = await _fcm.getInitialMessage();
      if (initial != null) _handleTap(initial);
    } catch (_) {
      // Silent — notification failure must never crash the app
    }
  }

  static String? getFcmToken() => _fcmToken;

  /// Call after login/register to ensure the backend has the latest token.
  static Future<void> refreshAndSendToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        _fcmToken = token;
        await _saveTokenToBackend(token);
      }
    } catch (_) {}
  }

  static Future<void> subscribeToTopic(String topic) async {
    try { await _fcm.subscribeToTopic(topic); } catch (_) {}
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try { await _fcm.unsubscribeFromTopic(topic); } catch (_) {}
  }

  // ── Internal dispatch (foreground + background) ───────────

  /// Single routing function used by both foreground listener and
  /// the top-level background handler — guarantees identical behaviour.
  static Future<void> _dispatchLocalNotification(RemoteMessage message) async {
    final type = message.data['type'] as String?;

    if (type == _NotifType.otp) {
      await _showOtp(message);
    } else if (_NotifType.isBookingRelated(type)) {
      await _showBooking(message);
    } else if (type == _NotifType.marketing) {
      await _showMarketing(message);
    } else {
      await _showGeneric(message);
    }
  }

  // ── Tap / deep-link handler ────────────────────────────────

  /// Unified navigation handler for both FCM taps and local notification taps.
  static void _navigateForMessage(String? type, String? bookingId) {
    try {
      if (_NotifType.isBookingRelated(type)) {
        final extra = <String, dynamic>{'tab': 1};
        if (bookingId != null && bookingId.isNotEmpty) {
          extra['bookingId'] = bookingId;
        }
        AppRouter.router.go('/home', extra: extra);
      } else if (type == _NotifType.otp) {
        // User is already on the OTP screen — no navigation needed.
      } else {
        AppRouter.router.go('/home');
      }
    } catch (_) {}
  }

  /// Called when user taps a notification while app is background/terminated.
  static void _handleTap(RemoteMessage message) {
    _navigateForMessage(
      message.data['type'] as String?,
      message.data['bookingId'] as String?,
    );
  }

  /// Called when user taps a flutter_local_notifications notification.
  static void _onLocalTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    // Payload format: "<type>:<bookingId>" or just "<type>"
    final parts = payload.split(':');
    final type = parts[0];
    final bookingId = parts.length > 1 ? parts[1] : null;
    _navigateForMessage(type, bookingId);
  }

  // ── Notification display helpers ──────────────────────────

  /// Deterministic notification ID from bookingId, or fallback to message hash.
  static int _notifId(RemoteMessage message, {String prefix = ''}) {
    final bookingId = message.data['bookingId'] as String?;
    if (bookingId != null && bookingId.isNotEmpty) {
      return '$prefix$bookingId'.hashCode.abs();
    }
    return message.messageId?.hashCode.abs() ?? message.hashCode.abs();
  }

  static Future<void> _showOtp(RemoteMessage message) async {
    final title = message.notification?.title ?? 'OTP Verification';
    final body  = message.notification?.body  ?? 'Your verification code has arrived';

    await _local.show(
      0, // Fixed ID — always replaces the previous OTP notification
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _otpChannel.id,
          _otpChannel.name,
          channelDescription: _otpChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ticker: 'OTP Code Received',
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: _NotifType.otp,
    );
  }

  static Future<void> _showBooking(RemoteMessage message) async {
    final type      = message.data['type'] as String?;
    final bookingId = message.data['bookingId'] as String?;
    final title     = message.notification?.title ?? 'Booking Update';
    final body      = message.notification?.body  ?? 'Your booking has been updated.';

    await _local.show(
      _notifId(message, prefix: 'booking'),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _highChannel.id,
          _highChannel.name,
          channelDescription: _highChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: type == _NotifType.vendorAssigned,
          ticker: title,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: type == _NotifType.vendorAssigned
              ? InterruptionLevel.timeSensitive
              : InterruptionLevel.active,
        ),
      ),
      payload: '$type:${bookingId ?? ''}',
    );
  }

  static Future<void> _showMarketing(RemoteMessage message) async {
    final title = message.notification?.title;
    final body  = message.notification?.body;
    if (title == null || title.isEmpty) return;

    await _local.show(
      _notifId(message, prefix: 'mkt'),
      title,
      body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _marketingChannel.id,
          _marketingChannel.name,
          channelDescription: _marketingChannel.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: false,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: _NotifType.marketing,
    );
  }

  static Future<void> _showGeneric(RemoteMessage message) async {
    final title = message.notification?.title;
    final body  = message.notification?.body ?? '';
    if (title == null || title.isEmpty) return;

    await _local.show(
      _notifId(message),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _highChannel.id,
          _highChannel.name,
          channelDescription: _highChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'] as String? ?? '',
    );
  }

  // ── Init helpers ──────────────────────────────────────────

  static Future<void> _initLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _local.initialize(initSettings, onDidReceiveNotificationResponse: _onLocalTap);
  }

  static Future<void> _createAndroidChannels() async {
    final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_highChannel);
    await android?.createNotificationChannel(_otpChannel);
    await android?.createNotificationChannel(_marketingChannel);
  }

  // ── Token sync ────────────────────────────────────────────

  /// Saves the FCM token to the backend with up to 3 retries.
  /// userId is derived server-side from the JWT — not sent in body.
  static Future<void> _saveTokenToBackend(String token, {int attempt = 0}) async {
    try {
      final authToken = SharedPrefs.getToken();
      if (authToken == null || authToken.isEmpty) {
        // Not logged in yet — retry after a short delay (token refresh on login)
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt == 0 ? 2 : 5));
          await _saveTokenToBackend(token, attempt: attempt + 1);
        }
        return;
      }

      await ApiService.post('/fcm/update-token', {'fcmToken': token});
    } catch (_) {
      if (attempt < 1) {
        await Future.delayed(const Duration(seconds: 3));
        await _saveTokenToBackend(token, attempt: attempt + 1);
      }
    }
  }
}
