import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../booking/map_screen.dart';

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
        const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final isMoreCard = categories[index]['name'] == 'More';
            
            return InkWell(
              onTap: isMoreCard ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(
                      selectedService: categories[index]['name'],
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(categories[index]['icon'] as IconData, 
                      color: AppColors.primaryTeal, 
                      size: 30),
                    const SizedBox(height: 8),
                    Text(
                      categories[index]['name'] as String, 
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
