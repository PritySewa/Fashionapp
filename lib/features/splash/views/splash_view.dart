import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../controllers/splash_controller.dart';

/// Placeholder Splash screen for testing the project foundation.
///
/// Displays the app logo, name, and a loading indicator.
/// Will navigate to the Login screen automatically in Phase 2.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo / Icon ─────────────────────────────────────────────────
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 32),

            // ── App name ────────────────────────────────────────────────────
            Text(
              AppStrings.splashTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),

            // ── Subtitle ────────────────────────────────────────────────────
            Text(
              AppStrings.splashSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 48),

            // ── Firebase status chip ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Firebase connected',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Loading indicator ───────────────────────────────────────────
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
