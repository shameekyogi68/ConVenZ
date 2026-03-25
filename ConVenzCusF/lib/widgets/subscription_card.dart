import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../config/app_colors.dart';
import '../models/subscription_plan.dart';  // ⬅️ Make sure this exists

class SubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback? onSelect;

  const SubscriptionCard({
    super.key,
    required this.plan,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            plan.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 6),

          // Price
          Text(
            "₹${plan.price} / ${plan.duration}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.accentMint,
            ),
          ),
          const SizedBox(height: 8),

          // Duration info
          Text(
            "Perfect for ${plan.duration}",
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 16),

          // Features List
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: plan.features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.accentMint,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Corrected Button
          PrimaryButton(
            text: "Select Plan",
            onPressed: onSelect, // 🔥 Corrected from onTap → onPressed
          ),
        ],
      ),
    );
  }
}
