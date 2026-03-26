import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (enabled && onPressed != null) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF02BEAF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
