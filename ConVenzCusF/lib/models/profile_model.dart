class ProfileModel {
  final String name;
  final String phone;
  final String address;

  ProfileModel({
    required this.name,
    required this.phone,
    required this.address,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'] ?? "",
      phone: json['phone'] ?? "",
      address: json['address'] ?? "No Address Available",
    );
  }
}
