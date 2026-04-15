import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_colors.dart';
import '../../../models/booking.dart';
import '../../../services/booking_service.dart';
import '../../../widgets/primary_button.dart';

class BookingTrackingScreen extends StatefulWidget {

  const BookingTrackingScreen({
    super.key,
    required this.bookingId,
  });
  final String bookingId;

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
        if (!mounted) {
          return;
        }
        setState(() {
          _booking = booking;
          _isLoading = false;
          _errorMessage = booking == null ? "We couldn't load your booking details. Please check your connection." : null;
        });
      },
      onError: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = "It's taking longer than expected. Please try again soon.";
        });
      },
    );
  }

  Future<void> _callVendor() async {
    final String? phone = _booking?.vendorPhone;
    if (phone != null && phone.isNotEmpty) {
      final Uri uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _cancelBooking() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking? This will remove the request completely.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, keep it'),
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

    if (confirm ?? false) {
      final Map<String, dynamic> result = await BookingService.cancelBooking(widget.bookingId);
      if (!mounted) {
        return;
      }
      if (result['success'] == true) {
        setState(() => _isLoading = true);
        _startPolling(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result['message'] as String?) ?? 'Unable to cancel booking at this time.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Track Your Service',
          style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryTeal),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : _errorMessage != null
              ? _buildErrorPlaceholder()
              : _booking == null
                  ? const Center(child: Text('Booking not found'))
                  : _buildTrackingContent(),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: AppColors.primaryTeal),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: AppColors.darkGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 150,
              child: PrimaryButton(
                text: 'Retry',
                onPressed: () {
                  setState(() => _isLoading = true);
                  _startPolling();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 20),
          _buildProgressTimeline(),
          const SizedBox(height: 20),
          _buildBookingDetailsSection(),
          if (_booking!.status != 'pending' && _booking!.status != 'cancelled' && _booking!.status != 'rejected') ...[
            const SizedBox(height: 20),
            _buildVendorDetailsSection(),
          ],
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDesc;

    switch (_booking!.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.search;
        statusText = 'Locating Vendor';
        statusDesc = 'We are finding the best-rated vendor for you.';
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.verified;
        statusText = 'Vendor Assigned';
        statusDesc = 'A professional has been assigned to your request.';
      case 'in_progress':
      case 'inprogress':
        statusColor = AppColors.primaryTeal;
        statusIcon = Icons.engineering;
        statusText = 'Service in Progress';
        statusDesc = 'The work is currently being handled.';
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Success!';
        statusDesc = 'Your home service is successfully completed.';
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        statusText = 'Cancelled';
        statusDesc = 'This request has been cancelled.';
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusText = 'Service Unavailable';
        statusDesc = 'No vendors were available at this time.';
      default:
        statusColor = AppColors.darkGrey;
        statusIcon = Icons.info_outline;
        statusText = _booking!.status;
        statusDesc = 'Processing your request...';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusDesc,
                  style: const TextStyle(
                    color: AppColors.darkGrey,
                    fontSize: 13,
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
    final String status = _booking!.status.toLowerCase();
    final steps = [
      {'title': 'Booking Created', 'id': 'pending'},
      {'title': 'Vendor Assigned', 'id': 'accepted'},
      {'title': 'In Progress', 'id': 'in_progress'},
      {'title': 'Completed', 'id': 'completed'},
    ];
    
    int currentIndex = steps.indexWhere((s) => s['id'] == status);
    if (status == 'inprogress') {
      currentIndex = 2;
    }
    if (status == 'completed') {
      currentIndex = 3;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryTeal.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          for (int i = 0; i < steps.length; i++)
            _buildTimelineStep(
              steps[i]['title']!, 
              i <= currentIndex, 
              i == steps.length - 1
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, bool isDone, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? AppColors.primaryTeal : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isDone ? AppColors.primaryTeal : Colors.grey[200],
              ),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            label,
            style: TextStyle(
              color: isDone ? AppColors.primaryTeal : Colors.grey[400],
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryTeal.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.receipt_long, 'Booking ID', '#${_booking!.bookingId}'),
          const Divider(height: 30),
          _buildDetailRow(Icons.handyman, 'Service', _booking!.serviceName),
          const Divider(height: 30),
          _buildDetailRow(Icons.event, 'Date Scheduled', _booking!.date),
          const Divider(height: 30),
          _buildDetailRow(Icons.location_on, 'Service Area', (_booking!.userLocation?['address'] as String?) ?? 'N/A'),
          if (_booking!.otpStart != null) ...[
            const Divider(height: 30),
            _buildDetailRow(Icons.vpn_key, 'Service OTP', _booking!.otpStart.toString(), isSpaced: true),
          ]
        ],
      ),
    );
  }

  Widget _buildVendorDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryTeal.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primaryTeal,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assigned Vendor', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(_booking!.vendorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              if (_booking!.vendorPhone != null)
                IconButton(
                  onPressed: _callVendor,
                  icon: const Icon(Icons.phone),
                  style: IconButton.styleFrom(backgroundColor: AppColors.accentMint.withOpacity(0.2), foregroundColor: AppColors.primaryTeal),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final String status = _booking!.status.toLowerCase();
    final bool showCancel = status == 'pending' || status == 'accepted';
    final isMock = _booking!.vendorId == 9999;

    return Column(
      children: [
        if (isMock && status != 'completed') ...[
          PrimaryButton(
            text: status == 'accepted' ? 'Mock: Vendor Enroute' : 'Mock: Complete Service',
            onPressed: () async {
              final nextStatus = status == 'accepted' ? 'enroute' : 'completed';
              await BookingService.mockProgress(widget.bookingId, nextStatus);
            },
          ),
          const SizedBox(height: 12),
        ],
        if (showCancel) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _cancelBooking,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel This Booking', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerRed,
                side: BorderSide(color: AppColors.dangerRed.withOpacity(0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (status == 'completed') ...[
          PrimaryButton(
            text: 'Leave Feedback',
            onPressed: () => context.push('/feedback', extra: _booking),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              side: BorderSide(color: AppColors.primaryTeal.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('Done / Go Back', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isSpaced = false}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              value, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                letterSpacing: isSpaced ? 4 : 0
              )
            ),
          ],
        ),
      ],
    );
  }
}
