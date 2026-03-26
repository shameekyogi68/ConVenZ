import 'dart:async';
import '../services/api_service.dart';
import '../utils/shared_prefs.dart';
import '../models/booking.dart';

class BookingService {

  // ----------------------------------------------------------
  // 📅 GET USER BOOKINGS
  // ----------------------------------------------------------
  static Future<List<Booking>> getUserBookings() async {
    try {
      String? userId = SharedPrefs.getUserId();
      if (userId == null) return [];

      // Call GET /api/booking/user/:userId
      final res = await ApiService.get("/booking/user/$userId");

      if (res['success'] == true) {
        List<dynamic> data = res['data'];
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("❌ Error fetching bookings: $e");
      return [];
    }
  }

  // ----------------------------------------------------------
  // 📝 CREATE BOOKING (Enhanced with all required fields)
  // ----------------------------------------------------------
  static Future<Map<String, dynamic>> createBooking({
    required String selectedService,
    required String selectedDate,
    required String selectedTime,
    required Map<String, dynamic> userLocation,
    String? jobDescription,
    String? vendorId,
    double? price,
  }) async {
    try {
      String? userId = SharedPrefs.getUserId();
      if (userId == null) {
        return {"success": false, "message": "User not logged in"};
      }

      // ✅ FIX: Map Flutter fields to exact backend field names
      final bookingData = {
        "userId": userId,
        "selectedService": selectedService,
        "date": selectedDate,                    // Backend expects "date" not "selectedDate"
        "time": selectedTime,                    // Backend expects "time" not "selectedTime"
        "location": userLocation,                // Backend expects "location" not "userLocation"
        "jobDescription": jobDescription ?? "",
      };

      // Add optional fields if provided
      if (vendorId != null) bookingData["vendorId"] = vendorId;
      if (price != null) bookingData["price"] = price;

      print("📤 Creating booking with correct field names: $bookingData");

      final res = await ApiService.post("/user/booking/create", bookingData);
      
      print("📥 Booking response: $res");

      return res;
    } catch (e) {
      print("❌ Error creating booking: $e");
      return {"success": false, "message": "Failed to create booking: $e"};
    }
  }

  // ----------------------------------------------------------
  // 🔄 GET SINGLE BOOKING BY ID
  // ----------------------------------------------------------
  static Future<Booking?> getBookingById(String bookingId) async {
    try {
      final res = await ApiService.get("/booking/$bookingId");

      if (res['success'] == true && res['data'] != null) {
        return Booking.fromJson(res['data']);
      }
      return null;
    } catch (e) {
      print("❌ Error fetching booking: $e");
      return null;
    }
  }

  // ----------------------------------------------------------
  // 🔄 POLL BOOKING STATUS (Every 3 seconds)
  // ----------------------------------------------------------
  static Stream<Booking?> pollBookingStatus(String bookingId) async* {
    while (true) {
      try {
        final booking = await getBookingById(bookingId);
        yield booking;
        
        // Stop polling if booking is in terminal state
        if (booking != null && 
            (booking.status == 'completed' || 
             booking.status == 'cancelled' || 
             booking.status == 'rejected')) {
          break;
        }
        
        // Wait 3 seconds before next poll
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        print("❌ Polling error: $e");
        yield null;
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  // ----------------------------------------------------------
  // ❌ CANCEL BOOKING
  // ----------------------------------------------------------
  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final res = await ApiService.post("/booking/$bookingId/cancel", {});
      return res;
    } catch (e) {
      print("❌ Error cancelling booking: $e");
      return {"success": false, "message": "Failed to cancel booking"};
    }
  }
}