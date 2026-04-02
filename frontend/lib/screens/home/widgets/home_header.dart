import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_colors.dart';
import '../../../../providers/user_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    "Current Location",
                    style: TextStyle(color: AppColors.darkGrey, fontSize: 13, letterSpacing: 0.5),
                  ).animate().fade().slideY(begin: -0.2, end: 0, duration: 400.ms),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.primaryTeal, size: 18),
                      ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userProvider.currentAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ).animate().fade(delay: 300.ms).slideX(begin: -0.05, end: 0, duration: 400.ms),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Profile entry or notification icon could go here if needed
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryTeal),
            ).animate().fade(delay: 400.ms).scale(curve: Curves.easeOutBack),
          ],
        );
      },
    );
  }
}
