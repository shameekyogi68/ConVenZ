import 'dart:async';
import 'dart:io';

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
    final Stopwatch stopwatch = Stopwatch()..start();

    onStatusUpdate?.call('Connecting to server...');
    AppLogger.i('🌐 Pinging server at $_healthUrl');

    while (stopwatch.elapsed < _coldStartTimeout) {
      try {
        final http.Response response = await http
            .get(Uri.parse(_healthUrl))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          _isServerAwake = true;
          stopwatch.stop();
          AppLogger.i('✅ Server is awake after ${stopwatch.elapsed.inSeconds}s');
          onStatusUpdate?.call('Connected!');
          _startKeepAliveTimer();
          return true;
        }
      } on SocketException {
        AppLogger.w('Server not reachable yet. Retrying...');
        onStatusUpdate?.call('Starting up server... (${stopwatch.elapsed.inSeconds}s)');
      } on TimeoutException {
        AppLogger.w('Server ping timed out. Retrying...');
        onStatusUpdate?.call('Server is warming up... (${stopwatch.elapsed.inSeconds}s)');
      } catch (e) {
        AppLogger.e('Unexpected ping error', e);
        onStatusUpdate?.call('Connecting...');
      }

      await Future<void>.delayed(_retryDelay);
    }

    // Timed out but allow app to continue (server might just be slow)
    _isServerAwake = false;
    AppLogger.w('⚠️ Server wake timeout after ${_coldStartTimeout.inSeconds}s. Proceeding anyway.');
    onStatusUpdate?.call('Taking longer than usual...');
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
