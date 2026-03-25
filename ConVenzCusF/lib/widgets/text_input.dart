import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? prefixText;
  final int maxLines;

  const TextInput({
    super.key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.keyboardType,
    this.maxLength,
    this.prefixText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // Fully curved border radius
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        decoration: InputDecoration(
          counterText: '',
          prefixIcon: Padding(
            // Align icon to top if it's a multi-line text area
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 60 : 0),
            child: Icon(icon, color: AppColors.primaryTeal),
          ),
          prefixText: prefixText,
          prefixStyle: const TextStyle(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.bold,
          ),
          labelText: labelText,
          labelStyle: const TextStyle(
            color: AppColors.darkGrey,
            fontWeight: FontWeight.w500,
          ),
          alignLabelWithHint: maxLines > 1,

          // Fully curved borders
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(color: AppColors.primaryTeal),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(color: AppColors.primaryTeal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(color: AppColors.accentMint),
          ),
        ),
      ),
    );
  }
}