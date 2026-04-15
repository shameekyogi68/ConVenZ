import 'dart:async';
import '../models/booking.dart';
import '../utils/shared_prefs.dart';
import 'api_service.dart';

class BookingService {
  // ─────────────────────────────────────────────
  /// GET all bookings for the logged-in user
  // ─────────────────────────────────────────────
  static Future<List<Booking>> getUserBookings() async {
    try {
      final String? userId = SharedPrefs.getUserId();
      if (userId == null || userId.isEmpty) {
        return [];
      }

      // Backend route: GET /api/user/bookings/:userId
      final Map<String, dynamic> res = await ApiService.get('/user/bookings/$userId');

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as List<dynamic>;
        return data
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  /// CREATE a new booking
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> createBooking({
    required String selectedService,
    required String selectedDate,
    required String selectedTime,
    required Map<String, dynamic> userLocation,
    String jobDescription = '',
  }) async {
    try {
      final String? userId = SharedPrefs.getUserId();
      if (userId == null || userId.isEmpty) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // ✅ Field names exactly match backend Joi validation schema
      final Map<String, dynamic> bookingData = {
        'selectedService': selectedService,
        'date': selectedDate,
        'time': selectedTime,
        'location': userLocation,
        'jobDescription': jobDescription.isEmpty ? selectedService : jobDescription,
      };

      // Backend route: POST /api/user/booking/create (protected)
      return await ApiService.post('/user/booking/create', bookingData);
    } catch (e) {
      return {'success': false, 'message': 'Failed to create booking: $e'};
    }
  }

  // ─────────────────────────────────────────────
  /// GET a single booking by its ID
  // ─────────────────────────────────────────────
  static Future<Booking?> getBookingById(String bookingId) async {
    try {
      // Backend route: GET /api/user/booking/:bookingId
      final Map<String, dynamic> res = await ApiService.get('/user/booking/$bookingId');

      if (res['success'] == true && res['data'] != null) {
        return Booking.fromJson(res['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  /// POLL booking status every 5 seconds until it reaches a terminal state
  // ─────────────────────────────────────────────
  static Stream<Booking?> pollBookingStatus(String bookingId) async* {
    const terminalStatuses = {'completed', 'cancelled', 'rejected'};
    while (true) {
      try {
        final Booking? booking = await getBookingById(bookingId);
        yield booking;
        if (booking != null && terminalStatuses.contains(booking.status)) {
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 5));
      } catch (_) {
        yield null;
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  // ─────────────────────────────────────────────
  /// CANCEL a booking by its ID
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      // Backend route: POST /api/user/booking/:bookingId/cancel
      return await ApiService.post('/user/booking/$bookingId/cancel', {});
    } catch (e) {
      return {'success': false, 'message': 'Failed to cancel booking: $e'};
    }
  }

  // ─────────────────────────────────────────────
  /// MOCK: Assign a mock vendor for QA
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> mockAssignVendor(String bookingId) async {
    try {
      return await ApiService.post('/user/booking/$bookingId/mock-assign-vendor', {});
    } catch (e) {
      return {'success': false, 'message': 'Failed to assign mock vendor: $e'};
    }
  }
}
