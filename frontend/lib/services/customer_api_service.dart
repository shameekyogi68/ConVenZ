// ============================================
// 📱 CUSTOMER FRONTEND - API SERVICE
// ============================================
// Base URL: https://convenzcusb-backend.onrender.com
// All endpoints use /api prefix automatically via ApiService
// JWT Authentication: Handled automatically by ApiService using SharedPrefs token

import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/app_logger.dart';
import '../utils/shared_prefs.dart';

class CustomerAPIService {
  
  // ============================================
  // 1️⃣ USER REGISTRATION
  // ============================================
  // Endpoint: POST /api/user/register
  // Description: Register new user with phone number
  static Future<Map<String, dynamic>> registerUser(String phone) async {
    try {
      final String? fcmToken = NotificationService.fcmToken;
      
      final Map<String, dynamic> response = await ApiService.post('/user/register', {
        'phone': phone,
        'fcmToken': fcmToken,
      });
      
      // Response structure:
      // {
      //   "success": true,
      //   "message": "User registered successfully",
      //   "userId": "673a1b2c3d4e5f6g7h8i9j0k",
      //   "isNewUser": true
      // }
      
      if (response['success'] == true) {
        await SharedPrefs.savePhone(phone);
        if (response['userId'] != null) {
          await SharedPrefs.saveUserId(response['userId'].toString());
        }
        await SharedPrefs.saveIsNewUser((response['isNewUser'] as bool?) ?? true);
      }
      
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: $e'
      };
    }
  }

  // ============================================
  // 2️⃣ OTP VERIFICATION
  // ============================================
  // Endpoint: POST /api/user/verify-otp
  // Description: Verify OTP sent to user's phone
  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final Map<String, dynamic> response = await ApiService.post('/user/verify-otp', {
        'phone': phone,
        'otp': otp
      });
      
      // Response structure:
      // {
      //   "success": true,
      //   "message": "OTP verified successfully",
      //   "userId": "673a1b2c3d4e5f6g7h8i9j0k",
      //   "isNewUser": false
      // }
      
      if (response['success'] == true) {
        if (response['token'] != null) {
          await SharedPrefs.saveToken(response['token'] as String);
        }
        
        if (response['userId'] != null) {
          await SharedPrefs.saveUserId(response['userId'].toString());
        }
        await SharedPrefs.saveIsNewUser((response['isNewUser'] as bool?) ?? false);
        
        // Update FCM token after successful login
        await NotificationService.refreshAndSendToken();
      }
      
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'OTP verification failed: $e'
      };
    }
  }

  // ============================================
  // 3️⃣ UPDATE FCM TOKEN
  // ============================================
  // Endpoint: POST /api/user/update-fcm-token
  // Description: Update FCM token for push notifications
  static Future<Map<String, dynamic>> updateFcmToken(String userId, String fcmToken) async {
    try {
      final Map<String, dynamic> response = await ApiService.post('/user/update-fcm-token', {
        'userId': userId,
        'fcmToken': fcmToken,
        'userType': 'customer',
      });
      
      // Response structure:
      // {
      //   "success": true,
      //   "message": "FCM token updated successfully"
      // }
      
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'FCM token update failed: $e'
      };
    }
  }

  // ============================================
  // 4️⃣ UPDATE USER LOCATION
  // ============================================
  // Endpoint: POST /api/user/update-location
  // Description: Update user's current location
  static Future<Map<String, dynamic>> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final Map<String, dynamic> response = await ApiService.post('/user/update-location', {
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      });
      
      // Response structure:
      // {
      //   "success": true,
      //   "message": "Location updated successfully",
      //   "data": {
      //     "latitude": 19.0760,
      //     "longitude": 72.8777,
      //     "address": "Marine Drive, Mumbai, Maharashtra, India"
      //   }
      // }
      
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Location update failed: $e'
      };
    }
  }

  // ============================================
  // 5️⃣ CREATE BOOKING ⭐ MAIN ENDPOINT
  // ============================================
  // Endpoint: POST /api/user/booking/create
  // Description: Create a new service booking
  static Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String selectedService,
    required String selectedDate,
    required String selectedTime,
    required Map<String, dynamic> userLocation,
    String? jobDescription,
  }) async {
    try {
      final Map<String, Object> bookingData = {
        'userId': userId,
        'selectedService': selectedService,
        'selectedDate': selectedDate,
        'selectedTime': selectedTime,
        'userLocation': {
          'latitude': userLocation['latitude'],
          'longitude': userLocation['longitude'],
          'address': userLocation['address'],
        },
        'jobDescription': jobDescription ?? '',
      };

      AppLogger.d('📤 Creating booking: $bookingData');

      final Map<String, dynamic> response = await ApiService.post('/user/booking/create', bookingData);
      
      // Response structure:
      // {
      //   "success": true,
      //   "message": "Booking created successfully",
      //   "data": {
      //     "_id": "674b2c3d4e5f6g7h8i9j0k1l",
      //     "userId": "673a1b2c3d4e5f6g7h8i9j0k",
      //     "selectedService": "Plumbing",
      //     "status": "pending",
      //     "selectedDate": "2025-12-05",
      //     "selectedTime": "10:30 AM",
      //     "userLocation": {...},
      //     "jobDescription": "Fix kitchen sink leak",
      //     "createdAt": "2025-12-04T10:25:30.000Z"
      //   }
      // }
      
      AppLogger.i('📥 Booking response: $response');

      return response;
    } catch (e) {
      AppLogger.e('Error creating booking', e);
      return {
        'success': false,
        'message': 'Failed to create booking: $e'
      };
    }
  }

  // ============================================
  // 6️⃣ GET USER PROFILE
  // ============================================
  // Endpoint: GET /api/user/profile/:userId
  // Description: Fetch user profile details
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final Map<String, dynamic> response = await ApiService.get('/user/profile/$userId');
      
      // Response structure:
      // {
      //   "success": true,
      //   "data": {
      //     "userId": "673a1b2c3d4e5f6g7h8i9j0k",
      //     "mobile": "9876543210",
      //     "name": "Ramesh Kumar",
      //     "email": "ramesh@example.com",
      //     "address": "Marine Drive, Mumbai",
      //     "latitude": 19.0760,
      //     "longitude": 72.8777
      //   }
      // }
      
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch profile: $e'
      };
    }
  }

  // ============================================
  // 🚪 LOGOUT
  // ============================================
  // Description: Clear all user data and session
  static Future<void> logout() async {
    try {
      await SharedPrefs.clear();
      AppLogger.i('👤 User logged out successfully');
    } catch (e) {
      AppLogger.e('Error during logout', e);
    }
  }

  // ============================================
  // 🔄 ERROR HANDLING & RETRY LOGIC
  // ============================================
  static Future<Map<String, dynamic>> retryApiCall({
    required Future<Map<String, dynamic>> Function() apiCall,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    var attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        final Map<String, dynamic> response = await apiCall();
        
        if (response['success'] == true) {
          return response;
        }
        
        // If not successful but no exception, retry
        attempts++;
        if (attempts < maxRetries) {
          await Future<void>.delayed(retryDelay * attempts); // Exponential backoff
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          return {
            'success': false,
            'message': 'Failed after $maxRetries attempts: $e'
          };
        }
        await Future<void>.delayed(retryDelay * attempts);
      }
    }
    
    return {
      'success': false,
      'message': 'Max retry attempts reached'
    };
  }

  // ============================================
  // 📊 USAGE EXAMPLE
  // ============================================
  
  /*
  // Example 1: Register User
  final result = await CustomerAPIService.registerUser("9876543210");
  if (result['success'] == true) {
    print("User registered: ${result['userId']}");
  }
  
  // Example 2: Verify OTP
  final otpResult = await CustomerAPIService.verifyOtp("9876543210", "123456");
  if (otpResult['success'] == true) {
    // Navigate to home screen
  }
  
  // Example 3: Create Booking
  final bookingResult = await CustomerAPIService.createBooking(
    userId: "673a1b2c3d4e5f6g7h8i9j0k",
    selectedService: "Plumbing",
    selectedDate: "2025-12-05",
    selectedTime: "10:30 AM",
    userLocation: {
      'latitude': 19.0760,
      'longitude': 72.8777,
      'address': "Marine Drive, Mumbai, Maharashtra, India"
    },
    jobDescription: "Fix kitchen sink leak",
  );
  
  if (bookingResult['success'] == true) {
    String bookingId = bookingResult['data']['_id'];
    // Navigate to booking confirmation screen
  }
  
  // Example 4: Update Location
  final locationResult = await CustomerAPIService.updateUserLocation(
    userId: "673a1b2c3d4e5f6g7h8i9j0k",
    latitude: 19.0760,
    longitude: 72.8777,
    address: "Marine Drive, Mumbai, Maharashtra, India",
  );
  
  // Example 5: Retry API Call
  final retryResult = await CustomerAPIService.retryApiCall(
    apiCall: () => CustomerAPIService.createBooking(...),
    maxRetries: 3,
    retryDelay: Duration(seconds: 2),
  );
  */
}

// ============================================
// 🔐 SECURITY NOTES
// ============================================
/*
1. ✅ All API calls go through backend - no direct vendor contact
2. ✅ FCM token updated on every login
3. ✅ User ID stored securely in SharedPreferences
4. ✅ Location only sent when creating booking or explicitly updated
5. ✅ JWT Authentication: Implemented (Bearer token injected by ApiService)
6. ✅ Add API request signing (HMAC-SHA256)
7. ✅ Implemented certificate pinning in ApiService for production
*/

// ============================================
// 📱 BACKEND BASE URL
// ============================================
// Production: https://convenzcusb-backend.onrender.com
// All endpoints automatically prefixed with /api
// Example: /user/register → https://convenzcusb-backend.onrender.com/api/user/register
