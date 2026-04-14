import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // 🌍 Production Ready API Configuration
  // Centralized URL, forcefully defaulting to the rendering backend for production build
  static String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: 'https://convenz-backend.onrender.com/api/v1');
  
  // 🏁 API Sub-Paths (Relative to apiBaseUrl)
  // Ensure paths match exactly with backend/server.js mount points
  static const String userApiPath = '/user';
  static const String bookingApiPath = '/booking';
  static const String subscriptionApiPath = '/subscription';
  
  // 🔗 Full Base URLs
  // Dynamically constructed for production stability
  static String get userBaseUrl => '$apiBaseUrl$userApiPath';
  static String get bookingBaseUrl => '$apiBaseUrl$bookingApiPath';
  static String get subscriptionBaseUrl => '$apiBaseUrl$subscriptionApiPath';
  
  // 🔐 Security: HMAC-SHA256 Signing Secret
  static String get apiSigningSecret => dotenv.get('API_SIGNING_SECRET', fallback: 'convenz_default_secret_key_2024_@!');
}
