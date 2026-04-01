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
        title: const Text('Matched Professional'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Professional Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.2), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, size: 70, color: AppColors.primaryTeal),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Professional Assigned',
                style: TextStyle(
                  color: AppColors.primaryTeal,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              
              _buildInfoField('Vendor Name', booking.vendorName, Icons.badge_outlined),
              const SizedBox(height: 16),
              if (booking.vendorPhone != null) ...[
                _buildInfoField('Phone Number', booking.vendorPhone!, Icons.phone_android_rounded),
                const SizedBox(height: 16),
              ],
              _buildInfoField('Service Category', booking.serviceName, Icons.home_repair_service_outlined),
              const SizedBox(height: 16),
              _buildInfoField('Scheduled On', '${booking.date} at ${booking.time}', Icons.calendar_month_outlined),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/bookingOtp', extra: booking);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Proceed to OTP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share the OTP only once the vendor arrives.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
          padding: const EdgeInsets.only(left: 12.0, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[50], // Very subtle background
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryTeal, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
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
