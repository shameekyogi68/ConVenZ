import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void sendOtp() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    final phone = phoneController.text.trim();

    // Validate: exactly 10 digits
    if (phone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await SharedPrefs.savePhone(phone);
    final response = await AuthService.registerUser(phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      widget.controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Something went wrong. Please try again.'),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 80),
                Image.asset('assets/images/logo.png', width: 150),
                const SizedBox(height: 80),
                const Text(
                  'Mobile Verification',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We'll send an OTP to your number",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),
                TextInput(
                  controller: phoneController,
                  labelText: 'Mobile Number',
                  icon: Icons.phone_android,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  prefixText: '+91 ',
                ),
                const SizedBox(height: 40),
                PrimaryButton(
                  text: 'Send OTP',
                  onPressed: _isLoading ? null : sendOtp,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
