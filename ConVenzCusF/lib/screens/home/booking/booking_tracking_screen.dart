import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/booking.dart';
import '../../../services/booking_service.dart';
import '../../../widgets/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingTrackingScreen extends StatefulWidget {
  final String bookingId;

  const BookingTrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> {
  Booking? _booking;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<Booking?>? _pollingSubscription;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingSubscription?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingSubscription = BookingService.pollBookingStatus(widget.bookingId).listen(
      (booking) {
        if (mounted) {
          setState(() {
            _booking = booking;
            _isLoading = false;
            _errorMessage = booking == null ? "Failed to load booking" : null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Error: $error";
          });
        }
      },
    );
  }

  void _callVendor() async {
    if (_booking?.vendorPhone != null) {
      final uri = Uri.parse('tel:${_booking!.vendorPhone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await BookingService.cancelBooking(widget.bookingId);
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _startPolling(); // Refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to cancel booking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Track Booking",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _startPolling();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _booking == null
                  ? const Center(child: Text('Booking not found'))
                  : _buildTrackingContent(),
    );
  }

  Widget _buildTrackingContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(),
          
          const SizedBox(height: 24),
          
          // Progress Timeline
          _buildProgressTimeline(),
          
          const SizedBox(height: 24),
          
          // Booking Details
          _buildBookingDetails(),
          
          const SizedBox(height: 24),
          
          // Vendor Details (if assigned)
          if (_booking!.status != 'pending' && _booking!.status != 'cancelled')
            _buildVendorDetails(),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_booking!.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Searching for vendors...';
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Vendor accepted your booking!';
        break;
      case 'in_progress':
      case 'inprogress':
        statusColor = Colors.blue;
        statusIcon = Icons.build;
        statusText = 'Service in progress';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        statusText = 'Service completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Booking cancelled';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Booking rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusText = _booking!.status;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Current Status",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline() {
    final statuses = ['pending', 'accepted', 'in_progress', 'completed'];
    final currentIndex = statuses.indexOf(_booking!.status.toLowerCase());

    return Container(
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
            "Progress",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 20),
          _buildTimelineStep('Booking Created', 'pending', 0, currentIndex >= 0),
          _buildTimelineStep('Vendor Assigned', 'accepted', 1, currentIndex >= 1),
          _buildTimelineStep('Service Started', 'in_progress', 2, currentIndex >= 2),
          _buildTimelineStep('Service Completed', 'completed', 3, currentIndex >= 3, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, String status, int index, bool isCompleted, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primaryTeal : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppColors.primaryTeal : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                color: isCompleted ? AppColors.darkGrey : Colors.grey[500],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetails() {
    return Container(
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
          const SizedBox(height: 16),
          _buildDetailRow(Icons.receipt, 'Booking ID', widget.bookingId),
          const Divider(height: 24),
          _buildDetailRow(Icons.home_repair_service, 'Service', _booking!.serviceName),
          const Divider(height: 24),
          _buildDetailRow(Icons.calendar_today, 'Date', _booking!.selectedDate ?? 'N/A'),
          const Divider(height: 24),
          _buildDetailRow(Icons.access_time, 'Time', _booking!.selectedTime ?? 'N/A'),
          if (_booking!.userLocation != null) ...[
            const Divider(height: 24),
            _buildDetailRow(
              Icons.location_on,
              'Location',
              _booking!.userLocation!['address'] ?? 'N/A',
            ),
          ],
          if (_booking!.jobDescription != null && _booking!.jobDescription!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildDetailRow(Icons.description, 'Description', _booking!.jobDescription!),
          ],
        ],
      ),
    );
  }

  Widget _buildVendorDetails() {
    return Container(
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
            "Vendor Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primaryTeal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _booking!.vendorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    if (_booking!.vendorPhone != null)
                      Text(
                        _booking!.vendorPhone!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (_booking!.vendorPhone != null)
                IconButton(
                  onPressed: _callVendor,
                  icon: const Icon(Icons.phone, color: AppColors.primaryTeal),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal.withOpacity(0.1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canCancel = _booking!.status.toLowerCase() == 'pending' || 
                      _booking!.status.toLowerCase() == 'accepted';

    return Column(
      children: [
        if (canCancel)
          OutlinedButton(
            onPressed: _cancelBooking,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text(
              'Cancel Booking',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (canCancel) const SizedBox(height: 12),
        PrimaryButton(
          text: 'Back to Home',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
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
