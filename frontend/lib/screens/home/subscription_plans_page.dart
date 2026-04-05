import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/subscription_card.dart';
import '../../config/app_colors.dart';
import '../../models/subscription_plan.dart';
import '../../services/subscription_service.dart';
import '../../utils/shared_prefs.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  late Future<List<SubscriptionPlan>> _plansFuture;
  bool _isLoading = false;
  String? _activeMessage; // Message if user already has active subscription

  @override
  void initState() {
    super.initState();
    _plansFuture = SubscriptionService.getActivePlans();
    _checkActiveSubscription();
  }

  Future<void> _checkActiveSubscription() async {
    try {
      final userId = SharedPrefs.getUserId();
      if (userId == null || userId.isEmpty) return;

      final result = await SubscriptionService.getUserSubscription(userId);
      
      if (result['success'] == true && result['data'] != null) {
        final sub = result['data'];
        final planName = sub['currentPack'] ?? 'Active Plan';
        final expiryDate = sub['expiryDate'];
        
        // Format expiry date
        String formattedDate = '';
        if (expiryDate != null) {
          try {
            final expiry = DateTime.parse(expiryDate);
            formattedDate = '${expiry.day}/${expiry.month}/${expiry.year}';
          } catch (e) {
            formattedDate = expiryDate.toString();
          }
        }

        setState(() {
          _activeMessage = "You have an active $planName until $formattedDate";
        });
      }
    } catch (_) {}
  }

  Future<void> _handlePlanSelection(SubscriptionPlan plan) async {
    setState(() {
      _isLoading = true;
    });

    final result = await SubscriptionService.purchaseSubscription(
      planId: plan.id ?? '',
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.accentMint,
          content: Text("${plan.name} activated successfully!",
              style: const TextStyle(color: Color(0xFF1F465A), fontWeight: FontWeight.w600)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to home screen after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('/home');
      });
    } else {
      // Show error message - could be "already has active subscription" or other error
      String errorMessage = result['message'] ?? 'Failed to activate plan';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.dangerRed,
          content: Text(errorMessage,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );

      // If user already has active subscription, update state to show message
      if (result['statusCode'] == 400 || result['message']?.contains('already have') == true) {
        setState(() {
          _activeMessage = errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 60,
        title: const Text(
          "Choose Your Plan",
          style: TextStyle(color: AppColors.primaryTeal, fontSize: 20),
        ),
        centerTitle: true,
      ),

      body: FutureBuilder<List<SubscriptionPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryTeal,
              ),
            );
          }

          // Error state — user-friendly, no raw message
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load plans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 8),
                  const Text('Check your connection and try again.',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _plansFuture = SubscriptionService.getActivePlans();
                    }),
                    icon: const Icon(Icons.refresh, color: AppColors.primaryTeal),
                    label: const Text('Retry', style: TextStyle(color: AppColors.primaryTeal)),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A5A6D), Color(0xFF2ED199)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryTeal.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, size: 44, color: Colors.white),
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scaleXY(begin: 0.95, end: 1.02, duration: 2500.ms, curve: Curves.easeInOut),
                  
                  const SizedBox(height: 32),
                  
                  const Text(
                    'No Plans Available',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
                  
                  const SizedBox(height: 12),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Please check back soon!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
                ],
              ),
            );
          }

          // Success state - Display plans
          final plans = snapshot.data!;
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: plans.length + (_activeMessage != null ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show active subscription message at top if exists
                  if (_activeMessage != null && index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentMint.withValues(alpha: 0.08),
                        border: Border.all(color: AppColors.accentMint.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: AppColors.accentMint, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _activeMessage ?? '',
                              style: const TextStyle(
                                color: AppColors.primaryTeal,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Adjust index for plans list
                  int planIndex = _activeMessage != null ? index - 1 : index;
                  if (planIndex < 0 || planIndex >= plans.length) return const SizedBox.shrink();

                  final plan = plans[planIndex];
                  return SubscriptionCard(
                    plan: plan,
                    onSelect: _isLoading || _activeMessage != null 
                        ? null 
                        : () => _handlePlanSelection(plan),
                  );
                },
              ),
              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
