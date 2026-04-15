import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_colors.dart';
import '../../../models/booking.dart';
import '../../../services/booking_service.dart';

class VendorSearchingScreen extends StatefulWidget {

  const VendorSearchingScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
  });
  final String bookingId;
  final String serviceName;

  @override
  State<VendorSearchingScreen> createState() => _VendorSearchingScreenState();
}

class _VendorSearchingScreenState extends State<VendorSearchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  Timer? _timeoutTimer;
  int _secondsElapsed = 0;
  Timer? _countTimer;
  StreamSubscription<Booking?>? _pollSubscription;
  bool _isCancelling = false;
  bool _isMockAssigning = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _countTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });

    // Hard timeout: if no vendor responds in 60 seconds go to not-found
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) {
        _pollSubscription?.cancel();
        context.go('/vendorNotFound', extra: {
          'bookingId': widget.bookingId,
          'serviceName': widget.serviceName,
        });
      }
    });

    // Poll backend every 5 seconds — navigate immediately on status change
    _pollSubscription = BookingService.pollBookingStatus(widget.bookingId).listen(
      (booking) {
        if (!mounted || booking == null) {
          return;
        }
        switch (booking.status) {
          case 'accepted':
            _timeoutTimer?.cancel();
            _pollSubscription?.cancel();
            context.go('/vendorFound', extra: {
              'bookingId': widget.bookingId,
              'vendorName': booking.vendorName,
              'vendorPhone': booking.vendorPhone ?? '',
              'vendorAddress': booking.location?['address'] as String? ?? '',
              'service': booking.selectedService,
              'date': booking.date,
              'time': booking.time,
            });
          case 'rejected':
          case 'cancelled':
            _timeoutTimer?.cancel();
            _pollSubscription?.cancel();
            context.go('/vendorNotFound', extra: {
              'bookingId': widget.bookingId,
              'serviceName': widget.serviceName,
            });
          default:
            break;
        }
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _timeoutTimer?.cancel();
    _countTimer?.cancel();
    _pollSubscription?.cancel();
    super.dispose();
  }

  String get _elapsedLabel {
    if (_secondsElapsed < 60) {
      return '${_secondsElapsed}s';
    }
    return '${_secondsElapsed ~/ 60}m ${_secondsElapsed % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Animated radar graphic ──
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse rings
                      for (int i = 0; i < 3; i++)
                        Transform.scale(
                          scale: 0.5 + (_pulseController.value * 0.5) + (i * 0.18),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryTeal.withValues(alpha:
                                (1 - _pulseController.value - i * 0.25).clamp(0.0, 0.12),
                              ),
                            ),
                          ),
                        ),
                      // Center avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A5A6D), Color(0xFF2ED199)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryTeal.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/avatar.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person_rounded, size: 48, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 48),

              const Text(
                'Searching for Vendor...',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

              const SizedBox(height: 8),

              Text(
                'Finding the best ${widget.serviceName} vendor near you',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 150.ms),

              const SizedBox(height: 20),

              // Booking ID + elapsed time
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ID: ${widget.bookingId.length > 6 ? widget.bookingId.substring(widget.bookingId.length - 6) : widget.bookingId}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: AppColors.accentMint),
                        const SizedBox(width: 4),
                        Text(
                          _elapsedLabel,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentMint),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fade(delay: 200.ms),

              const SizedBox(height: 32),

              // Progress bar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primaryTeal.withOpacity(0.1),
                ),
                child: LinearProgressIndicator(
                  value: (_secondsElapsed / 60.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentMint),
                ),
              ).animate().fade(delay: 250.ms),

              const SizedBox(height: 8),

              Text(
                '${(60 - _secondsElapsed).clamp(0, 60)}s remaining',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 40),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: AppColors.accentMint, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Keep the app open. You'll be notified instantly when a vendor accepts.",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 300.ms),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCancelling ? null : () {
                    if (_isCancelling) {
                      return;
                    }
                    setState(() => _isCancelling = true);
                    _timeoutTimer?.cancel();
                    _pollSubscription?.cancel();
                    BookingService.cancelBooking(widget.bookingId);
                    context.go('/home');
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Cancel Search', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: BorderSide(color: AppColors.primaryTeal.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              ).animate().fade(delay: 350.ms),

              const SizedBox(height: 12),

              // QA escape hatch: assign a mock vendor to continue testing flows
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isMockAssigning
                      ? null
                      : () async {
                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);
                          setState(() => _isMockAssigning = true);
                          final Map<String, dynamic> res =
                              await BookingService.mockAssignVendor(widget.bookingId);
                          if (!mounted) {
                            return;
                          }
                          setState(() => _isMockAssigning = false);
                          if (res['success'] == true) {
                            // Poller will pick up accepted status and navigate automatically.
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Mock vendor assigned'),
                                backgroundColor: AppColors.primaryTeal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text((res['message'] as Object?)?.toString() ?? 'Failed to assign mock vendor'),
                                backgroundColor: AppColors.dangerRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        },
                  child: _isMockAssigning
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Assign Mock Vendor (Testing)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ).animate().fade(delay: 380.ms),
            ],
          ),
        ),
      ),
    );
  }
}
