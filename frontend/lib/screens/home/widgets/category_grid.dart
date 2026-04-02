import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Cleaning', 'icon': Icons.cleaning_services},
    {'name': 'Plumbing', 'icon': Icons.plumbing},
    {'name': 'Electrician', 'icon': Icons.electrical_services},
    {'name': 'Painting', 'icon': Icons.format_paint},
    {'name': 'Moving', 'icon': Icons.local_shipping},
    {'name': 'More', 'icon': Icons.grid_view},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            .animate().fade().slideX(begin: -0.1, end: 0, duration: 400.ms),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final isMoreCard = categories[index]['name'] == 'More';
            
            return InkWell(
              onTap: isMoreCard ? null : () {
                context.push(
                  '/map',
                  extra: {'selectedService': categories[index]['name']},
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(isMoreCard ? 0.05 : 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(categories[index]['icon'] as IconData, 
                        color: isMoreCard ? Colors.grey.shade600 : AppColors.primaryTeal, 
                        size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      categories[index]['name'] as String, 
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMoreCard ? Colors.grey.shade700 : Colors.black87,
                      ),
                    )
                  ],
                ),
              ),
            ).animate().fade(delay: (index * 50).ms).scale(delay: (index * 50).ms, duration: 300.ms, curve: Curves.easeOutBack);
          },
        ),
      ],
    );
  }
}
