import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';

class VendorNotFoundScreen extends StatelessWidget {

  const VendorNotFoundScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
  });
  final String bookingId;
  final String serviceName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Search Result', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade100, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.saturation),
                          child: Image.asset(
                            'assets/images/avatar.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 52, color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              const Text(
                'No Vendor Found',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

              const SizedBox(height: 12),

              Text(
                "We couldn't find an available $serviceName vendor\nin your area right now.",
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.6),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 150.ms),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Booking ID: #${bookingId.length > 8 ? bookingId.substring(bookingId.length - 8) : bookingId}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1),
                ),
              ).animate().fade(delay: 180.ms),

              const SizedBox(height: 48),

              // Suggestions card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSuggestion(Icons.schedule_rounded, 'Try at a different time of day'),
                    const SizedBox(height: 12),
                    _buildSuggestion(Icons.location_searching_rounded, 'Expand your search area'),
                    const SizedBox(height: 12),
                    _buildSuggestion(Icons.support_agent_rounded, 'Contact support for help'),
                  ],
                ),
              ).animate().fade(delay: 220.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 36),

              PrimaryButton(
                text: 'Try Again',
                onPressed: () => context.go('/home'),
              ).animate().fade(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              SecondaryButton(
                text: 'Back to Home',
                onPressed: () => context.go('/home'),
              ).animate().fade(delay: 350.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestion(IconData icon, String text) {
    return Row(
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
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.darkGrey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
