import 'package:flutter_test/flutter_test.dart';
import 'package:convenz_customer_app/models/booking.dart';

void main() {
  group('Booking Model Tests', () {
    test('fromJson correctly parses valid backend JSON', () {
      final Map<String, Object> json = {
        '_id': 'abc123',
        'booking_id': 1,
        'userId': 42,
        'vendorId': 7,
        'selectedService': 'Cleaning',
        'jobDescription': 'Clean the living room',
        'date': '2023-10-25',
        'time': '10:00 AM',
        'status': 'accepted',
        'location': {
          'type': 'Point',
          'coordinates': [77.5946, 12.9716],
          'address': '123 MG Road, Bengaluru',
        },
        'otpStart': 4321,
        'distance': 2.5,
        'createdAt': '2023-10-25T10:00:00Z',
        'updatedAt': '2023-10-25T11:00:00Z',
      };

      final booking = Booking.fromJson(json);

      expect(booking.id, 'abc123');
      expect(booking.bookingId, 1);
      expect(booking.userId, 42);
      expect(booking.vendorId, 7);
      expect(booking.selectedService, 'Cleaning');
      expect(booking.serviceName, 'Cleaning'); // convenience getter
      expect(booking.status, 'accepted');
      expect(booking.otpStart, 4321);
      expect(booking.distance, 2.5);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = {
        '_id': 'xyz',
        'selectedService': 'Plumbing',
        'jobDescription': 'Fix pipe',
        'date': '2024-01-10',
        'time': '2:00 PM',
        'status': 'pending',
      };

      final booking = Booking.fromJson(json);

      expect(booking.id, 'xyz');
      expect(booking.bookingId, 0); // defaults to 0
      expect(booking.vendorId, null);
      expect(booking.otpStart, null);
      expect(booking.price, 0.0);     // convenience getter default
      expect(booking.vendorPhone, null); // convenience getter default
    });

    test('toJson serializes correctly', () {
      const booking = Booking(
        id: '123',
        bookingId: 5,
        userId: 42,
        selectedService: 'Plumbing',
        jobDescription: 'Fix the sink',
        date: '2024-01-10',
        time: '3:00 PM',
        status: 'pending',
      );

      final Map<String, dynamic> json = booking.toJson();

      expect(json['_id'], '123');
      expect(json['booking_id'], 5);
      expect(json['userId'], 42);
      expect(json['selectedService'], 'Plumbing');
      expect(json['status'], 'pending');
    });
  });
}
