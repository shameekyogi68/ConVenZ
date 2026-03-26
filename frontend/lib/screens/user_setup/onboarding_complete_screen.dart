import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_services.dart';
import '../../services/auth_service.dart';
import '../../utils/shared_prefs.dart';

class OnboardingCompleteScreen extends StatefulWidget {
  final String? userName;

  const OnboardingCompleteScreen({super.key, this.userName});

  @override
  State<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen>
    with SingleTickerProviderStateMixin {
  bool _animate = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _animate = true;
      });
    });
  }

  void goToDashboard() async {
    if (_isLoading) return;

    setState(() { _isLoading = true; });

    // 1. Get User ID
    String? userId = SharedPrefs.getUserId();

    if (userId == null) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User ID not found. Please log in again.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Get Location & Update Server
    try {
      Position? position = await LocationService.determinePosition();

      if (position != null) {
        final apiResponse = await AuthService.updateUserLocation(
          userId,
          position.latitude,
          position.longitude,
        );

        if (apiResponse['success'] != true) {
          // Log error but allow proceeding
          print("Location update failed: ${apiResponse['message']}");
        }
      }
    } catch (e) {
      print('Location error: $e');
    }

    // 3. ✅ NAVIGATION FIX: Go to Home and clear back stack
    setState(() { _isLoading = false; });

    if (mounted) {
      // This removes all previous routes (splash, setup, etc.) so "Back" exits the app
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                ),
              ),
              const SizedBox(height: 50),
              AnimatedScale(
                scale: _animate ? 1 : 0.4,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: _animate ? 1 : 0,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeIn,
                  child: Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: AppColors.accentMint.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF02BEAF),
                        size: 80,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Text(
                "Welcome${widget.userName != null ? ", ${widget.userName!}" : ""}!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTeal,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "You’re all set up! Let’s get started and explore your dashboard.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 60),
              PrimaryButton(
                text: _isLoading ? "Setting up..." : "Go to Dashboard",
                onPressed: goToDashboard,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}