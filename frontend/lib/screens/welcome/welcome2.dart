import 'package:flutter/material.dart';
import '../../widgets/welcome_base_screen.dart';

class Welcome2 extends StatelessWidget {
  final PageController controller;

  const Welcome2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return WelcomeBaseScreen(
      title: "Explore Multiple Services",
      subtitle: "From home repairs to events, pet care, and more—get help anytime, anywhere.",
      buttonText: "Next",
      showBack: true,
      controller: controller,
      imagePath: 'assets/images/welcome2.png',
      onNext: () {
        controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      },
    );
  }
}
