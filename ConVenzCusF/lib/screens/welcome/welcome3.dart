import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../widgets/welcome_base_screen.dart';

class Welcome3 extends StatelessWidget {
  final PageController controller;

  const Welcome3({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return WelcomeBaseScreen(
      title: "Connect Instantly",
      subtitle: "Set up your profile and start booking trusted vendors in real-time.",
      buttonText: "Get Started",
      showBack: true,
      controller: controller,
      imagePath: 'assets/images/welcome3.png',
      onNext: () {
        context.go('/userSetupCarousel');
      },
    );
  }
}
