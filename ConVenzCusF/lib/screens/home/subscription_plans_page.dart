import 'package:flutter/material.dart';
import '../../widgets/subscription_card.dart';
import '../../config/app_colors.dart';
import '../../models/subscription_plan.dart';
import '../../services/subscription_service.dart';
import '../../utils/shared_prefs.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  late Future<List<SubscriptionPlan>> _plansFuture;
  bool _isLoading = false;
  String? _activeMessage; // Message if user already has active subscription
  Map<String, dynamic>? _activeSubscription; // Store active subscription data

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
          _activeSubscription = sub;
        });
      }
    } catch (e) {
      print("❌ Error checking subscription: $e");
    }
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
          backgroundColor: Colors.green,
          content: Text("✅ ${plan.name} activated successfully!"),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate to home screen after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      });
    } else {
      // Show error message - could be "already has active subscription" or other error
      String errorMessage = result['message'] ?? 'Failed to activate plan';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("❌ $errorMessage"),
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

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading plans: ${snapshot.error}",
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          // No data state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No plans available",
                style: TextStyle(color: AppColors.primaryTeal, fontSize: 16),
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
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _activeMessage ?? '',
                              style: const TextStyle(
                                color: Colors.orange,
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
                  color: Colors.black.withOpacity(0.3),
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
