import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/text_input.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../utils/shared_prefs.dart';

class MobileNumberScreen extends StatefulWidget {
  final PageController controller;
  const MobileNumberScreen({super.key, required this.controller});

  @override
  State<MobileNumberScreen> createState() => _MobileNumberScreenState();
}

class _MobileNumberScreenState extends State<MobileNumberScreen> {
  final TextEditingController phoneController = TextEditingController();

  // ⭐ UPDATED — API + SharedPrefs integrated (UI untouched)
  void sendOtp() async {
    if (phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid 10-digit mobile number"),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
      return;
    }

    // Save locally for OTP usage later
    // Check if phone number is saved before proceeding
      await SharedPrefs.savePhone(phoneController.text);

    // Call backend API
      final response = await AuthService.registerUser(phoneController.text);

    if (response["success"] == true) {
    // Move to OTP Screen (Page 1)
    widget.controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
     } else {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(response["message"] ?? "Something went wrong"),
           backgroundColor: Colors.red,
         ),
       );
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          // ✅ FIX: Use ClampingScrollPhysics to eliminate the scroll "bounce" look
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Image.asset('assets/images/logo.png', width: 150),
              const SizedBox(height: 80),
              const Text(
                "Mobile Verification",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 40),
              TextInput(
                controller: phoneController,
                labelText: "Mobile Number",
                icon: Icons.phone_android,
                keyboardType: TextInputType.number,
                maxLength: 10,
                prefixText: "+91 ",
              ),
              const SizedBox(height: 40),
              PrimaryButton(text: "Send OTP", onPressed: sendOtp),
              // ✅ FIX: Increased SizedBox to prevent overflow when keyboard is open
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }
}