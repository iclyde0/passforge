import 'package:flutter/material.dart';

import '../branding.dart';

class AppColors {
  /// Brand colors — matched to PassForge logo (glossy violet).
  static const Color violet = AppBranding.logoVivid;
  static const Color violetDark = AppBranding.logoMid;
  static const Color violetDeep = AppBranding.logoDeep;
  static const Color violetLight = AppBranding.logoSoft;
  static const Color canvas = AppBranding.canvasWash;

  /// Slightly darker slate for WCAG contrast on light washes.
  static const Color grey = Color(0xFF475569);
  static const Color greyLight = Color(0xFFF1F5F9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0F172A);

  /// Feedback colors (not brand — keep semantic meaning).
  static const Color mastered = Color(0xFF16A34A);
  static const Color review = Color(0xFFEA580C);
  static const Color critical = Color(0xFFDC2626);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.violet,
        brightness: Brightness.light,
        primary: AppColors.violet,
        onPrimary: Colors.white,
        secondary: AppColors.violetLight,
        onSecondary: AppColors.violetDeep,
        surface: AppColors.white,
        onSurface: AppColors.ink,
      ),
    );
    final textTheme = base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        iconTheme: const IconThemeData(color: AppColors.violetDark),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.violet,
        circularTrackColor: AppColors.violetLight,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.violetDark,
          side: const BorderSide(color: AppColors.violet),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.violetDark),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        focusColor: AppColors.violet,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.violetLight.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.violet, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: AppColors.violetLight.withValues(alpha: 0.55),
        checkmarkColor: AppColors.violetDark,
        side: BorderSide(color: AppColors.violet.withValues(alpha: 0.35)),
        labelStyle: const TextStyle(color: AppColors.ink),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.violetDark;
            }
            return AppColors.grey;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.violetLight.withValues(alpha: 0.45);
            }
            return Colors.white;
          }),
        ),
      ),
    );
  }
}
