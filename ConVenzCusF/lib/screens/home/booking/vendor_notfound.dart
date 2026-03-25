import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';

class VendorNotFoundPage extends StatelessWidget {
  const VendorNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🚫 High Quality Vendor Not Found Avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Large dimmed avatar image
                    ClipOval(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5), // Dimmed look
                          BlendMode.darken,
                        ),
                        child: Image.asset(
                          "assets/images/avatar.png", // Your placeholder image
                          width: 180, // 👈 Larger size
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // ❌ Red cross badge (overlay)
                    Positioned(
                      bottom: 18,
                      right: 18,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ---------- TITLE ----------
                const Text(
                  "Vendor Not Found",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // ---------- MESSAGE ----------
                const Text(
                  "We couldn’t locate any vendor matching your request.\nTry expanding your search.",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.darkGrey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // 🔵 Expand Search Button
                PrimaryButton(
                  text: "Expand Search",
                  onPressed: () {
                    // TODO: Implement expand search
                  },
                ),

                const SizedBox(height: 16),

                // 🔘 Back to Home Button
                SecondaryButton(
                  text: "Back to Home",
                  onPressed: () {
                    context.go('/home');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
