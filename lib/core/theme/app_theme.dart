import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'text_theme.dart';

/// Provides [lightTheme] and [darkTheme] for [GetMaterialApp].
abstract final class AppTheme {
  // ── Light ──────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFE0F2FE),
      onSecondaryContainer: AppColors.secondaryDark,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.surfaceVariantLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderLight,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,
      scrim: Colors.black26,
      shadow: Colors.black12,
      inverseSurface: AppColors.surfaceDark,
      onInverseSurface: AppColors.textPrimaryDark,
      inversePrimary: AppColors.primaryLight,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: AppColors.backgroundLight,
      isDark: false,
    );
  }

  // ── Dark ───────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: const Color(0xFFE0F2FE),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderDark,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: AppColors.errorLight,
      scrim: Colors.black54,
      shadow: Colors.black38,
      inverseSurface: AppColors.surfaceLight,
      onInverseSurface: AppColors.textPrimaryLight,
      inversePrimary: AppColors.primaryLight,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: AppColors.backgroundDark,
      isDark: true,
    );
  }

  // ── Shared builder ─────────────────────────────────────────────────────────
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required bool isDark,
  }) {
    final textTheme = buildTextTheme(isDark: isDark);
    final radius = BorderRadius.circular(AppDimensions.radiusSm);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      // ── ElevatedButton ─────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space6,
            vertical: AppDimensions.space3,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      // ── OutlinedButton ─────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space6,
            vertical: AppDimensions.space3,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      // ── TextButton ─────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space4,
            vertical: AppDimensions.space2,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      // ── Input ──────────────────────────────────────────────────────────────
      inputDecorationTheme: buildInputDecorationTheme(isDark: isDark),
      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      // ── Chip ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space3,
          vertical: AppDimensions.space1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      ),
      // ── ListTile ───────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space4,
        ),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      // ── Snackbar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );
  }
}
