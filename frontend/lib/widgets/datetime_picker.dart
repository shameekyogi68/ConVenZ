import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl package for formatting
import '../config/app_colors.dart';

class CustomDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CustomDatePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primaryTeal, // Header background color
                  onPrimary: Colors.white, // Header text color
                  onSurface: AppColors.darkGrey, // Body text color
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal, // Button text color
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primaryTeal, size: 20),
            const SizedBox(width: 12),
            Text(
              selectedDate == null
                  ? label
                  : DateFormat('dd MMM yyyy').format(selectedDate!),
              style: TextStyle(
                color: selectedDate == null ? Colors.grey : Colors.black87,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class CustomTimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay> onTimeSelected;

  const CustomTimePicker({
    super.key,
    required this.label,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primaryTeal,
                  onPrimary: Colors.white,
                  onSurface: AppColors.darkGrey,
                ),
                timePickerTheme: TimePickerThemeData(
                  dialHandColor: AppColors.accentMint,
                  dialBackgroundColor: AppColors.background,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.primaryTeal, size: 20),
            const SizedBox(width: 12),
            Text(
              selectedTime == null
                  ? label
                  : selectedTime!.format(context),
              style: TextStyle(
                color: selectedTime == null ? Colors.grey : Colors.black87,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}