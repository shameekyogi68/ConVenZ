import 'dart:async';
import 'package:flutter/material.dart';
import '/../../config/app_colors.dart';
import 'vendor_notfound.dart';
import '/../../widgets/secondary_button.dart';

class VendorSearchScreen extends StatefulWidget {
  const VendorSearchScreen({super.key});

  @override
  State<VendorSearchScreen> createState() => _VendorSearchScreenState();
}

class _VendorSearchScreenState extends State<VendorSearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double progress = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        progress += 0.0033;
        if (progress >= 1.0) {
          timer.cancel();
        }
      });
    });

    Future.delayed(const Duration(seconds: 30), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VendorNotFoundPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🌊 Waves start OUTSIDE avatar, with clean empty center gap
            SizedBox(
              width: 380,
              height: 380,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(3, (i) {
                        final value = (_controller.value + i * 0.33) % 1;
                        return Container(
                          width: 200 + (value * 280), // 👈 Starts OUTSIDE avatar (180 used)
                          height: 200 + (value * 280),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentMint.withOpacity(
                              (1 - value * 1.4).clamp(0.0, 0.25),
                            ),
                          ),
                        );
                      }),

                      // 📷 Center Avatar (not affected by waves)
                      Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            "assets/images/avatar.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Searching for Vendor...",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Please wait while we locate your vendor.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 18,
                  backgroundColor: AppColors.accentMint.withOpacity(0.15),
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SecondaryButton(
                text: "Cancel Search",
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
