import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/text_input.dart';
import '../../services/auth_service.dart';
import '../../utils/shared_prefs.dart';

class UserDetailsScreen extends StatefulWidget {
  final PageController controller;
  const UserDetailsScreen({super.key, required this.controller});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final TextEditingController nameController = TextEditingController();
  String? selectedGender;

  // ⭐ UPDATED = Backend + SharedPrefs integration (UI untouched)
  void continueNext() async {
    // Validate fields
    if (nameController.text.isEmpty || selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your name and select gender"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get phone saved earlier
    String? phone = SharedPrefs.getPhone();
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone number missing! Restart onboarding."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // API call to update user details
    final response = await AuthService.updateUserDetails(
      phone,
      nameController.text,
      selectedGender!,
    );

    if (response["success"] == true) {
      // Move to OnboardingCompleteScreen
      widget.controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"]),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void goBack() {
    if (widget.controller.hasClients) {
      widget.controller.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Back button (UNCHANGED)
            Positioned(
              top: 20,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primaryTeal),
                onPressed: goBack,
              ),
            ),

            // Main content (UNCHANGED)
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  Image.asset('assets/images/logo.png', width: 150),
                  const SizedBox(height: 80),
                  const Text(
                    "Your Details",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextInput(
                    controller: nameController,
                    labelText: "Full Name",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: "Gender",
                        labelStyle: TextStyle(
                          color: AppColors.darkGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: selectedGender,
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(value: "Female", child: Text("Female")),
                        DropdownMenuItem(value: "Other", child: Text("Other")),
                      ],
                      onChanged: (value) => setState(() => selectedGender = value),
                    ),
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(text: "Continue", onPressed: continueNext),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
