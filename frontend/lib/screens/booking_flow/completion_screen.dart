import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class CompletionScreen extends StatelessWidget {
  const CompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: AppColors.accentMint,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              
              const Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Your work is completed successfully.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 120),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Home
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentMint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
