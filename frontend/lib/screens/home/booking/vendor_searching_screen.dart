import 'package:flutter/material.dart';
import 'dart:async';
import '../../../config/app_colors.dart';
import 'vendor_found_screen.dart';

class VendorSearchingScreen extends StatefulWidget {
  final String bookingId;
  final String serviceName;
  
  const VendorSearchingScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
  });

  @override
  State<VendorSearchingScreen> createState() => _VendorSearchingScreenState();
}

class _VendorSearchingScreenState extends State<VendorSearchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for pulsing effect
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // Auto-navigate to Vendor Found screen after 3 seconds
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VendorFoundScreen(
              bookingId: widget.bookingId,
              vendorName: "Sarah Peterson",
              vendorPhone: "+1 234 567 8900",
              vendorAddress: "123 Professional Lane",
              service: widget.serviceName,
              date: "Today",
              time: "In 30 mins",
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated searching icon
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_animationController.value * 0.1),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search,
                          size: 60,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Circular progress indicator
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: AppColors.primaryTeal,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Title
                const Text(
                  'Searching for Vendor',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  'Finding the best ${widget.serviceName} vendor near you...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Booking ID
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Booking ID: #${widget.bookingId.substring(widget.bookingId.length > 8 ? widget.bookingId.length - 8 : 0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Info text
                Text(
                  'This may take a few moments...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
