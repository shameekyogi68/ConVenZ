import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/otp_box.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../utils/shared_prefs.dart';

class OtpScreen extends StatefulWidget {
  final PageController controller;
  const OtpScreen({super.key, required this.controller});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> otpControllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  // ⭐ LOGIC PRESERVED (Conditional Navigation)
  void verifyOtp() async {
    String otp = otpControllers.map((c) => c.text).join();

    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter 4-digit OTP"),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
      return;
    }

    String? phone = SharedPrefs.getPhone();

    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone number missing"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final response = await AuthService.verifyOtp(phone, otp);

    if (response["success"] == true) {
      bool isNewUser = response["isNewUser"] ?? true;

      // ⭐ NEW USER → Go to UserDetailsScreen (Page 2)
      if (isNewUser) {
        widget.controller.animateToPage(
          2,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
      // ⭐ EXISTING USER → Go to OnboardingCompleteScreen (Page 3)
      else {
        widget.controller.animateToPage(
          3,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Invalid OTP"),
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
        child: Stack(
          children: [
            // ✅ FIX: Main content is wrapped in SingleChildScrollView
            SingleChildScrollView(
              // Use ClampingScrollPhysics to remove the scroll "bounce" look
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 100), // Increased top padding
                  Image.asset('assets/images/logo.png', width: 150),
                  const SizedBox(height: 60),
                  const Text(
                    "Enter OTP",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sent to +91 **********",
                    style: TextStyle(fontSize: 16, color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                          (i) => OtpBox(
                        controller: otpControllers[i],
                        focusNode: focusNodes[i],
                        onFilled: i < 3
                            ? () => FocusScope.of(context)
                            .requestFocus(focusNodes[i + 1])
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(text: "Verify OTP", onPressed: verifyOtp),
                  // ✅ FIX: Increased size from 80 to 150 to prevent overflow
                  const SizedBox(height: 150),
                ],
              ),
            ),

            // Back button (remains outside the SingleChildScrollView)

          ],
        ),
      ),
    );
  }
}