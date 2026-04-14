import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final List<Booking> bookings = await BookingService.getUserBookings();
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (_) {
      // ✅ No raw error — show friendly retry state
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':  return AppColors.accentMint;
      case 'accepted':   return AppColors.primaryTeal;
      case 'enroute':    return const Color(0xFF6C63FF);
      case 'cancelled':  return AppColors.dangerRed;
      case 'rejected':   return const Color(0xFFE57373);
      default:           return AppColors.premiumGold; // pending
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':  return Icons.check_circle;
      case 'accepted':   return Icons.thumb_up;
      case 'enroute':    return Icons.directions_car;
      case 'cancelled':  return Icons.cancel;
      case 'rejected':   return Icons.block;
      default:           return Icons.schedule;
    }
  }

  String _formatDate(String rawDate) {
    try {
      final DateTime dt = DateTime.parse(rawDate);
      return '${dt.day} ${_month(dt.month)} ${dt.year}';
    } catch (_) {
      return rawDate.split('T').first;
    }
  }

  String _month(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m >= 1 && m <= 12 ? months[m] : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'My Bookings',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (!_isLoading && _bookings.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_bookings.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : RefreshIndicator(
              color: AppColors.primaryTeal,
              onRefresh: _loadBookings,
              child: _bookings.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) =>
                          _buildBookingCard(_bookings[index]),
                    ),
            ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final Color statusColor = _getStatusColor(booking.status);

    return GestureDetector(
      onTap: () => context.push('/bookingTracking', extra: {'bookingId': booking.id}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top stripe with status colour
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Booking #${booking.bookingId}',
                        style: const TextStyle(
                          color: AppColors.darkGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(_getStatusIcon(booking.status), color: statusColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              booking.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 18),

                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.home_repair_service,
                            color: AppColors.primaryTeal, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.serviceName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (booking.location?['address'] != null)
                              Text(
                                booking.location!['address'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.darkGrey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.darkGrey, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(booking.date),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.darkGrey),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.access_time,
                          color: AppColors.darkGrey, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        booking.time,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.darkGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A5A6D), Color(0xFF2ED199)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit_calendar_rounded, size: 40, color: Colors.white),
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: 0.95, end: 1.02, duration: 2500.ms, curve: Curves.easeInOut),
                  
              const SizedBox(height: 32),
              
              const Text(
                'No Bookings Yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
              
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Your scheduled services will appear here. Pull down to refresh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                ),
              ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
            ],
          ),
        ),
      ],
    );
  }
}
