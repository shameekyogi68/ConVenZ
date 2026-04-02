import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';

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
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primaryTeal,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A5A6D), Color(0xFF2ED199)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Avatar with badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                              color: Colors.white.withOpacity(0.15),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/avatar.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 52, color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(color: Color(0xFF2ED199), shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Vendor Found!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Your booking has been accepted', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Vendor card
                  _buildCard(
                    title: 'Vendor Details',
                    rows: [
                      _RowData(Icons.person_rounded, 'Vendor Name', vendorName),
                      if (vendorPhone.isNotEmpty) _RowData(Icons.phone_rounded, 'Phone Number', vendorPhone),
                      if (vendorAddress.isNotEmpty) _RowData(Icons.location_on_rounded, 'Address', vendorAddress),
                    ],
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 16),

                  // Booking card
                  _buildCard(
                    title: 'Booking Details',
                    rows: [
                      _RowData(Icons.home_repair_service_rounded, 'Service', service),
                      if (date.isNotEmpty) _RowData(Icons.calendar_today_rounded, 'Date', date),
                      if (time.isNotEmpty) _RowData(Icons.access_time_rounded, 'Time', time),
                      _RowData(Icons.receipt_long_rounded, 'Booking ID', '#${bookingId.length > 8 ? bookingId.substring(bookingId.length - 8) : bookingId}'),
                    ],
                  ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 28),

                  if (vendorPhone.isNotEmpty)
                    PrimaryButton(
                      text: 'Call Vendor',
                      onPressed: () => _makePhoneCall(vendorPhone),
                    ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  SecondaryButton(
                    text: 'Back to Home',
                    onPressed: () => context.go('/home'),
                  ).animate().fade(delay: 250.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<_RowData> rows}) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
          ),
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(rows[i].icon, color: AppColors.primaryTeal, size: 17),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(rows[i].value, style: const TextStyle(fontSize: 14, color: AppColors.darkGrey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.shade100),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _RowData {
  final IconData icon;
  final String label;
  final String value;
  const _RowData(this.icon, this.label, this.value);
}
