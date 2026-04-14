/// User profile model — maps to the backend User schema
class ProfileModel {

  ProfileModel({
    this.userId,
    required this.name,
    required this.phone,
    required this.address,
    this.gender,
    this.isOnline = false,
    this.isBlocked = false,
    this.subscriptionId,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'] != null ? (json['user_id'] as num).toInt() : null,
      name: json['name'] as String? ?? 'User',
      phone: json['phone']?.toString() ?? '',
      address: json['address'] as String? ?? 'No address set',
      gender: json['gender'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      subscriptionId: json['subscription']?.toString(),
    );
  }
  final int? userId;
  final String name;
  final String phone;
  final String address;
  final String? gender;
  final bool isOnline;
  final bool isBlocked;
  final String? subscriptionId;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'phone': phone,
        'address': address,
        'gender': gender,
        'isOnline': isOnline,
      };

  /// Returns display name or masked phone if name is not set
  String get displayName =>
      name.isNotEmpty ? name : 'User #$userId';
}
