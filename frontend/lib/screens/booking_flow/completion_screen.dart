import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../widgets/primary_button.dart';

class CompletionScreen extends StatelessWidget {
  const CompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated success checkmark
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5A6D), Color(0xFF2ED199)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentMint.withOpacity(0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 90, color: Colors.white),
              )
                  .animate()
                  .scale(
                    duration: 700.ms,
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1, 1),
                  )
                  .fade(duration: 400.ms),

              const SizedBox(height: 48),

              const Text(
                'Service Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

              const SizedBox(height: 16),

              Text(
                'Your service has been completed successfully.\nWe hope you had a great experience!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.6),
              ).animate().fade(delay: 400.ms),

              const SizedBox(height: 60),

              // Stat chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildChip(Icons.verified_rounded, 'Verified'),
                  const SizedBox(width: 12),
                  _buildChip(Icons.shield_rounded, 'Backed'),
                  const SizedBox(width: 12),
                  _buildChip(Icons.star_rounded, 'Rated'),
                ],
              ).animate().fade(delay: 500.ms),

              const SizedBox(height: 60),

              PrimaryButton(
                text: 'Back to Home',
                onPressed: () => context.go('/home'),
              ).animate().fade(delay: 600.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accentMint),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal)),
        ],
      ),
    );
  }
}
