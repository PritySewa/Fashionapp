import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../../../features/dashboard/controllers/dashboard_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SettingsView
// ─────────────────────────────────────────────────────────────────────────────

/// Settings screen mounted at sidebar index 8.
///
/// Delegates to existing [DashboardController] for theme toggle and sign-out.
/// No separate controller or repository required.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dash = Get.find<DashboardController>();
    final auth = Get.find<AuthRepository>();
    final email = auth.currentUser?.email ?? 'Admin';
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? AppDimensions.space4 : AppDimensions.pagePadding;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ────────────────────────────────────────────────────
          Text('Settings', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            'Manage your account preferences',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),

          // ── Profile section ────────────────────────────────────────────────
          _SettingsSection(
            title: 'Profile',
            children: [
              _InfoTile(
                icon: Icons.person_rounded,
                label: 'Signed in as',
                value: email,
              ),
              _InfoTile(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Role',
                value: 'Administrator',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space5),

          // ── Appearance section ─────────────────────────────────────────────
          _SettingsSection(
            title: 'Appearance',
            children: [
              _ToggleTile(
                icon: Icons.dark_mode_rounded,
                label: 'Dark Mode',
                subtitle: 'Switch between light and dark theme',
                value: isDark,
                onChanged: (_) => dash.toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space5),

          // ── Account section ────────────────────────────────────────────────
          _SettingsSection(
            title: 'Account',
            children: [
              _ActionTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                subtitle: 'Sign out of the admin panel',
                iconColor: AppColors.error,
                labelColor: AppColors.error,
                onTap: () => _confirmSignOut(context, dash),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),

          // ── Footer ────────────────────────────────────────────────────────
          Center(
            child: Text(
              'Marketplace Admin Panel  ·  v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, DashboardController dash) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        title: const Text('Sign out?'),
        content: const Text(
          'You will be returned to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              dash.logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimensions.space1,
              bottom: AppDimensions.space2,
            ),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: List.generate(children.length, (i) {
                return Column(
                  children: [
                    children[i],
                    if (i < children.length - 1)
                      Divider(
                        height: 1,
                        indent: AppDimensions.space4 + AppDimensions.iconLg + AppDimensions.space3,
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile variants
// ─────────────────────────────────────────────────────────────────────────────

/// A read-only info row.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space4,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconLg,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: AppDimensions.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A row with a toggle switch.
class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space3,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconLg,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: AppDimensions.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// A tappable action row.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveIconColor =
        iconColor ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space4,
          vertical: AppDimensions.space4,
        ),
        child: Row(
          children: [
            Icon(icon, size: AppDimensions.iconLg, color: effectiveIconColor),
            const SizedBox(width: AppDimensions.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppDimensions.iconMd,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
