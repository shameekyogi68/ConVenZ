import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/permission.dart';
import '../../utils/shared_prefs.dart'; // ✅ Import SharedPrefs
import '../../widgets/welcome_base_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    PermissionService.requestInitialPermissions();
    _checkLoginStatus();
  }

  // ✅ Logic to check login state
  Future<void> _checkLoginStatus() async {
    // Reduced delay for faster navigation - all initialization done in main()
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    // Check Shared Preferences (already initialized in main)
    final String? userId = SharedPrefs.getUserId();
    final bool isNew = SharedPrefs.getIsNewUser();

    if (userId != null) {
      // User is logged in
      if (isNew) {
        // Profile setup incomplete -> Go to Setup
        context.go('/userSetupCarousel');
      } else {
        // Fully Setup -> Go to Home
        context.go('/home');
      }
    } else {
      // Not logged in -> Go to Welcome
      context.go('/welcomeCarousel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _WelcomeBackground(),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.58,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/convenzlogo.png',
                  height: 100,
                ),
                const SizedBox(height: 50),
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 37.5),
                const Text(
                  'Loading vendor services to you...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reusing the background widget
class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6AACBF), Color(0xFF1F465A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        ClipPath(
          clipper: TopRoundedClipper(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFF3A7A94)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: 85,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/welcome1.png',
            height: 275,
          ),
        ),
      ],
    );
  }
}
