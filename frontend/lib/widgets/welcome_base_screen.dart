import 'package:flutter/material.dart';

class WelcomeBaseScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onNext;
  final bool showBack;
  final PageController? controller;
  final String imagePath; // NEW

  const WelcomeBaseScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onNext,
    required this.imagePath, // NEW
    this.showBack = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6AACBF),
                  Color(0xFF1F465A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Curved top white-teal section
          ClipPath(
            clipper: TopRoundedClipper(), // 🔹 NO MORE ERROR
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Color(0xFF3A7A94),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Image (Position unchanged)
          Positioned(
            top: 85,
            left: 0,
            right: 0,
            child: Image.asset(
              imagePath, // Dynamic image
              height: 275,
            ),
          ),

          // Back Button
          if (showBack)
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                onPressed: () {
                  controller?.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
                icon: const Icon(
                  Icons.arrow_back,
                  size: 28,
                  color: Colors.black87,
                ),
              ),
            ),

          // Page content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                Padding(
                  padding: const EdgeInsets.only(top: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Next Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Add this at the end of the same file (do NOT remove it)
class TopRoundedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.15);

    path.arcToPoint(
      Offset(0, size.height * 0.35),
      radius: Radius.circular(size.width / 2),
      clockwise: true,
    );

    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
