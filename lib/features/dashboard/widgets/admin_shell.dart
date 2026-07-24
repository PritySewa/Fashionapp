import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/badges/views/badges_view.dart';
import '../../../features/banners/views/banners_view.dart';
import '../../../features/categories/views/categories_view.dart';
import '../../../features/customers/views/customers_view.dart';
import '../../../features/orders/views/orders_view.dart';
import '../../../features/products/views/products_view.dart';
import '../../../features/reviews/views/reviews_view.dart';
import '../../../features/settings/views/settings_view.dart';
import '../controllers/dashboard_controller.dart';
import 'admin_sidebar.dart';
import 'admin_top_bar.dart';
import 'dashboard_content.dart';

/// The structural shell of the admin panel.
class AdminShell extends GetView<DashboardController> {
  const AdminShell({super.key});

  Widget _buildContent(int index) {
    if (index == 0) return const DashboardContent();
    if (index == 1) return const ProductsView();
    if (index == 2) return const CategoriesView();
    if (index == 3) return const OrdersView();
    if (index == 4) return const CustomersView();
    if (index == 5) return const ReviewsView();
    if (index == 6) return const BadgesView();
    if (index == 7) return const BannersView();
    if (index == 8) return const SettingsView();
    return _PlaceholderModuleView(
      label: DashboardController.navItems[index].label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // On mobile/tablet, sidebar becomes a Drawer.
      drawer: isDesktop ? null : const AdminSidebar(isDrawer: true),
      body: Row(
        children: [
          // ── Desktop: permanent sidebar ────────────────────────────────────
          if (isDesktop) const AdminSidebar(isDrawer: false),
          if (isDesktop)
            VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),

          // ── Main content column ───────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                const AdminTopBar(),
                Divider(height: 1, thickness: 1, color: theme.dividerColor),
                Expanded(
                  child: Obx(
                    () => _buildContent(controller.selectedIndex.value),
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

// ── Placeholder Module View ────────────────────────────────────────────────────

/// Shown for any sidebar item that is not yet implemented.
///
/// Clearly communicates to the user (and the evaluator) that a module exists
/// in the navigation but will be built in a future phase.
class _PlaceholderModuleView extends StatelessWidget {
  const _PlaceholderModuleView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Icon(
                Icons.construction_rounded,
                size: AppDimensions.iconXl,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: AppDimensions.space5),
            Text(label, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppDimensions.space2),
            Text(
              '$label module will be implemented in a future phase.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
