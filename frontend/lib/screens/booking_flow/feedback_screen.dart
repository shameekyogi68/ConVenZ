import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/booking.dart';
import '../../widgets/primary_button.dart';

class FeedbackScreen extends StatefulWidget {
  final Booking booking;

  const FeedbackScreen({super.key, required this.booking});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Service Feedback'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Animated Icon or Image
              const Icon(
                Icons.stars_rounded,
                size: 80,
                color: AppColors.primaryTeal,
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'How was your experience?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Your feedback helps us provide better service for your ${widget.booking.serviceName} request.',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Rating Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 48,
                      color: index < _rating ? Colors.amber : Colors.grey[300],
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              
              // Feedback Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Any specific comments? (Optional)',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    contentPadding: EdgeInsets.all(20),
                    border: InputBorder.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              PrimaryButton(
                text: 'Submit Feedback',
                onPressed: () {
                  // In a real app, send both _rating and _feedbackController.text to backend
                  context.go('/home'); // Or to a thank you screen
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you! Your feedback has been recorded.'),
                      backgroundColor: AppColors.primaryTeal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
