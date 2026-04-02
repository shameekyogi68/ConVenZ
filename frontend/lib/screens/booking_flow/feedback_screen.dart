import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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

  final List<String> _ratingLabels = ['Terrible', 'Bad', 'Okay', 'Good', 'Excellent'];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryTeal),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Rate Your Service', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Icon / hero area
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5A6D), Color(0xFF2ED199)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Icon(Icons.star_rounded, size: 52, color: Colors.white),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              const Text(
                'How was your experience?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

              const SizedBox(height: 8),

              Text(
                widget.booking.serviceName,
                style: const TextStyle(fontSize: 15, color: AppColors.accentMint, fontWeight: FontWeight.w600),
              ).animate().fade(delay: 150.ms),

              const SizedBox(height: 32),

              // Star rating card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _ratingLabels[_rating - 1],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final filled = index < _rating;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              key: ValueKey('$index-$filled'),
                              size: 46,
                              color: filled ? const Color(0xFFFACC15) : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 20),

              // Feedback input card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 15, color: AppColors.darkGrey),
                  decoration: InputDecoration(
                    hintText: 'Share your experience... (Optional)',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    contentPadding: const EdgeInsets.all(20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ).animate().fade(delay: 250.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Submit Feedback',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Thank you! Your feedback has been recorded.'),
                      backgroundColor: AppColors.accentMint,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                  await Future.delayed(const Duration(milliseconds: 1500));
                  if (context.mounted) context.go('/home');
                },
              ).animate().fade(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => context.go('/home'),
                child: Text('Skip for now', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
