import 'package:flutter_test/flutter_test.dart';
import 'package:convenz_customer_app/models/booking.dart';

void main() {
  group('Booking Model Tests', () {
    test('fromJson correctly parses valid JSON', () {
      final json = {
        '_id': '12345',
        'bookingStatus': 'Accepted',
        'booking_createdAt': '2023-10-25T10:00:00Z',
        'price': 100.0,
        'vendorId': {
           '_id': 'v1',
           'name': 'Test Vendor',
           'phone': '9876543210'
        },
        'servicesId': {
           '_id': 's1',
           'name': 'Cleaning'
        }
      };

      final booking = Booking.fromJson(json);

      expect(booking.id, '12345');
      expect(booking.status, 'Accepted');
      expect(booking.date, '2023-10-25T10:00:00Z');
      expect(booking.price, 100.0);
      expect(booking.vendorName, 'Test Vendor');
      expect(booking.vendorPhone, '9876543210');
      expect(booking.serviceName, 'Cleaning');
    });

    test('toJson creates correctly mapped JSON', () {
      final booking = Booking(
        id: '123',
        status: 'Pending',
        vendorId: 'vendor1',
        vendorName: 'Joe',
        serviceId: 's1',
        serviceName: 'Plumbing',
        date: '2023-11-01',
        price: 50.0,
      );

      final json = booking.toJson();

      expect(json['bookingStatus'], 'Pending');
      expect(json['vendorId'], 'vendor1');
      expect(json['servicesId'], 's1');
      expect(json['price'], 50.0);
    });
  });
}
