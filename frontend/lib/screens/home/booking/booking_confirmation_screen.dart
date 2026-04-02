import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String bookingId;
  final String serviceName;
  final String selectedDate;
  final String selectedTime;
  final String address;
  final String? jobDescription;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
    required this.selectedDate,
    required this.selectedTime,
    required this.address,
    this.jobDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Booking Confirmed', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Success icon
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
                    BoxShadow(color: AppColors.accentMint.withOpacity(0.3), blurRadius: 28, offset: const Offset(0, 10)),
                  ],
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 60),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 20),

              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

              const SizedBox(height: 8),

              Text(
                'Your booking has been created successfully',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ).animate().fade(delay: 150.ms),

              const SizedBox(height: 8),

              // Booking ID pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ID: ${bookingId.length > 8 ? bookingId.substring(bookingId.length - 8) : bookingId}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1),
                ),
              ).animate().fade(delay: 180.ms),

              const SizedBox(height: 28),

              // Details card
              _buildCard([
                _buildRow(Icons.home_repair_service_rounded, 'Service', serviceName),
                _buildDivider(),
                _buildRow(Icons.calendar_today_rounded, 'Date', selectedDate),
                _buildDivider(),
                _buildRow(Icons.access_time_rounded, 'Time', selectedTime),
                _buildDivider(),
                _buildRow(Icons.location_on_rounded, 'Location', address),
                if (jobDescription != null && jobDescription!.isNotEmpty) ...[
                  _buildDivider(),
                  _buildRow(Icons.description_rounded, 'Description', jobDescription!),
                ],
              ]).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 20),

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
                        "We're finding an available vendor near you. You'll get a notification once accepted.",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 280.ms),

              const SizedBox(height: 28),

              PrimaryButton(
                text: 'Track Booking',
                onPressed: () {
                  context.pushReplacement('/vendorSearching', extra: {
                    'bookingId': bookingId,
                    'serviceName': serviceName,
                  });
                },
              ).animate().fade(delay: 320.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home', style: TextStyle(color: AppColors.primaryTeal, fontSize: 15, fontWeight: FontWeight.w600)),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryTeal.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryTeal, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 14, color: AppColors.darkGrey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.shade100);
}
