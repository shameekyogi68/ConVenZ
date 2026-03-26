import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/booking.dart';

class FeedbackScreen extends StatefulWidget {
  final Booking booking;

  const FeedbackScreen({super.key, required this.booking});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100),
              
              const Text(
                'Are you satisfied?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Share your opinion:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentMint.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Yes',
                    contentPadding: EdgeInsets.all(20),
                    border: InputBorder.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 80),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to completion
                    context.push('/completion');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentMint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
