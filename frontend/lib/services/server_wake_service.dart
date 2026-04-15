import 'dart:async';


import 'package:http/http.dart' as http;

import '../config/app_constants.dart';
import '../utils/app_logger.dart';

/// Manages the Render free-tier server lifecycle.
///
/// Strategy:
/// 1. On app start, ping /health and wait until the server responds (cold start).
/// 2. After the server is up, ping every 14 minutes to prevent it from sleeping.
class ServerWakeService {
  static const Duration _pingInterval = Duration(minutes: 14);
  static const Duration _coldStartTimeout = Duration(seconds: 75);
  static const Duration _retryDelay = Duration(seconds: 5);

  static Timer? _keepAliveTimer;
  static bool _isServerAwake = false;

  /// Returns the current wake status
  static bool get isServerAwake => _isServerAwake;

  /// Returns the health endpoint URL (no auth needed)
  static String get _healthUrl {
    // e.g. https://convenz.onrender.com/health
    final String base = AppConstants.apiBaseUrl.replaceAll('/api/v1', '');
    return '$base/health';
  }

  /// Called on app start. Returns true when the server is ready.
  /// Shows a cold-start wait of up to 75 seconds.
  static Future<bool> wakeUp({void Function(String status)? onStatusUpdate}) async {
    final stopwatch = Stopwatch()..start();

    onStatusUpdate?.call('Connecting to server...');
    AppLogger.i('🌐 Pinging server at $_healthUrl');

    var attempts = 0;
    while (stopwatch.elapsed < _coldStartTimeout) {
      attempts++;
      try {
        // Fast timeout for the first few pings to detect an already-awake server
        final http.Response response = await http
            .get(Uri.parse(_healthUrl))
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          _isServerAwake = true;
          stopwatch.stop();
          AppLogger.i('✅ Server is awake after ${stopwatch.elapsed.inSeconds}s ($attempts attempts)');
          onStatusUpdate?.call('Connected!');
          _startKeepAliveTimer();
          return true;
        }
      } catch (e) {
        // Log failures but keep going fast for the first 5 attempts
        if (attempts > 5) {
          AppLogger.w('Server not responsive yet: $e');
        }
      }

      // UX: Faster retries (1s) for the first 5 seconds, then move to 3s
      final Duration delay = attempts < 5 ? const Duration(seconds: 1) : _retryDelay;
      
      if (attempts > 1) {
        onStatusUpdate?.call('Starting up server... (${stopwatch.elapsed.inSeconds}s)');
      }
      
      await Future<void>.delayed(delay as Duration);
    }

    _isServerAwake = false;
    stopwatch.stop();
    return false;
  }

  /// Starts a periodic timer that pings /health every 14 minutes.
  static void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(_pingInterval, (_) async {
      try {
        final http.Response response = await http
            .get(Uri.parse(_healthUrl))
            .timeout(const Duration(seconds: 10));
        AppLogger.d('🏓 Keep-alive ping: ${response.statusCode}');
      } catch (e) {
        AppLogger.w('Keep-alive ping failed: $e');
        _isServerAwake = false;
      }
    });
    AppLogger.i('🏓 Keep-alive timer started (every 14 min)');
  }

  /// Call when app is disposed / backgrounded for a long time.
  static void dispose() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _isServerAwake = false;
    AppLogger.i('🛑 Keep-alive timer stopped');
  }
}
