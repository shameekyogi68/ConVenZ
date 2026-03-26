import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';

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
        const Text("Popular Near You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: popularServices.length,
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(popularServices[index]['icon'] as IconData, size: 32, color: AppColors.primaryTeal),
                    const SizedBox(height: 8),
                    Text(
                      popularServices[index]['name'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
