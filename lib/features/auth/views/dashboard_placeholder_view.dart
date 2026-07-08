import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../routes/app_routes.dart';
import '../repositories/auth_repository.dart';

/// Minimal placeholder Dashboard screen for Phase 2A navigation verification.
///
/// Confirms that an authenticated user reaches this screen after startup.
/// The real Dashboard will replace this in Phase 3.
class DashboardPlaceholderView extends StatelessWidget {
  const DashboardPlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Get.find<AuthRepository>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              AppStrings.appName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            // Signed-in user email
            if (auth.currentUser?.email != null)
              Text(
                auth.currentUser!.email!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            const SizedBox(height: 8),

            // Phase placeholder badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.construction_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dashboard — Phase 3',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Sign-out button (verifies AuthRepository is accessible)
            OutlinedButton.icon(
              onPressed: () async {
                await auth.signOut();
                Get.offAllNamed(AppRoutes.login);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
