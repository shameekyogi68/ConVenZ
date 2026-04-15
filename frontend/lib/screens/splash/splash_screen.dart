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
        if (!mounted) {
          return;
        }
        setState(() {
          _statusMessage = status;

          // Detect cold start: if it's taking more than a few seconds
          if (status.contains('Starting up') || status.contains('warming up')) {
            _isColdStart = true;
          }
        });
      },
    );

    if (!mounted) {
      return;
    }
    _animateProgress(0.85, const Duration(milliseconds: 500));

    // Navigate to the right screen
    await _checkLoginStatus();
  }

  void _animateProgress(double target, Duration duration) {
    final start = _progress;
    const steps = 20;
    const stepDuration = Duration(
      milliseconds: 400 ~/ steps,
    );
    int step = 0;
    Future.doWhile(() async {
      await Future<void>.delayed(stepDuration);
      if (!mounted) {
        return false;
      }
      step++;
      setState(() {
        _progress = start + (target - start) * (step / steps);
      });
      return step < steps;
    });
  }

  Future<void> _checkLoginStatus() async {
    _animateProgress(1.0, const Duration(milliseconds: 200));
    
    if (!mounted) {
      return;
    }

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
                colors: [Color(0xFF0F303E), Color(0xFF1D5B6F), Color(0xFF299991)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── White Wave Top ──
          ClipPath(
            clipper: TopRoundedClipper(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Welcome Image ──
          Positioned(
            top: 75,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/welcome1.png',
              height: 290,
            ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9)),
          ),

          // ── Bottom Content ──
          Positioned(
            bottom: 70,
            left: 32,
            right: 32,
            child: Column(
              children: [
                // Logo with Glow
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 40, spreadRadius: 10),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/convenzlogo.png',
                    height: 85,
                  ),
                ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.15),

                const SizedBox(height: 35),

                // Cold start banner (Glassmorphism)
                if (_isColdStart)
                  _ColdStartBanner(message: _statusMessage)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2),

                if (!_isColdStart) ...[
                  // Minimal smooth spinner
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Sleek Progress Bar ──
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: MediaQuery.of(context).size.width * 0.8 * _progress,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.white70, Colors.white]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
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
