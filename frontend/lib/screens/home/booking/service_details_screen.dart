import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/datetime_picker.dart';
import '../../../services/booking_service.dart';
import '../../../services/location_services.dart';
import '../../../utils/blocking_helper.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String address;
  final String? selectedService;
  final double? latitude;
  final double? longitude;

  const ServiceDetailsScreen({
    super.key,
    required this.address,
    this.selectedService,
    this.latitude,
    this.longitude,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _createBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select both Date and Time'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      double? lat = widget.latitude;
      double? lng = widget.longitude;

      if (lat == null || lng == null) {
        Position? position = await LocationService.determinePosition();
        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
        }
      }

      if (lat == null || lng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to get location. Please try again.'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final formattedTime = _selectedTime!.format(context);

      final result = await BookingService.createBooking(
        selectedService: widget.selectedService ?? 'General Service',
        selectedDate: formattedDate,
        selectedTime: formattedTime,
        userLocation: {
          'latitude': lat,
          'longitude': lng,
          'address': widget.address,
        },
        jobDescription: _descriptionController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        BlockingHelper.handleBlockingResponse(context, result);

        if (result['success'] == true) {
          final String bookingId = result['data']?['_id'] ?? result['bookingId'] ?? '';
          context.go('/vendorSearch', extra: {
            'bookingId': bookingId,
            'serviceName': widget.selectedService ?? 'General Service',
          });
        } else if (result['blocked'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create booking'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Service Details', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Location card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A5A6D), Color(0xFF2ED199)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Service Location', style: TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(
                            widget.address,
                            style: const TextStyle(fontSize: 13, color: AppColors.darkGrey, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Section: When
              const Text(
                'When do you need it?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.darkGrey),
              ).animate().fade(delay: 80.ms),

              const SizedBox(height: 14),

              CustomDatePicker(
                label: 'Select Date',
                selectedDate: _selectedDate,
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ).animate().fade(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 12),

              CustomTimePicker(
                label: 'Select Time',
                selectedTime: _selectedTime,
                onTimeSelected: (time) => setState(() => _selectedTime = time),
              ).animate().fade(delay: 120.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Section: Description
              const Text(
                'Job Description',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.darkGrey),
              ).animate().fade(delay: 150.ms),

              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryTeal.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14, color: AppColors.darkGrey),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue or job in detail...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    contentPadding: const EdgeInsets.all(18),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, top: 14),
                      child: Icon(Icons.description_outlined, color: AppColors.primaryTeal, size: 20),
                    ),
                    prefixIconConstraints: const BoxConstraints(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ).animate().fade(delay: 170.ms, duration: 400.ms),

              const SizedBox(height: 36),

              _isLoading
                  ? Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: AppColors.primaryTeal, strokeWidth: 3),
                          const SizedBox(height: 12),
                          Text('Creating your booking...', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : PrimaryButton(
                      text: 'Confirm Booking',
                      onPressed: _createBooking,
                    ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
