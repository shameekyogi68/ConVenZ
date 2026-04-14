import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';
import '../utils/shared_prefs.dart';
import '../widgets/primary_button.dart';

class BlockedUserScreen extends StatelessWidget {
  const BlockedUserScreen({super.key, this.reason});
  final String? reason;

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
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade100, width: 2),
                ),
                child: const Icon(Icons.block_rounded, size: 60, color: Colors.red),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              const Text(
                'Account Suspended',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

              const SizedBox(height: 12),

              Text(
                reason?.isNotEmpty ?? false
                    ? reason!
                    : 'Your account has been suspended. Please contact our support team for assistance.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.6),
              ).animate().fade(delay: 150.ms),

              const SizedBox(height: 48),

              // Contact card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildContactRow(Icons.email_outlined, 'Email Support', 'support@convenz.com'),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 16),
                    _buildContactRow(Icons.phone_outlined, 'Call Us', '+91 999 999 9999'),
                  ],
                ),
              ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 40),

              PrimaryButton(
                text: 'Log Out',
                onPressed: () async {
                  await SharedPrefs.clear();
                  if (context.mounted) {
                    context.go('/splash');
                  }
                },
              ).animate().fade(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryTeal, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, color: AppColors.darkGrey, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
