class SubscriptionPlan {
  final String? id;
  final String name;
  final int price;
  final String duration;
  final List<String> features;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionPlan({
    this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to parse from JSON
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      duration: json['duration'] as String? ?? '',
      features: List<String>.from(json['features'] as List? ?? []),
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'duration': duration,
      'features': features,
      'active': active,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
