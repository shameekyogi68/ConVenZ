import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/booking.dart';
import '../../widgets/primary_button.dart';
import '../../services/booking_service.dart';

class VendorDetailsScreen extends StatefulWidget {
  const VendorDetailsScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Gradient AppBar ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text(
                'Matched Professional',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A5A6D), Color(0xFF2ED199)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded, size: 52, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentMint.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentMint.withOpacity(0.4)),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: const TextStyle(
                          color: AppColors.primaryTeal,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 28),

                  // Info card
                  _buildInfoCard([
                    _InfoRow(icon: Icons.badge_outlined, label: 'Vendor Name', value: widget.booking.vendorName ?? 'Mock Vendor'),
                    if (widget.booking.vendorPhone != null)
                      _InfoRow(icon: Icons.phone_android_rounded, label: 'Phone Number', value: widget.booking.vendorPhone!),
                    _InfoRow(icon: Icons.home_repair_service_outlined, label: 'Service Category', value: widget.booking.serviceName),
                    _InfoRow(icon: Icons.calendar_month_outlined, label: 'Scheduled On', value: '${widget.booking.date} at ${widget.booking.time}'),
                    _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: widget.booking.location?.address ?? 'Loading...'),
                  ]).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 32),

                  // CTA
                  PrimaryButton(
                    text: 'Proceed to OTP',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _navigateToOtp,
                  ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // Error message
                  if (_error != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  Center(
                    child: Text(
                      'Share OTP only once vendor arrives.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (widget.booking.status) {
      case 'accepted':
        return '✓ Professional Assigned';
      case 'enroute':
        return '🚶 Professional En Route';
      case 'completed':
        return '✅ Service Completed';
      default:
        return '⏳ Waiting for Professional';
    }
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryTeal.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(rows[i].icon, color: AppColors.primaryTeal, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].label,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rows[i].value,
                          style: const TextStyle(fontSize: 15, color: AppColors.darkGrey, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.shade100),
          ],
        ],
      ),
    );
  }

  void _navigateToOtp() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Navigate to OTP screen with booking data
    context.push('/bookingOtp', extra: widget.booking).then((_) {
      setState(() {
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to navigate to OTP screen. Please try again.';
      });
    });
  }
}

class _InfoRow {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}
