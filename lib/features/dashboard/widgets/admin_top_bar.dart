import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../controllers/dashboard_controller.dart';

/// Horizontal top bar for the admin panel shell.
///
/// Contents:
///   - Hamburger menu button (mobile/tablet only) — opens the Drawer.
///   - Current page title derived from [DashboardController.selectedIndex].
///   - Theme toggle button (sun/moon icon).
///   - Admin avatar (circle with first letter of email) + email on desktop.
///
/// The bar height is fixed to [AppDimensions.appBarHeight] (64 px).
/// No notifications, search, or complex menus in Phase 3.1.
class AdminTopBar extends GetView<DashboardController> {
  const AdminTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);

    final auth = Get.find<AuthRepository>();
    final email = auth.currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'A';

    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      height: AppDimensions.appBarHeight,
      color: theme.colorScheme.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppDimensions.space6 : AppDimensions.space3,
      ),
      child: Row(
        children: [
          // ── Menu button (mobile/tablet only) ───────────────────────────────
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Open navigation menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: AppDimensions.space1),
          ],

          // ── Page title ─────────────────────────────────────────────────────
          Obx(
            () => Text(
              DashboardController
                  .navItems[controller.selectedIndex.value]
                  .label,
              style: theme.textTheme.titleMedium,
            ),
          ),

          const Spacer(),

          // ── Theme toggle ───────────────────────────────────────────────────
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: controller.toggleTheme,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),

          const SizedBox(width: AppDimensions.space2),

          // ── Admin profile area ─────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Email label: desktop only (too wide for mobile)
              if (isDesktop && email.isNotEmpty) ...[
                const SizedBox(width: AppDimensions.space2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
