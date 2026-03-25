import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import 'package:go_router/go_router.dart';

class VendorFoundScreen extends StatelessWidget {
  final String bookingId;
  final String vendorName;
  final String vendorPhone;
  final String vendorAddress;
  final String service;
  final String date;
  final String time;

  const VendorFoundScreen({
    super.key,
    required this.bookingId,
    required this.vendorName,
    required this.vendorPhone,
    required this.vendorAddress,
    required this.service,
    required this.date,
    required this.time,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // ✅ Success Icon & Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  // Avatar
                  ClipOval(
                    child: Image.asset(
                      "assets/images/avatar.png",
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 130,
                          height: 130,
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.primaryTeal,
                          ),
                        );
                      },
                    ),
                  ),

                  // ✅ Green check badge overlay
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.accentMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                "Vendor Found!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Your booking has been accepted",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 30),

              // 👤 Vendor Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryTeal.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Vendor Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    _buildInfoRow(
                      icon: Icons.person,
                      label: "Vendor Name",
                      value: vendorName,
                    ),

                    const SizedBox(height: 12),

                    // Phone
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: "Phone Number",
                      value: vendorPhone,
                    ),

                    const SizedBox(height: 12),

                    // Address
                    _buildInfoRow(
                      icon: Icons.location_on,
                      label: "Address",
                      value: vendorAddress,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 📋 Booking Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryTeal.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Booking Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Service
                    _buildInfoRow(
                      icon: Icons.home_repair_service,
                      label: "Service",
                      value: service,
                    ),

                    const SizedBox(height: 12),

                    // Date
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: "Date",
                      value: date.isNotEmpty ? date : "Not specified",
                    ),

                    const SizedBox(height: 12),

                    // Time
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: "Time",
                      value: time.isNotEmpty ? time : "Not specified",
                    ),

                    const SizedBox(height: 12),

                    // Booking ID
                    _buildInfoRow(
                      icon: Icons.receipt_long,
                      label: "Booking ID",
                      value: "#${bookingId.substring(bookingId.length > 8 ? bookingId.length - 8 : 0)}",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 📞 Call Vendor Button
              PrimaryButton(
                text: "Call Vendor",
                onPressed: vendorPhone.isNotEmpty
                    ? () => _makePhoneCall(vendorPhone)
                    : null,
              ),

              const SizedBox(height: 16),

              // 🏠 Back to Home Button
              SecondaryButton(
                text: "Back to Home",
                onPressed: () {
                  context.go('/home');
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primaryTeal,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
