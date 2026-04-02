import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/booking.dart';
import '../../widgets/primary_button.dart';

class BookingOtpScreen extends StatefulWidget {
  final Booking booking;
  const BookingOtpScreen({super.key, required this.booking});

  @override
  State<BookingOtpScreen> createState() => _BookingOtpScreenState();
}

class _BookingOtpScreenState extends State<BookingOtpScreen> {
  @override
  Widget build(BuildContext context) {
    final otp = widget.booking.otpStart?.toString() ?? '----';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Start Service', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Icon with gradient background
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5A6D), Color(0xFF2ED199)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.vpn_key_rounded, size: 50, color: Colors.white),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 28),

              const Text(
                'Verify with Professional',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

              const SizedBox(height: 12),

              Text(
                'Share this OTP with the vendor once they arrive at your doorstep.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ).animate().fade(delay: 150.ms),

              const SizedBox(height: 40),

              // OTP Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.15), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'YOUR SERVICE OTP',
                      style: TextStyle(
                        letterSpacing: 4,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      otp,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 16,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Copy button
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: otp));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('OTP copied to clipboard'),
                            backgroundColor: AppColors.primaryTeal,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.accentMint),
                      label: const Text('Copy OTP', style: TextStyle(color: AppColors.accentMint, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentMint.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentMint.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.accentMint, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Do not share this OTP with anyone other than the assigned vendor.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 300.ms),

              const SizedBox(height: 40),

              PrimaryButton(
                text: 'Back to Dashboard',
                onPressed: () => context.go('/home'),
              ).animate().fade(delay: 350.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
