import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/datetime_picker.dart';
import '../../../widgets/text_input.dart';
import '../../../services/booking_service.dart';
import '../../../services/location_services.dart';
import '../../../utils/blocking_helper.dart';
import 'package:go_router/go_router.dart';

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

  void _createBooking() async {
    // Validation
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both Date and Time"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current location if not provided
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
            const SnackBar(
              content: Text("Unable to get location. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Format date and time
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final formattedTime = _selectedTime!.format(context);

      // Create booking
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
        
        // Check if user is blocked
        BlockingHelper.handleBlockingResponse(context, result);

        if (result['success'] == true) {
          // Get booking ID from response
          String bookingId = result['data']?['_id'] ?? result['bookingId'] ?? '';

          // Navigate directly to vendor search screen using GoRouter
          context.go(
            '/vendorSearch',
            extra: {
              'bookingId': bookingId,
              'serviceName': widget.selectedService ?? 'General Service',
            },
          );
        } else if (result['blocked'] != true) {
          // Only show error if not blocked (blocked case handled above)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create booking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Service Details"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.03),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primaryTeal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Service Location",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              const Text(
                "When do you need the service?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              CustomDatePicker(
                label: "Select Date",
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 16),

              CustomTimePicker(
                label: "Select Time",
                selectedTime: _selectedTime,
                onTimeSelected: (time) {
                  setState(() => _selectedTime = time);
                },
              ),

              SizedBox(height: screenHeight * 0.04),

              const Text(
                "Job Description:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextInput(
                controller: _descriptionController,
                labelText: "Describe the issue...",
                icon: Icons.description_outlined,
                maxLines: 4,
              ),

              SizedBox(height: screenHeight * 0.05),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: "Create Booking",
                      onPressed: _createBooking,
                    ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
