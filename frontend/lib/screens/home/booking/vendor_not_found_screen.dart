import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';

class VendorNotFoundScreen extends StatelessWidget {
  final String bookingId;
  final String serviceName;
  
  const VendorNotFoundScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
  });

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
                // 🚫 Vendor Not Found Avatar with red cross
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Large dimmed avatar image
                    ClipOval(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5),
                          BlendMode.darken,
                        ),
                        child: Image.asset(
                          "assets/images/avatar.png",
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 180,
                              height: 180,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ❌ Red cross badge overlay
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

                // Title
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

                // Message
                Text(
                  "We couldn't locate any $serviceName vendor\nmatching your request. Try expanding your search.",
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.darkGrey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Booking ID
                Text(
                  "Booking ID: #${bookingId.substring(bookingId.length > 8 ? bookingId.length - 8 : 0)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 40),

                // Expand Search Button
                PrimaryButton(
                  text: "Expand Search",
                  onPressed: () {
                    // TODO: Implement expand search functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expanding search area...'),
                        backgroundColor: AppColors.primaryTeal,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Back to Home Button
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
