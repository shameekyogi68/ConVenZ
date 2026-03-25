import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/text_input.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart'; // ✅ Import SecondaryButton
import '../../services/profile_service.dart';
import '../../utils/shared_prefs.dart'; // ✅ Import SharedPrefs

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
      name: json['name']?.toString() ?? "",
      phone: json['phone']?.toString() ?? "",
      address: json['address']?.toString() ?? "No Address Available",
    );
  }
}

class CustomerProfileScreen extends StatefulWidget {
  final PageController controller;
  const CustomerProfileScreen({super.key, required this.controller});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  ProfileModel? profile;
  bool isLoading = true;
  bool isEditing = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final FocusNode nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    try {
      final response = await ProfileService.getProfile();

      print("📥 API Response: $response");

      if (response["success"] == true && response["data"] != null) {
        final data = response["data"];
        setState(() {
          profile = ProfileModel.fromJson(data);
          nameController.text = profile!.name;
          phoneController.text = profile!.phone;
          addressController.text = profile!.address;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "Failed to load profile")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching profile")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveProfile() async {
    setState(() => isLoading = true);

    final response = await ProfileService.updateProfile(name: nameController.text);

    if (response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully"), backgroundColor: AppColors.accentMint),
      );
      fetchProfile();
      setState(() => isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Update failed"), backgroundColor: AppColors.primaryTeal),
      );
    }

    setState(() => isLoading = false);
  }

  // ✅ LOGOUT FUNCTION
  void logout() async {
    // 1. Clear all local data
    await SharedPrefs.clear();

    if (mounted) {
      // 2. Navigate to Mobile Number Screen (UserSetupCarousel starts with it)
      // removeUntil((route) => false) removes all previous screens from the stack
      Navigator.of(context).pushNamedAndRemoveUntil('/userSetupCarousel', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : profile == null
          ? const Center(child: Text("No profile data found"))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Image.asset('assets/images/avatar.png', width: 130),
              const SizedBox(height: 20),

              const Text(
                "Customer Profile",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
              ),

              const SizedBox(height: 40),

              /// 👤 Name - Editable
              TextField(
                controller: nameController,
                focusNode: nameFocusNode,
                readOnly: !isEditing,
                onTap: () {
                  setState(() => isEditing = true);
                  nameFocusNode.requestFocus();
                },
                style: TextStyle(
                  color: isEditing ? AppColors.primaryTeal : AppColors.darkGrey,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: AppColors.primaryTeal),
                  labelText: "Name",
                  labelStyle: TextStyle(
                    color: isEditing ? AppColors.primaryTeal : AppColors.darkGrey,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: isEditing ? AppColors.primaryTeal : AppColors.darkGrey,
                    fontWeight: FontWeight.w600,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: AppColors.primaryTeal),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: AppColors.primaryTeal),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(
                      color: AppColors.primaryTeal,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 📞 Phone (Read-Only)
              AbsorbPointer(
                child: TextInput(
                  controller: phoneController,
                  labelText: "Phone Number",
                  icon: Icons.phone_android,
                  prefixText: "+91 ",
                ),
              ),

              const SizedBox(height: 20),

              /// 📍 Address Field (Bigger)
              AbsorbPointer(
                child: TextField(
                  controller: addressController,
                  maxLines: 3,
                  readOnly: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on, color: AppColors.primaryTeal),
                    labelText: "Address",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.primaryTeal),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// 🚀 Show Submit only while editing & focused
              if (isEditing && nameFocusNode.hasFocus)
                Column(
                  children: [
                    PrimaryButton(
                      text: "Submit Changes",
                      onPressed: saveProfile,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // ✅ LOGOUT BUTTON (Using SecondaryButton style)
              SecondaryButton(
                text: "Log Out",
                onPressed: logout,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}