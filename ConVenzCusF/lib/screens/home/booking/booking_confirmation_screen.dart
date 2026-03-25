import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';
import 'vendor_searching_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String bookingId;
  final String serviceName;
  final String selectedDate;
  final String selectedTime;
  final String address;
  final String? jobDescription;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
    required this.selectedDate,
    required this.selectedTime,
    required this.address,
    this.jobDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Booking Confirmed"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Success Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryTeal,
                          size: 80,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        "Booking Confirmed!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        "Your booking has been created successfully",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        "Booking ID: $bookingId",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Booking Details Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Booking Details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGrey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            _buildDetailRow(
                              Icons.home_repair_service,
                              "Service",
                              serviceName,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDetailRow(
                              Icons.calendar_today,
                              "Date",
                              selectedDate,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDetailRow(
                              Icons.access_time,
                              "Time",
                              selectedTime,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDetailRow(
                              Icons.location_on,
                              "Location",
                              address,
                            ),
                            
                            if (jobDescription != null && jobDescription!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                Icons.description,
                                "Description",
                                jobDescription!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentMint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentMint.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primaryTeal,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "We're searching for available vendors near you. You'll be notified once a vendor accepts your booking.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Track Booking Button
              PrimaryButton(
                text: "Track Booking",
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorSearchingScreen(
                        bookingId: bookingId,
                        serviceName: serviceName,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              // Back to Home Button
              TextButton(
                onPressed: () {
                  context.go('/home');
                },
                child: const Text(
                  "Back to Home",
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 20),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
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
