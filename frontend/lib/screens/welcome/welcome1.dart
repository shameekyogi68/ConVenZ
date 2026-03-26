import 'package:flutter/material.dart';
import '../../widgets/welcome_base_screen.dart';

class Welcome1 extends StatelessWidget {
  final PageController controller;

  const Welcome1({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return WelcomeBaseScreen(
      title: "Welcome to ConVenz",
      subtitle: "Find trusted service providers for every need—instantly and easily.",
      buttonText: "Next",
      imagePath: 'assets/images/welcome1.png',
      onNext: () async {
        await Future.delayed(const Duration(milliseconds: 50));
        controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      },
    );
  }
}
