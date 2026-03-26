class Booking {
  final String id;
  final String vendorId;
  final String vendorName;
  final String? vendorPhone;
  final String serviceId;
  final String serviceName;
  final double price;
  final String status;
  final String date;
  final String? selectedDate;
  final String? selectedTime;
  final String? jobDescription;
  final Map<String, dynamic>? userLocation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    this.vendorPhone,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.status,
    required this.date,
    this.selectedDate,
    this.selectedTime,
    this.jobDescription,
    this.userLocation,
    this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle populated fields safely
    final vendor = json['vendorId'] ?? {};
    final service = json['servicesId'] ?? {};

    return Booking(
      id: json['_id'] ?? '',
      vendorId: vendor is String ? vendor : (vendor['_id'] ?? ''),
      vendorName: vendor is Map ? (vendor['name'] ?? 'Unknown Vendor') : 'Unknown Vendor',
      vendorPhone: vendor is Map ? vendor['phone'] : null,
      serviceId: service is String ? service : (service['_id'] ?? ''),
      serviceName: service is Map ? (service['name'] ?? 'General Service') : 'General Service',
      price: (json['price'] ?? 0).toDouble(),
      status: json['bookingStatus'] ?? 'pending',
      date: json['booking_createdAt'] ?? DateTime.now().toString(),
      selectedDate: json['selectedDate'],
      selectedTime: json['selectedTime'],
      jobDescription: json['jobDescription'],
      userLocation: json['userLocation'],
      createdAt: json['booking_createdAt'] != null 
          ? DateTime.tryParse(json['booking_createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vendorId': vendorId,
      'servicesId': serviceId,
      'price': price,
      'bookingStatus': status,
      'selectedDate': selectedDate,
      'selectedTime': selectedTime,
      'jobDescription': jobDescription,
      'userLocation': userLocation,
    };
  }
}