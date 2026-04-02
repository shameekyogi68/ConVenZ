import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PopularServicesList extends StatelessWidget {
  const PopularServicesList({super.key});

  final List<Map<String, dynamic>> popularServices = const [
    {'name': 'AC Repair', 'icon': Icons.ac_unit},
    {'name': 'Sofa Cleaning', 'icon': Icons.chair},
    {'name': 'Car Wash', 'icon': Icons.local_car_wash},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Popular Near You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            .animate().fade().slideX(begin: -0.1, end: 0, duration: 400.ms, delay: 200.ms),
        const SizedBox(height: 15),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: popularServices.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  context.push('/map', extra: {
                    'selectedService': popularServices[index]['name'],
                  });
                },
                child: Container(
                width: 110,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accentMint.withOpacity(0.2), Colors.transparent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(popularServices[index]['icon'] as IconData, size: 30, color: AppColors.primaryTeal),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      popularServices[index]['name'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              ).animate().fade(delay: (300 + (index * 100)).ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
            },
          ),
        ),
      ],
    );
  }
}
