import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Returns the [TextTheme] using Inter from Google Fonts.
/// Used by both light and dark [ThemeData].
TextTheme buildTextTheme({required bool isDark}) {
  final Color onSurface = isDark
      ? AppColors.textPrimaryDark
      : AppColors.textPrimaryLight;
  final Color secondary = isDark
      ? AppColors.textSecondaryDark
      : AppColors.textSecondaryLight;

  return GoogleFonts.interTextTheme(
    TextTheme(
      // Display
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Headline
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Title
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      // Body
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: secondary,
      ),
      // Label
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: secondary,
      ),
    ),
  );
}

/// Common [InputDecorationTheme] shared between light and dark themes.
InputDecorationTheme buildInputDecorationTheme({required bool isDark}) {
  final Color border = isDark ? AppColors.borderDark : AppColors.borderLight;
  final Color fill = isDark
      ? AppColors.surfaceVariantDark
      : AppColors.surfaceVariantLight;

  return InputDecorationTheme(
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.space4,
      vertical: AppDimensions.space3,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
  );
}
