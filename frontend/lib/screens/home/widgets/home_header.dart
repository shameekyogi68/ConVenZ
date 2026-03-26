import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_colors.dart';
import '../../../../providers/user_provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    "Current Location",
                    style: TextStyle(color: AppColors.darkGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primaryTeal, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          userProvider.currentAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
