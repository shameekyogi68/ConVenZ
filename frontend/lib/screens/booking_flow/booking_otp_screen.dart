import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
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
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) controller.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Start Service'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              const Hero(
                tag: 'otp-icon',
                child: Icon(
                  Icons.vpn_key_rounded,
                  size: 80,
                  color: AppColors.primaryTeal,
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Verify with Professional',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Please share your service OTP with the professional\nto start the work.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),

              // OTP Display (since this is customer app, CUSTOMER holds the OTP)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'YOUR SERVICE OTP',
                      style: TextStyle(
                        letterSpacing: 4,
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.booking.otpStart?.toString() ?? 'xxxx',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 20,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 80),
              
              PrimaryButton(
                text: 'Done - Work Started',
                onPressed: () {
                  // This is a UI-only flow, in reality the backend updates status.
                  // We'll proceed to feedback to simulate a completion flow.
                  context.push('/feedback', extra: widget.booking);
                },
              ),
              
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
