import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/booking.dart';

class VendorDetailsScreen extends StatelessWidget {
  final Booking booking;

  const VendorDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Vendor Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo/Header Area
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.accentMint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png', // Assuming logo exists, fall back to icon
                    width: 80,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.business_center_rounded, size: 60, color: AppColors.accentMint),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your gateway to every service',
                style: TextStyle(
                  color: AppColors.accentMint,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),
              
              const CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.accentMint,
                child: Icon(Icons.person, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 40),
              
              _buildInfoField('Vendor Name', booking.vendorName, Icons.person_outline),
              const SizedBox(height: 16),
              _buildInfoField('Phone Number', booking.vendorPhone ?? 'N/A', Icons.phone_android_rounded),
              const SizedBox(height: 16),
              _buildInfoField('Business Name', 'RK Electricals', Icons.business), // Data can come from model additions later
              const SizedBox(height: 16),
              _buildInfoField('Business Address', '12th Cross, MG Road, Bengaluru', Icons.location_on_outlined),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/bookingOtp', extra: booking);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentMint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Proceed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryTeal, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
