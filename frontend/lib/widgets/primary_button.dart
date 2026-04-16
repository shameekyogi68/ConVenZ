import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PrimaryButton extends StatelessWidget {

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.enabled = true,
    this.icon,
    this.isLoading = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !enabled || onPressed == null || isLoading;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: AppTheme.primaryButton,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(text, style: AppTheme.subtitle1.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Text(text, style: AppTheme.subtitle1.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
