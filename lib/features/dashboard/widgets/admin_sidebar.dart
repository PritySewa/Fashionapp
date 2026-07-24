import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../controllers/dashboard_controller.dart';

/// Admin panel sidebar navigation widget.
///
/// Features a minimal high-fashion aesthetic with a clean background,
/// accent-colored indicator bar (#C8B6A6) for active items, and subtle hover effects.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, required this.isDrawer});

  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarBg = isDark ? AppColors.sidebarDark : AppColors.sidebarLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SizedBox(
      width: AppDimensions.sidebarWidth,
      child: Material(
        color: sidebarBg,
        child: Column(
          children: [
            // ── Branding area ──────────────────────────────────────────────
            _SidebarBrand(isDark: isDark),

            Divider(color: borderColor, height: 1, thickness: 1),

            // ── Navigation items ───────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space2,
                  vertical: AppDimensions.space3,
                ),
                itemCount: DashboardController.navItems.length,
                itemBuilder: (context, index) =>
                    _NavTile(index: index, isDrawer: isDrawer, isDark: isDark),
              ),
            ),

            // ── Logout ────────────────────────────────────────────────────
            Divider(color: borderColor, height: 1, thickness: 1),
            _LogoutTile(isDrawer: isDrawer, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ── Brand Header ───────────────────────────────────────────────────────────────

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space5,
      ),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: isDark ? AppColors.primary : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.space3),
          // Brand text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marketplace',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Admin Panel',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nav Tile ──────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.index,
    required this.isDrawer,
    required this.isDark,
  });

  final int index;
  final bool isDrawer;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final item = DashboardController.navItems[index];
    final controller = Get.find<DashboardController>();

    final activeBg = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.accentLight; // #F5F0EB
    final activeTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight; // #1A1A1A
    final unselectedTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final hoverColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.surfaceVariantLight;

    return Obx(() {
      final isSelected = controller.selectedIndex.value == index;

      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.space1),
        child: Material(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            hoverColor: hoverColor,
            splashColor: AppColors.accent.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            onTap: () {
              controller.selectItem(index);
              if (isDrawer) Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space3,
                vertical: AppDimensions.space3,
              ),
              child: Row(
                children: [
                  // Icon
                  Icon(
                    item.icon,
                    size: AppDimensions.iconMd,
                    color: isSelected
                        ? (isDark ? AppColors.accent : AppColors.primary)
                        : unselectedTextColor,
                  ),
                  const SizedBox(width: AppDimensions.space3),
                  // Label
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? activeTextColor
                            : unselectedTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Accent indicator bar (#C8B6A6)
                  if (isSelected)
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.accent, // Warm taupe accent indicator
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ── Logout Tile ───────────────────────────────────────────────────────────────

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.isDrawer, required this.isDark});

  final bool isDrawer;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space2,
        vertical: AppDimensions.space3,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          hoverColor: AppColors.error.withValues(alpha: 0.08),
          splashColor: AppColors.error.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          onTap: controller.logout,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space3,
              vertical: AppDimensions.space3,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: AppDimensions.iconMd,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppDimensions.space3),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
