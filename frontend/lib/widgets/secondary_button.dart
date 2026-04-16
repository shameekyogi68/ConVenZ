import 'package:flutter/material.dart';
import '../config/app_theme.dart';

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
        style: AppTheme.secondaryButton,
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(text, style: AppTheme.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                ],
              )
            : Text(text, style: AppTheme.subtitle1.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
