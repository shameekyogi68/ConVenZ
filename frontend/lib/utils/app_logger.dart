import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of method calls to be displayed
    ),
  );

  /// Log a verbose message
  static void v(String message) => _logger.v(message);

  /// Log a debug message
  static void d(String message) => _logger.d(message);

  /// Log an info message
  static void i(String message) => _logger.i(message);

  /// Log a warning message
  static void w(String message) => _logger.w(message);

  /// Log an error message
  static void e(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// Log a fatal error message
  static void f(String message) => _logger.f(message);
}
