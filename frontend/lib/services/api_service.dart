import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../config/app_constants.dart';
import '../core/router/app_router.dart';
import '../utils/app_logger.dart';
import '../utils/shared_prefs.dart';

class ApiService {
  static late Dio _dio;
  static bool _isInitialized = false;

  // 🚀 In-Memory Cache to reduce server load
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 1);

  /// Initialize the API service with performance interceptors and security signing
  static void initialize() {
    if (_isInitialized) {
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // ── INTERCEPTORS (Signing, Auth, Logging, Session) ──
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 1. Auth Token
        final String? token = SharedPrefs.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // 2. 🔐 HMAC Request Signing
        try {
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final String secret = AppConstants.apiSigningSecret;
          
          // Use the fully resolved URI path (includes /api/v1 prefix) 
          // to match backend verification logic exactly.
          final String path = options.uri.path;
          
          String bodyString = '';
          if (options.data != null) {
            if (options.data is Map && (options.data as Map).isEmpty) {
              options.data = null;
            } else if (options.data is List && (options.data as List).isEmpty) {
              options.data = null;
            } else {
              bodyString = jsonEncode(options.data);
            }
          }
          
          final String dataToSign = '${options.method.toUpperCase()}|$path|$timestamp|$bodyString';
          final Hmac hmac = Hmac(sha256, utf8.encode(secret));
          final String signature = hmac.convert(utf8.encode(dataToSign)).toString();
          
          options.headers['X-Signature'] = signature;
          options.headers['X-Timestamp'] = timestamp;
        } catch (e) {
          AppLogger.e('Error signing request', e);
        }

        AppLogger.d('🚀 API REQUEST: [${options.method}] ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.d('✅ API RESPONSE: [${response.statusCode}] ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        AppLogger.e('❌ API ERROR: [${e.response?.statusCode}] ${e.requestOptions.path}', e);
        
        // Handle Session Expiry (401)
        if (e.response?.statusCode == 401) {
          SharedPrefs.clear().then((_) {
            AppRouter.router.go('/welcomeCarousel');
          });
        }
        
        return handler.next(e);
      },
    ));

    _isInitialized = true;
  }

  static Dio get _client {
    if (!_isInitialized) {
      initialize();
    }
    return _dio;
  }

  // ------------------------------------------------------------
  /// GET REQUEST with caching and auto-retry
  // ------------------------------------------------------------
  static Future<Map<String, dynamic>> get(String endpoint, {int retries = 3}) async {
    final fullUrl = endpoint.startsWith('http') ? endpoint : '${AppConstants.apiBaseUrl}$endpoint';
    
    // 1. Check Cache
    final _CacheEntry? cached = _cache[fullUrl];
    if (cached != null && DateTime.now().isBefore(cached.expiry)) {
      AppLogger.d('⚡ CACHE HIT: $fullUrl');
      return cached.data;
    }

    // 2. Network Request with Retries
    for (var attempt = 1; attempt <= retries; attempt++) {
      try {
        final Response<dynamic> response = await _client.get(endpoint);
        final Map<String, dynamic> result = _handleResponse(response);
        
        if (result['success'] == true) {
          _cache[fullUrl] = _CacheEntry(
            data: result,
            expiry: DateTime.now().add(_cacheDuration),
          );
        }
        return result;
      } on DioException catch (e) {
        if (attempt < retries && _shouldRetry(e)) {
          AppLogger.w('⚠️ GET failed (attempt $attempt/$retries). Retrying in 6s...');
          await Future<void>.delayed(const Duration(seconds: 6));
          continue;
        }
        return _handleError(e);
      } catch (e) {
        return _handleGeneralError(e);
      }
    }
    return {'success': false, 'message': 'Network timeout. Please try again.'};
  }

  // ------------------------------------------------------------
  /// POST REQUEST with auto-retry
  // ------------------------------------------------------------
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {int retries = 3}) async {
    for (var attempt = 1; attempt <= retries; attempt++) {
      try {
        final Response<dynamic> response = await _client.post(endpoint, data: data);
        final Map<String, dynamic> result = _handleResponse(response);
        return result;
      } on DioException catch (e) {
        if (attempt < retries && _shouldRetry(e)) {
          AppLogger.w('⚠️ POST failed (attempt $attempt/$retries). Retrying in 6s...');
          await Future<void>.delayed(const Duration(seconds: 6));
          continue;
        }
        return _handleError(e);
      } catch (e) {
        return _handleGeneralError(e);
      }
    }
    return {'success': false, 'message': 'Network timeout. Please try again.'};
  }

  // ------------------------------------------------------------
  /// PUT REQUEST
  // ------------------------------------------------------------
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final Response<dynamic> response = await _client.put(endpoint, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return _handleGeneralError(e);
    }
  }

  // ------------------------------------------------------------
  /// DELETE REQUEST
  // ------------------------------------------------------------
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final Response<dynamic> response = await _client.delete(endpoint);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return _handleGeneralError(e);
    }
  }

  // ------------------------------------------------------------
  /// Backward compatibility aliases
  // ------------------------------------------------------------
  static Future<Map<String, dynamic>> getUrl(String url) => get(url);
  static Future<Map<String, dynamic>> postUrl(String url, Map<String, dynamic> data) => post(url, data);

  // ------------------------------------------------------------
  // PRIVATE HANDLERS
  // ------------------------------------------------------------

  static bool _shouldRetry(DioException e) {
    return e.type == DioExceptionType.connectionError ||
           e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.receiveTimeout;
  }

  static Map<String, dynamic> _handleResponse(Response<dynamic> response) {
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      // If backend didn't wrap in 'success', we assume success if statusCode is 2xx
      if (!data.containsKey('success')) {
        return {'success': true, 'data': data};
      }
      return data;
    }
    return {'success': true, 'data': data};
  }

  static Map<String, dynamic> _handleError(DioException e) {
    final Response<dynamic>? response = e.response;
    final int? statusCode = response?.statusCode;
    
    // 1. Extract backend message
    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      if (data.containsKey('message')) {
        return {
          'success': false,
          'message': data['message'].toString(),
          'statusCode': statusCode,
        };
      }
    }

    // 2. Handle specific network errors
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return {'success': false, 'message': 'Connection timed out. Please try again.', 'statusCode': statusCode};
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return {'success': false, 'message': 'Network unavailable. Please check your connection.', 'statusCode': statusCode};
    }

    // 3. Fallback
    return {
      'success': false, 
      'message': e.message ?? 'An unexpected error occurred.',
      'statusCode': statusCode,
    };
  }

  static Map<String, dynamic> _handleGeneralError(dynamic e) {
    AppLogger.e('Unhandled ApiService Exception', e);
    return {'success': false, 'message': 'Internal system error. Please restart the app.'};
  }
}

class _CacheEntry {
  _CacheEntry({required this.data, required this.expiry});
  final Map<String, dynamic> data;
  final DateTime expiry;
}
