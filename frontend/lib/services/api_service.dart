import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:dio/dio.dart';

import '../config/app_constants.dart';
import '../core/router/app_router.dart';
import '../utils/app_logger.dart';
import '../utils/shared_prefs.dart';

class ApiService {
  static String get baseUrl => AppConstants.userBaseUrl;



  static Dio? _dio;

  // 🚀 In-Memory Cache to drastically reduce server load (10/10 optimization)
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 1);

  static Dio get _client {
    if (_dio != null) {
      return _dio!;
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // ── INTERCEPTORS ──
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final String? token = SharedPrefs.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // 🔐 REQUEST SIGNING (HMAC-SHA256)
        // This ensures the request hasn't been tampered with and comes from the official app.
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final String secret = AppConstants.apiSigningSecret;
          
          // Data to sign: METHOD|PATH|TIMESTAMP|BODY
          var bodyString = '';
          if (options.data != null) {
            if (options.data is Map || options.data is List) {
              bodyString = jsonEncode(options.data);
            } else {
              bodyString = options.data.toString();
            }
          }
          
          final dataToSign = '${options.method.toUpperCase()}|${options.path}|$timestamp|$bodyString';
          final hmac = Hmac(sha256, utf8.encode(secret));
          final signature = hmac.convert(utf8.encode(dataToSign)).toString();
          
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

    return _dio!;
  }

  // -----------------------
  // POST REQUEST (absolute URL)
  // -----------------------
  static Future<Map<String, dynamic>> postUrl(
      String absoluteUrl, Map<String, dynamic> data, {int retries = 3}) async {
    for (var attempt = 1; attempt <= retries; attempt++) {
      try {
        final Response<Map<String, dynamic>> response =
            await _client.post<Map<String, dynamic>>(
          absoluteUrl,
          data: data,
        );
        return _handleDioResponse(response);
      } on DioException catch (e) {
        // Retry on connection errors (server might be waking up)
        if (attempt < retries &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout)) {
          AppLogger.w('⚠️ Request failed (attempt $attempt/$retries). Retrying in 6s...');
          await Future<void>.delayed(const Duration(seconds: 6));
          continue;
        }
        return _handleDioException(e);
      } catch (e) {
        return _handleException(e);
      }
    }
    return {'success': false, 'message': 'Server is unavailable. Please try again later.'};
  }

  // -----------------------
  // GET REQUEST (absolute URL)
  // -----------------------
  static Future<Map<String, dynamic>> getUrl(String absoluteUrl,
      {int retries = 3}) async {
        
    // 1️⃣ Check Cache
    final _CacheEntry? cached = _cache[absoluteUrl];
    if (cached != null && DateTime.now().isBefore(cached.expiry)) {
      AppLogger.d('⚡ CACHE HIT: $absoluteUrl');
      return cached.data;
    }

    // 2️⃣ Network Request
    for (var attempt = 1; attempt <= retries; attempt++) {
      try {
        final Response<Map<String, dynamic>> response =
            await _client.get<Map<String, dynamic>>(absoluteUrl);
            
        final Map<String, dynamic> responseData = _handleDioResponse(response);
        
        // Save to Cache if successful
        if (responseData['success'] == true) {
           _cache[absoluteUrl] = _CacheEntry(
             data: responseData,
             expiry: DateTime.now().add(_cacheDuration),
           );
        }
        
        return responseData;
      } on DioException catch (e) {
        // Retry on connection errors (server might be waking up)
        if (attempt < retries &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout)) {
          AppLogger.w('⚠️ GET failed (attempt $attempt/$retries). Retrying in 6s...');
          await Future<void>.delayed(const Duration(seconds: 6));
          continue;
        }
        return _handleDioException(e);
      } catch (e) {
        return _handleException(e);
      }
    }
    return {'success': false, 'message': 'Server is unavailable. Please try again later.'};
  }

  // -----------------------
  // CONVENIENCE METHODS
  // -----------------------
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    return postUrl(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint', data);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    return getUrl(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
  }

  // -----------------------
  // HANDLERS
  // -----------------------

  static Map<String, dynamic> _handleDioResponse(Response<Map<String, dynamic>> response) {
    return response.data ?? {'success': true};
  }

  static Map<String, dynamic> _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout || 
        e.type == DioExceptionType.sendTimeout) {
      return {'success': false, 'message': 'The server took too long to respond. Please check your internet speed and try again.'};
    }
    
    if (e.type == DioExceptionType.connectionError) {
      if (e.message?.contains('CERTIFICATE_VERIFY_FAILED') ?? false) {
        return {'success': false, 'message': 'Secure connection failed. Please ensure your device date and time are accurate.'};
      }
      return {'success': false, 'message': 'No internet connection detected. Please check your Wi-Fi or mobile data.'};
    }

    // Capture standard backend JSON errors
    final Response<dynamic>? response = e.response;
    if (response != null) {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        // Bubble up clean backend validation errors
        if (data.containsKey('message')) return data;
      }
      
      // Fallback for 500s or HTML dumps from Render when server crashes
      if (response.statusCode != null && response.statusCode! >= 500) {
        return {'success': false, 'message': 'Our servers are currently overloaded. Please try again in a few moments.'};
      }
    }

    return {'success': false, 'message': 'We encountered a minor communication hiccup. Please try again.'};
  }

  static Map<String, dynamic> _handleException(Object e) {
    // We log the real error for developers, but show a polished message to the standard user
    AppLogger.e('Unhandled Internal Exception', e);
    return {'success': false, 'message': 'Oops! Something went wrong on our end. Please restart the app if this persists.'};
  }
}

class _CacheEntry {
  _CacheEntry({required this.data, required this.expiry});

  final Map<String, dynamic> data;
  final DateTime expiry;
}
