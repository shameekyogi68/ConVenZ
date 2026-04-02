import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../../utils/shared_prefs.dart';
import '../router/app_router.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.get('API_BASE_URL', fallback: 'https://convenz-backend.onrender.com/api'),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static void initialize() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = SharedPrefs.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Centralized success handling/logging
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // Centralized error handling: If 401 (Token Expired), clear data and logout
          if (e.response?.statusCode == 401) {
            await SharedPrefs.clear();
            AppRouter.router.go('/welcomeCarousel');
            print('🚨 TOKEN_EXPIRED: User logged out automatically.');
          }
          return handler.next(e);
        },
      ),
    );
  }

  static Dio get instance => _dio;
}
