import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/app_constants.dart';
import '../core/router/app_router.dart';
import '../utils/app_logger.dart';
import '../utils/shared_prefs.dart';

class ApiService {
  static String get baseUrl => AppConstants.userBaseUrl;

  // 🔐 Certificate Fingerprints for onrender.com
  // These are the SHA-256 fingerprints of the leaf certificates.
  // Note: These should be updated if the server certificates are rotated.
  static const List<String> _pinnedFingerprints = [
    '4E:60:2F:FB:2A:B3:D6:8F:7E:16:D7:C6:BB:62:3D:62:0C:9E:14:38:B7:13:A6:A9:5B:4B:04:D3:A8:70:4A:29', // PRIMARY (EC)
    '68:A9:E4:83:29:4D:DE:C2:84:4A:3A:CC:30:25:09:DF:E2:EC:CB:9E:B0:E2:9E:60:B6:8B:DC:6E:4E:52:A0:D2', // SECONDARY (RSA)
  ];

  static Dio? _dio;

  static Dio get _client {
    if (_dio != null) {
      return _dio!;
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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

    // ── CERTIFICATE PINNING ──
    _dio!.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient(context: SecurityContext(withTrustedRoots: true));
        client.badCertificateCallback = (cert, host, port) => false;
        return client;
      },
      validateCertificate: (certificate, host, port) {
        if (certificate == null) {
          return false;
        }

        // Hash the certificate bytes (DER)
        final Digest hash = sha256.convert(certificate.der);
        final String fingerprint = _formatFingerprint(hash.bytes);
        
        AppLogger.d('🛡️ Verifying Certificate Pin: $fingerprint');

        if (_pinnedFingerprints.contains(fingerprint)) {
          AppLogger.i('🔒 Certificate pinning successful for $host');
          return true;
        }

        AppLogger.f('🚨 CERTIFICATE PINNING FAILED for $host! Expected one of $_pinnedFingerprints but got $fingerprint');
        return false;
      },
    );

    return _dio!;
  }

  static String _formatFingerprint(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  // -----------------------
  // POST REQUEST (absolute URL)
  // -----------------------
  static Future<Map<String, dynamic>> postUrl(
      String absoluteUrl, Map<String, dynamic> data) async {
    try {
      final Response<Map<String, dynamic>> response = await _client.post<Map<String, dynamic>>(
        absoluteUrl,
        data: data,
      );
      return _handleDioResponse(response);
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      return _handleException(e);
    }
  }

  // -----------------------
  // GET REQUEST (absolute URL)
  // -----------------------
  static Future<Map<String, dynamic>> getUrl(String absoluteUrl) async {
    try {
      final Response<Map<String, dynamic>> response = await _client.get<Map<String, dynamic>>(absoluteUrl);
      return _handleDioResponse(response);
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      return _handleException(e);
    }
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
        e.type == DioExceptionType.receiveTimeout) {
      return {'success': false, 'message': 'Connection timed out. Please try again.'};
    }
    
    if (e.type == DioExceptionType.connectionError) {
      if (e.message?.contains('CERTIFICATE_VERIFY_FAILED') ?? false) {
        return {'success': false, 'message': 'Secure connection failed. Possible security risk detected.'};
      }
      return {'success': false, 'message': 'Network error. Please check your connection.'};
    }

    final Response<dynamic>? response = e.response;
    if (response != null && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    return {'success': false, 'message': 'An error occurred during communication.'};
  }

  static Map<String, dynamic> _handleException(Object e) {
    return {'success': false, 'message': 'Unexpected error: $e'};
  }
}
