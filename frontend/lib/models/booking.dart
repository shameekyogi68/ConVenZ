/// Booking model — maps to the ConVenZ backend bookingModel.js schema
class Booking { // Subscription-based model

  const Booking({
    required this.id,
    required this.bookingId,
    required this.userId,
    this.vendorId,
    required this.selectedService,
    required this.jobDescription,
    required this.date,
    required this.time,
    required this.status,
    this.location,
    this.otpStart,
    this.distance,
    this.createdAt,
    this.updatedAt,
    this.vendor,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested 'vendor' object from backend
    final vendorData = json['vendor'] as Map<String, dynamic>?;
    final externalVendor = json['externalVendor'] as Map<String, dynamic>?;
    
    return Booking(
      id: json['_id']?.toString() ?? '',
      bookingId: (json['booking_id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      vendorId: json['vendorId'] != null ? (json['vendorId'] as num?)?.toInt() : null,
      selectedService: json['selectedService'] as String? ?? 'Service',
      jobDescription: json['jobDescription'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      location: json['location'] as Map<String, dynamic>?,
      otpStart: json['otpStart'] != null ? (json['otpStart'] as num).toInt() : null,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      vendor: vendorData ?? externalVendor,
    );
  }
  final String id;
  final int bookingId;
  final int userId;
  final int? vendorId;
  final String selectedService;
  final String jobDescription;
  final String date;
  final String time;
  final String status;
  final Map<String, dynamic>? location;
  final int? otpStart;
  final double? distance;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Populated vendor data from backend (if available)
  final Map<String, dynamic>? vendor;

  // ── UI convenience getters that match existing screens ──
  String get serviceName    => selectedService;
  
  String get vendorName {
    if (vendor != null && vendor!['name'] != null) {
      return vendor!['name'] as String;
    }
    if (vendor != null && vendor!['vendorName'] != null) {
      return vendor!['vendorName'] as String;
    }
    return vendorId != null ? 'Vendor #$vendorId' : 'Searching...';
  }

  String? get vendorPhone {
    if (vendor != null && vendor!['phone'] != null) {
      return vendor!['phone']?.toString();
    }
    if (vendor != null && vendor!['vendorPhone'] != null) {
      return vendor!['vendorPhone']?.toString();
    }
    return null;
  }

  String? get selectedDate  => date;
  String? get selectedTime  => time;
  Map<String, dynamic>? get userLocation => location;
  double get price => 0.0;

  Map<String, dynamic> toJson() => {
    '_id': id,
    'booking_id': bookingId,
    'userId': userId,
    'vendorId': vendorId,
    'selectedService': selectedService,
    'jobDescription': jobDescription,
    'date': date,
    'time': time,
    'status': status,
    'location': location,
    'otpStart': otpStart,
    'distance': distance,
    'vendor': vendor,
  };
}
