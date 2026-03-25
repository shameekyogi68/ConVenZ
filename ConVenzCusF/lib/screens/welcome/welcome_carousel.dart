import 'package:flutter/material.dart';
import 'welcome1.dart';
import 'welcome2.dart';
import 'welcome3.dart';

class WelcomeCarousel extends StatefulWidget {
  const WelcomeCarousel({super.key});

  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        children: [
          Welcome1(controller: _controller),
          Welcome2(controller: _controller),
          Welcome3(controller: _controller),
        ],
      ),
    );
  }
}
