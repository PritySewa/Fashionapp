import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'text_theme.dart';

/// Provides [lightTheme] and [darkTheme] for [GetMaterialApp].
/// Fashion theme inspired by Zara, COS & Uniqlo.
abstract final class AppTheme {
  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary, // #1A1A1A
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.primary,
      secondaryContainer: AppColors.accentLight,
      onSecondaryContainer: AppColors.primary,
      tertiary: AppColors.accent, // #C8B6A6
      onTertiary: Colors.white,
      surface: AppColors.surfaceLight, // #FFFFFF
      onSurface: AppColors.textPrimaryLight, // #1A1A1A
      surfaceContainerHighest: AppColors.surfaceVariantLight,
      onSurfaceVariant: AppColors.textSecondaryLight, // #6B7280
      outline: AppColors.borderLight, // #E5E7EB
      outlineVariant: AppColors.borderLight,
      error: AppColors.error, // #EF4444
      onError: Colors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,
      scrim: Colors.black26,
      shadow: Colors.black12,
      inverseSurface: AppColors.surfaceDark,
      onInverseSurface: AppColors.textPrimaryDark,
      inversePrimary: AppColors.accent,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: AppColors.backgroundLight, // #F8F8F8
      isDark: false,
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.textPrimaryDark,
      onPrimary: AppColors.backgroundDark,
      primaryContainer: AppColors.surfaceVariantDark,
      onPrimaryContainer: AppColors.textPrimaryDark,
      secondary: AppColors.surfaceDark,
      onSecondary: AppColors.textPrimaryDark,
      secondaryContainer: AppColors.surfaceVariantDark,
      onSecondaryContainer: AppColors.textPrimaryDark,
      tertiary: AppColors.accent,
      onTertiary: AppColors.primary,
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
      inversePrimary: AppColors.accent,
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
    final buttonRadius = BorderRadius.circular(AppDimensions.radiusMd); // 12px
    final cardRadius = BorderRadius.circular(AppDimensions.radiusMd); // 12px

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
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 20),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface, size: 20),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Primary Button (FilledButton & ElevatedButton) ─────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space5,
            vertical: AppDimensions.space3,
          ),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space5,
            vertical: AppDimensions.space3,
          ),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Secondary Button (OutlinedButton) ──────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space5,
            vertical: AppDimensions.space3,
          ),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space4,
            vertical: AppDimensions.space2,
          ),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Dialog Theme ───────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg), // 16px
          side: BorderSide(color: colorScheme.outline),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
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
        selectedColor: AppColors.accentLight,
        secondarySelectedColor: AppColors.accentLight,
        labelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space3,
          vertical: AppDimensions.space1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),

      // ── ListTile ───────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space4,
        ),
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      ),

      // ── Snackbar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        backgroundColor: AppColors.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      ),
    );
  }
}
