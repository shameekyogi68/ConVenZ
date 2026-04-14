import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class SecondaryButton extends StatelessWidget {

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryTeal,
          side: BorderSide(color: AppColors.primaryTeal.withOpacity(0.5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                ],
              )
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      ),
    );
  }
}
