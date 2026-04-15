import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/booking.dart';
import '../../widgets/primary_button.dart';
import '../../services/booking_service.dart';

class BookingOtpScreen extends StatefulWidget {
  const BookingOtpScreen({super.key, required this.booking});
  final Booking booking;

  @override
  State<BookingOtpScreen> createState() => _BookingOtpScreenState();
}

class _BookingOtpScreenState extends State<BookingOtpScreen> {
  bool _isVerifying = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final String otp = widget.booking.otpStart?.toString() ?? '----';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getStatusTitle(),
          style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
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
                child: Icon(
                  _getStatusIcon(),
                  size: 50,
                  color: Colors.white,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 28),

              Text(
                _getVerificationTitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

              const SizedBox(height: 12),

              Text(
                _getVerificationSubtitle(),
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
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
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

              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fade(delay: 250.ms),

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
                        _getInfoMessage(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 300.ms),

              const SizedBox(height: 40),

              // Action buttons
              if (widget.booking.status == 'accepted')
                PrimaryButton(
                  text: 'Start Service',
                  isLoading: _isVerifying,
                  onPressed: _isVerifying ? null : _verifyOtp,
                ).animate().fade(delay: 350.ms, duration: 400.ms).slideY(begin: 0.2, end: 0)
              else
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

  String _getStatusTitle() {
    switch (widget.booking.status) {
      case 'accepted':
        return 'Start Service';
      case 'enroute':
        return 'Service in Progress';
      case 'completed':
        return 'Service Completed';
      default:
        return 'Verify Service';
    }
  }

  String _getVerificationTitle() {
    switch (widget.booking.status) {
      case 'accepted':
        return 'Verify with Professional';
      case 'enroute':
        return 'Professional is En Route';
      case 'completed':
        return 'Service Completed';
      default:
        return 'Verify with Professional';
    }
  }

  String _getVerificationSubtitle() {
    switch (widget.booking.status) {
      case 'accepted':
        return 'Share this OTP with vendor once they arrive at your doorstep.';
      case 'enroute':
        return 'Professional is on the way to your location.';
      case 'completed':
        return 'Service has been completed successfully.';
      default:
        return 'Share this OTP with vendor once they arrive at your doorstep.';
    }
  }

  String _getInfoMessage() {
    switch (widget.booking.status) {
      case 'accepted':
        return 'Do not share this OTP with anyone other than the assigned vendor.';
      case 'enroute':
        return 'Professional is en route with your OTP verification.';
      case 'completed':
        return 'Service was completed successfully.';
      default:
        return 'Do not share this OTP with anyone other than the assigned vendor.';
    }
  }

  IconData _getStatusIcon() {
    switch (widget.booking.status) {
      case 'accepted':
        return Icons.vpn_key_rounded;
      case 'enroute':
        return Icons.delivery_dining_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.vpn_key_rounded;
    }
  }

  Future<void> _verifyOtp() async {
    if (widget.booking.otpStart == null) {
      setState(() {
        _error = 'OTP not available. Please try again.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      // Call backend to verify OTP and start service
      final result = await BookingService.verifyJobOtp(
        widget.booking.booking_id!,
        widget.booking.otpStart.toString(),
      );

      if (result['success'] == true) {
        // Navigate to completion screen
        if (mounted) {
          context.go('/completion', extra: widget.booking);
        }
      } else {
        setState(() {
          _error = result['message'] ?? 'Verification failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to verify OTP. Please try again.';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }
}
