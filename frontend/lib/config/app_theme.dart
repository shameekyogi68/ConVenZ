import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // ─────────────────────────────────────────────
  // 🎨 CONSISTENT DESIGN SYSTEM
  // ─────────────────────────────────────────────
  
  // Standard spacing values
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Standard border radius values
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius32 = 32.0;
  static const double radius100 = 100.0;

  // Consistent typography styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTeal,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTeal,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryTeal,
    height: 1.3,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGrey,
    height: 1.4,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkGrey,
    height: 1.4,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.darkGrey,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.darkGrey,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGrey,
    height: 1.3,
  );

  // Consistent container decorations
  static BoxDecoration primaryContainer = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius16),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryTeal.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration secondaryContainer = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius12),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryTeal.withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration accentContainer = BoxDecoration(
    color: AppColors.primaryTeal.withOpacity(0.08),
    borderRadius: BorderRadius.circular(radius20),
    border: Border.all(
      color: AppColors.primaryTeal.withOpacity(0.15),
    ),
  );

  // Consistent button styles
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: spacing16, horizontal: spacing32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius100),
        ),
        elevation: 0,
        textStyle: heading3.copyWith(fontSize: 16),
      );

  static ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryTeal,
        side: BorderSide(color: AppColors.primaryTeal.withOpacity(0.5), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: spacing14, horizontal: spacing32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius100),
        ),
        textStyle: heading3.copyWith(fontSize: 16),
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Outfit',
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      
      // ─────────────────────────────────────────────
      // 🎨 UNIFIED TYPOGRAPHY SYSTEM
      // ─────────────────────────────────────────────
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: heading1,
        displayMedium: heading2,
        headlineLarge: heading3,
        titleLarge: heading3,
        titleMedium: subtitle1,
        bodyLarge: body1,
        bodyMedium: body2,
        labelLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.2,
        ),
        bodySmall: caption,
      ),

      // ─────────────────────────────────────────────
      // 🎨 CONSISTENT APP BAR THEME
      // ─────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: heading3,
        iconTheme: IconThemeData(
          color: AppColors.primaryTeal,
          size: 24,
        ),
      ),

      // ─────────────────────────────────────────────
      // 🎨 UNIFIED BUTTON THEMES
      // ─────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: spacing16, horizontal: spacing32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius100),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryTeal,
          side: const BorderSide(color: AppColors.primaryTeal),
          padding: const EdgeInsets.symmetric(vertical: spacing14, horizontal: spacing32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius100),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryTeal,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─────────────────────────────────────────────
      // 🎨 CONSISTENT INPUT THEME
      // ─────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(spacing16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(
            color: AppColors.primaryTeal,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(
            color: AppColors.dangerRed,
          ),
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightGrey,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.primaryTeal,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ─────────────────────────────────────────────
      // 🎨 PREMIUM CARD THEME
      // ─────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
        ),
        margin: EdgeInsets.zero,
        shadowColor: AppColors.primaryTeal.withOpacity(0.05),
      ),

      // ─────────────────────────────────────────────
      // 🎨 CONSISTENT SNACK BAR THEME
      // ─────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryTeal,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🎨 SYSTEM UI OVERLAY STYLE
  // ─────────────────────────────────────────────
  static const SystemUiOverlayStyle systemUiOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );
}
