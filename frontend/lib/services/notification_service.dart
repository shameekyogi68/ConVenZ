
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../firebase_options.dart';
import '../core/router/app_router.dart';
import '../utils/app_logger.dart';
import '../utils/shared_prefs.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────
// Canonical notification type strings — single source of truth.
// All comparisons go through these constants.
// ─────────────────────────────────────────────────────────────
class _NotifType {
  static const otp = 'otp';
  static const bookingConfirm = 'BOOKING_CONFIRMATION';
  static const bookingStatus = 'BOOKING_STATUS_UPDATE';
  static const vendorAssigned = 'VENDOR_ASSIGNED';
  static const vendorUpdate = 'VENDOR_UPDATE';
  static const newBooking = 'NEW_BOOKING';
  static const marketing = 'MARKETING_NUDGE';

  /// Returns true for any type that should deep-link to the Bookings tab.
  static bool isBookingRelated(String? type) {
    if (type == null) {
      return false;
    }
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
  // Dummy references to satisfy reachability analysis for the background entry point.
  // This prevents 'unreachable member' warnings for members used elsewhere in the app.
  // ignore: unnecessary_statements
  NotificationService.initialize;
  // ignore: unnecessary_statements
  NotificationService.fcmToken;

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
  );

  static const _otpChannel = AndroidNotificationChannel(
    'otp_channel',
    'OTP Codes',
    description: 'One-time password verification codes.',
    importance: Importance.max,
  );

  static const _marketingChannel = AndroidNotificationChannel(
    'marketing_channel',
    'Offers & Reminders',
    description: 'Promotions, tips and service reminders.',
    playSound: false,
    enableVibration: false,
  );

  // ── Public API ────────────────────────────────────────────

  static Future<void> initialize() async {
    try {
      await Permission.notification.request();
      await _initLocalNotifications();
      await _createAndroidChannels();

      final NotificationSettings settings = await _fcm.requestPermission();

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        AppLogger.w('Notification permission denied');
        return;
      }

      await refreshAndSendToken();

      _fcm.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _saveTokenToBackend(token);
      });

      FirebaseMessaging.onMessage.listen(_dispatchLocalNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      final RemoteMessage? initial = await _fcm.getInitialMessage();
      if (initial != null) {
        _handleTap(initial);
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to initialize notification service', e, stackTrace);
    }
  }

  static String? get fcmToken => _fcmToken;

  /// Call after login/register to ensure the backend has the latest token.
  static Future<void> refreshAndSendToken() async {
    try {
      final String? token = await _fcm.getToken();
      if (token != null) {
        _fcmToken = token;
        await _saveTokenToBackend(token);
        AppLogger.d('FCM token refreshed and sent to backend');
      } else {
        AppLogger.w('Failed to get FCM token - token is null');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to refresh and send FCM token', e, stackTrace);
    }
  }

  // ── Internal dispatch (foreground + background) ───────────

  /// Single routing function used by both foreground listener and
  /// the top-level background handler — guarantees identical behaviour.
  static Future<void> _dispatchLocalNotification(RemoteMessage message) async {
    try {
      final type = message.data['type'] as String?;
      AppLogger.d('Dispatching notification of type: $type');

      if (type == _NotifType.otp) {
        await _showOtp(message);
      } else if (_NotifType.isBookingRelated(type)) {
        await _showBooking(message);
      } else if (type == _NotifType.marketing) {
        await _showMarketing(message);
      } else {
        await _showGeneric(message);
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to dispatch local notification', e, stackTrace);
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
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    // Payload format: "<type>:<bookingId>" or just "<type>"
    final List<String> parts = payload.split(':');
    final String type = parts[0];
    final String? bookingId = parts.length > 1 ? parts[1] : null;
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
    final String title = message.notification?.title ?? 'OTP Verification';
    final String body = message.notification?.body ?? 'Your verification code has arrived';

    await _local.show(
      id: 0, // Fixed ID — always replaces the previous OTP notification
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _otpChannel.id,
          _otpChannel.name,
          channelDescription: _otpChannel.description,
          importance: Importance.max,
          priority: Priority.max,
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
    final type = message.data['type'] as String?;
    final bookingId = message.data['bookingId'] as String?;
    final String title = message.notification?.title ?? 'Booking Update';
    final String body = message.notification?.body ?? 'Your booking has been updated.';

    await _local.show(
      id: _notifId(message, prefix: 'booking'),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _highChannel.id,
          _highChannel.name,
          channelDescription: _highChannel.description,
          importance: Importance.high,
          priority: Priority.high,
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
    final String? title = message.notification?.title;
    final String? body = message.notification?.body;
    if (title == null || title.isEmpty) {
      return;
    }

    await _local.show(
      id: _notifId(message, prefix: 'mkt'),
      title: title,
      body: body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _marketingChannel.id,
          _marketingChannel.name,
          channelDescription: _marketingChannel.description,
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
    final String? title = message.notification?.title;
    final String body = message.notification?.body ?? '';
    if (title == null || title.isEmpty) {
      return;
    }

    await _local.show(
      id: _notifId(message),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _highChannel.id,
          _highChannel.name,
          channelDescription: _highChannel.description,
          importance: Importance.high,
          priority: Priority.high,
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
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings: initSettings, onDidReceiveNotificationResponse: _onLocalTap);
  }

  static Future<void> _createAndroidChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_highChannel);
    await android?.createNotificationChannel(_otpChannel);
    await android?.createNotificationChannel(_marketingChannel);
  }

  // ── Token sync ────────────────────────────────────────────

  /// Saves the FCM token to the backend with up to 3 retries.
  /// userId is derived server-side from the JWT — not sent in body.
  static Future<void> _saveTokenToBackend(String token, {int attempt = 0}) async {
    try {
      final String? authToken = SharedPrefs.getToken();
      if (authToken == null || authToken.isEmpty) {
        // Not logged in yet - retry after a short delay (token refresh on login)
        if (attempt < 3) {
          AppLogger.d('Not logged in, retrying token save in ${attempt == 0 ? 2 : 5}s');
          await Future<void>.delayed(Duration(seconds: attempt == 0 ? 2 : 5));
          await _saveTokenToBackend(token, attempt: attempt + 1);
        } else {
          AppLogger.w('Max retries reached for token save - not logged in');
        }
        return;
      }

      final Map<String, dynamic> response = await ApiService.post('/fcm/update-token', {'fcmToken': token});
      if (response['success'] == true) {
        AppLogger.d('FCM token saved to backend successfully');
      } else {
        AppLogger.w('Failed to save FCM token: ${response['message']}');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error saving FCM token to backend (attempt $attempt)', e, stackTrace);
      if (attempt < 1) {
        AppLogger.d('Retrying token save in 3s');
        await Future<void>.delayed(const Duration(seconds: 3));
        await _saveTokenToBackend(token, attempt: attempt + 1);
      }
    }
  }
}
