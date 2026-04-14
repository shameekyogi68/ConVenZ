import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../utils/shared_prefs.dart';
import '../../widgets/otp_box.dart';
import '../../widgets/primary_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.controller});
  final PageController controller;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  // 60-second resend countdown
  int _resendCountdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final TextEditingController c in otpControllers) {
      c.dispose();
    }
    for (final FocusNode f in focusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _maskedPhone {
    final String phone = SharedPrefs.getPhone() ?? '';
    if (phone.length >= 10) {
      return '+91 ${phone.substring(0, 2)}****${phone.substring(6)}';
    }
    return '+91 **********';
  }

  Future<void> _resendOtp() async {
    final String? phone = SharedPrefs.getPhone();
    if (phone == null) {
      return;
    }

    setState(() => _isResending = true);
    final Map<String, dynamic> response = await AuthService.registerUser(phone);
    if (!mounted) {
      return;
    }
    setState(() => _isResending = false);

    if (response['success'] == true) {
      // Clear current OTP inputs
      for (final TextEditingController c in otpControllers) {
        c.clear();
      }
      focusNodes[0].requestFocus();
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP resent successfully'),
          backgroundColor: AppColors.accentMint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((response['message'] as String?) ?? 'Failed to resend OTP'),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> verifyOtp() async {
    FocusScope.of(context).unfocus();

    final String otp = otpControllers.map((c) => c.text).join();

    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the complete 4-digit OTP'),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final String? phone = SharedPrefs.getPhone();
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone number missing. Please restart.'),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final Map<String, dynamic> response = await AuthService.verifyOtp(phone, otp);
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      final bool isNewUser = (response['isNewUser'] as bool?) ?? true;
      widget.controller.animateToPage(
        isNewUser ? 2 : 3,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else {
      // Clear boxes on wrong OTP
      for (final TextEditingController c in otpControllers) {
        c.clear();
      }
      focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((response['message'] as String?) ?? 'Invalid OTP. Please try again.'),
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
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    Image.asset('assets/images/logo.png', width: 150),
                    const SizedBox(height: 60),
                    const Text(
                      'Enter OTP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sent to $_maskedPhone',
                      style: const TextStyle(fontSize: 16, color: AppColors.darkGrey),
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
                    const SizedBox(height: 32),

                    // Resend row
                    if (_isResending) const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryTeal,
                            ),
                          ) else _resendCountdown > 0
                            ? Text(
                                'Resend OTP in ${_resendCountdown}s',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade500),
                              )
                            : TextButton(
                                onPressed: _resendOtp,
                                child: const Text(
                                  'Resend OTP',
                                  style: TextStyle(
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Verify OTP',
                      onPressed: _isLoading ? null : verifyOtp,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 150),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
