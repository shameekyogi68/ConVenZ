import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_colors.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  // First 5 shown in grid; "More" reveals the remaining 3
  static const List<Map<String, dynamic>> _primary = [
    {'name': 'Cleaning',    'icon': Icons.cleaning_services},
    {'name': 'Plumbing',    'icon': Icons.plumbing},
    {'name': 'Electrician', 'icon': Icons.electrical_services},
    {'name': 'Painting',    'icon': Icons.format_paint},
    {'name': 'Moving',      'icon': Icons.local_shipping},
  ];

  static const List<Map<String, dynamic>> _extra = [
    {'name': 'AC Repair',     'icon': Icons.ac_unit},
    {'name': 'Sofa Cleaning', 'icon': Icons.chair},
    {'name': 'Car Wash',      'icon': Icons.local_car_wash},
  ];

  void _navigateToService(BuildContext context, String name) {
    context.push('/map', extra: {'selectedService': name});
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'More Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _extra.map((service) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/map', extra: {'selectedService': service['name'] as String});
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(service['icon'] as IconData,
                            color: AppColors.primaryTeal, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service['name'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build 6-item list: 5 primary + 1 "More" card
    final List<Map<String, dynamic>> items = [
      ..._primary,
      {'name': 'More', 'icon': Icons.grid_view, 'isMore': true},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            GestureDetector(
              onTap: () => _showMoreSheet(context),
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ).animate().fade().slideX(begin: -0.1, end: 0, duration: 400.ms),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final Map<String, dynamic> item = items[index];
            final isMore = item['isMore'] == true;

            return InkWell(
              onTap: () => isMore
                  ? _showMoreSheet(context)
                  : _navigateToService(context, item['name'] as String),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primaryTeal.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal
                            .withValues(alpha: isMore ? 0.05 : 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isMore
                            ? Colors.grey.shade600
                            : AppColors.primaryTeal,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMore
                            ? Colors.grey.shade700
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate()
                .fade(delay: (index * 50).ms)
                .scale(
                    delay: (index * 50).ms,
                    duration: 300.ms,
                    curve: Curves.easeOutBack);
          },
        ),
      ],
    );
  }
}
