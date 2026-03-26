class AppConstants {
  // API Configuration
  // Change this to your backend server IP address or domain
  // For local development: Use your machine's local IP address
  // For production: Use your server's domain or public IP
  // For Android emulator: use 10.0.2.2 instead of localhost
  static const String apiBaseUrl = "https://convenzcusb-backend.onrender.com";
  
  // API Endpoints
  static const String userApiPath = "/api/user";
  static const String bookingApiPath = "/api/booking";
  static const String subscriptionApiPath = "/api/subscription";
  
  // Full URLs
  static const String userBaseUrl = "$apiBaseUrl$userApiPath";
  static const String bookingBaseUrl = "$apiBaseUrl$bookingApiPath";
  static const String subscriptionBaseUrl = "$apiBaseUrl$subscriptionApiPath";
}
