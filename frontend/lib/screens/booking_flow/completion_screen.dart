import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/booking.dart';
import '../../widgets/primary_button.dart';
import '../../services/booking_service.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  int _rating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Service Complete', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              // Animated success checkmark
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5A6D), Color(0xFF2ED199)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentMint.withOpacity(0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 90, color: Colors.white),
              )
                  .animate()
                  .scale(
                    duration: 700.ms,
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1, 1),
                  )
                  .fade(duration: 400.ms),

              const SizedBox(height: 48),

              Text(
                'Service Complete!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

              const SizedBox(height: 16),

              Text(
                'Your service has been completed successfully.\nWe hope you had a great experience!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.6),
              ).animate().fade(delay: 400.ms),

              const SizedBox(height: 40),

              // Rating Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8)),
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate Your Experience',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'How was your service with ${widget.booking.vendorName ?? 'Mock Vendor'}?',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    // Star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: AppColors.primaryTeal,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Feedback field
                    TextField(
                      controller: _feedbackController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your feedback (optional)',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Submit button or error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                PrimaryButton(
                  text: 'Submit Feedback',
                  isLoading: _isSubmitting,
                  onPressed: _submitFeedback,
                ).animate().fade(delay: 600.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please provide a rating before submitting feedback.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final result = await BookingService.submitReview(
        widget.booking.booking_id!,
        _rating,
        _feedbackController.text.trim(),
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your feedback!'),
              backgroundColor: AppColors.primaryTeal,
            ),
          );
          // Navigate to home after successful submission
          context.go('/home');
        }
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to submit feedback. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to submit feedback. Please try again.';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
