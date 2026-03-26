import 'package:flutter/material.dart';

class OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onFilled;

  const OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onFilled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F465A),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            onFilled?.call();
          }
        },
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Color(0xFF1F465A), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Color(0xFF6AACBF), width: 1.4),
          ),
        ),
      ),
    );
  }
}
