import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../services/server_wake_service.dart';
import '../../utils/permission.dart';
import '../../utils/shared_prefs.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _statusMessage = 'Connecting to server...';
  double _progress = 0.0;
  bool _isColdStart = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    PermissionService.requestInitialPermissions();
    _initializeApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Start progress animation
    _animateProgress(0.15, const Duration(milliseconds: 400));

    // Ping server and wait for it to wake up
    await ServerWakeService.wakeUp(
      onStatusUpdate: (status) {
        if (!mounted) return;
        setState(() {
          _statusMessage = status;

          // Detect cold start: if it's taking more than a few seconds
          if (status.contains('Starting up') || status.contains('warming up')) {
            _isColdStart = true;
          }
        });
      },
    );

    if (!mounted) return;
    _animateProgress(0.85, const Duration(milliseconds: 500));

    // Navigate to the right screen
    await _checkLoginStatus();
  }

  void _animateProgress(double target, Duration duration) {
    final start = _progress;
    final steps = 20;
    final stepDuration = Duration(
      milliseconds: duration.inMilliseconds ~/ steps,
    );
    int step = 0;
    Future.doWhile(() async {
      await Future<void>.delayed(stepDuration);
      if (!mounted) return false;
      step++;
      setState(() {
        _progress = start + (target - start) * (step / steps);
      });
      return step < steps;
    });
  }

  Future<void> _checkLoginStatus() async {
    _animateProgress(1.0, const Duration(milliseconds: 300));
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    final String? userId = SharedPrefs.getUserId();
    final bool isNew = SharedPrefs.getIsNewUser();

    if (userId != null) {
      if (isNew) {
        context.go('/userSetupCarousel');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/welcomeCarousel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background Gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6AACBF), Color(0xFF1F465A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── White Wave Top ──
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

          // ── Welcome Image ──
          Positioned(
            top: 85,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/welcome1.png',
              height: 275,
            ),
          ),

          // ── Bottom Content ──
          Positioned(
            bottom: 80,
            left: 32,
            right: 32,
            child: Column(
              children: [
                // Logo
                Image.asset(
                  'assets/images/convenzlogo.png',
                  height: 80,
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

                const SizedBox(height: 40),

                // Cold start banner (only shown when server is waking up)
                if (_isColdStart)
                  _ColdStartBanner(message: _statusMessage)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3),

                if (!_isColdStart) ...[
                  // Normal spinner
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Progress Bar ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 4,
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

/// Friendly banner shown only during a cold start (first 30–60 sec)
class _ColdStartBanner extends StatelessWidget {
  final String message;
  const _ColdStartBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Server Starting Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message.isEmpty
                      ? 'This takes about 30–60 seconds on first launch.'
                      : message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background Clipper ──
class TopRoundedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.65,
      size.width,
      size.height * 0.55,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
