import 'package:flutter/material.dart';
import 'mobile_number_screen.dart';
import 'otp_screen.dart';
import 'user_details_screen.dart';
import 'onboarding_complete_screen.dart';

class UserSetupCarousel extends StatefulWidget {
  const UserSetupCarousel({super.key});

  @override
  State<UserSetupCarousel> createState() => _UserSetupCarouselState();
}

class _UserSetupCarouselState extends State<UserSetupCarousel> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          MobileNumberScreen(controller: _controller),
          OtpScreen(controller: _controller),
          UserDetailsScreen(controller: _controller),
          OnboardingCompleteScreen(),
        ],
      ),
    );
  }
}
