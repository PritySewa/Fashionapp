import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../banners/controllers/banner_controller.dart';
import '../../categories/controllers/category_controller.dart';
import '../../customers/controllers/customer_controller.dart';
import '../../orders/controllers/order_controller.dart';
import '../../orders/models/order_model.dart';
import '../../products/controllers/product_controller.dart';
import '../../reviews/controllers/review_controller.dart';
import '../../reviews/models/review_model.dart';
import '../controllers/dashboard_controller.dart';

// ── Stat card model ────────────────────────────────────────────────────────────

class _StatCard {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTapNavIndex,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int? onTapNavIndex;
}

// ── Dashboard Content ──────────────────────────────────────────────────────────

/// Clean, responsive, realtime dashboard screen.
///
/// Features:
///   - Personalised welcome section.
///   - 7 live statistic cards (Total Products, Total Categories, Total Customers,
///     Total Orders, Pending Orders, Pending Reviews, Active Banners).
///   - Recent Orders (last 5).
///   - Recent Reviews (last 5).
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthRepository>();
    final email = auth.currentUser?.email ?? 'Admin';
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? AppDimensions.space4 : AppDimensions.pagePadding;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          _WelcomeSection(email: email),
          const SizedBox(height: AppDimensions.space6),

          // Top statistic cards grid (Obx driven for realtime updates)
          const _StatCardsGrid(),
          const SizedBox(height: AppDimensions.space6),

          // Bottom row: Recent Orders (last 5) + Recent Reviews (last 5)
          LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.maxWidth >= 900;
              if (side) {
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _RecentOrdersCard()),
                    SizedBox(width: AppDimensions.space4),
                    Expanded(flex: 2, child: _RecentReviewsCard()),
                  ],
                );
              }
              return const Column(
                children: [
                  _RecentOrdersCard(),
                  SizedBox(height: AppDimensions.space4),
                  _RecentReviewsCard(),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimensions.space8),
        ],
      ),
    );
  }
}

// ── Welcome Section ────────────────────────────────────────────────────────────

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({required this.email});

  final String email;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_greeting! 👋', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppDimensions.space1),
        Text(
          'Signed in as $email',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ── Stat Cards Grid ────────────────────────────────────────────────────────────

class _StatCardsGrid extends StatelessWidget {
  const _StatCardsGrid();

  @override
  Widget build(BuildContext context) {
    final productCtrl = Get.find<ProductController>();
    final categoryCtrl = Get.find<CategoryController>();
    final customerCtrl = Get.find<CustomerController>();
    final orderCtrl = Get.find<OrderController>();
    final reviewCtrl = Get.find<ReviewController>();
    final bannerCtrl = Get.find<BannerController>();

    return Obx(() {
      final totalProducts = productCtrl.products.length;
      final totalCategories = categoryCtrl.categories.length;
      final totalCustomers = customerCtrl.customers.length;
      final totalOrders = orderCtrl.orders.length;
      final pendingOrders = orderCtrl.orders
          .where((o) => o.status == OrderStatus.pending)
          .length;
      final pendingReviews = reviewCtrl.reviews
          .where((r) => r.status == ReviewStatus.pending)
          .length;
      final activeBanners = bannerCtrl.banners
          .where((b) => b.isActive)
          .length;

      final cards = [
        _StatCard(
          label: 'Total Products',
          value: '$totalProducts',
          icon: Icons.inventory_2_rounded,
          color: AppColors.primary,
          onTapNavIndex: 1,
        ),
        _StatCard(
          label: 'Total Categories',
          value: '$totalCategories',
          icon: Icons.category_rounded,
          color: AppColors.accent,
          onTapNavIndex: 2,
        ),
        _StatCard(
          label: 'Total Customers',
          value: '$totalCustomers',
          icon: Icons.people_rounded,
          color: AppColors.accent,
          onTapNavIndex: 4,
        ),
        _StatCard(
          label: 'Total Orders',
          value: '$totalOrders',
          icon: Icons.receipt_long_rounded,
          color: AppColors.info,
          onTapNavIndex: 3,
        ),
        _StatCard(
          label: 'Pending Orders',
          value: '$pendingOrders',
          icon: Icons.pending_actions_rounded,
          color: AppColors.warning,
          onTapNavIndex: 3,
        ),
        _StatCard(
          label: 'Pending Reviews',
          value: '$pendingReviews',
          icon: Icons.rate_review_rounded,
          color: const Color(0xFFF97316), // Orange-500
          onTapNavIndex: 5,
        ),
        _StatCard(
          label: 'Active Banners',
          value: '$activeBanners',
          icon: Icons.view_carousel_rounded,
          color: AppColors.success,
          onTapNavIndex: 7,
        ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final crossAxisCount = w >= 1100
              ? 4
              : w >= 700
                  ? 3
                  : w >= 440
                      ? 2
                      : 1;
          const spacing = AppDimensions.space4;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: crossAxisCount == 1 ? 3 : 1.7,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) =>
                _StatCardTile(card: cards[index]),
          );
        },
      );
    });
  }
}

class _StatCardTile extends StatelessWidget {
  const _StatCardTile({required this.card});

  final _StatCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: card.onTapNavIndex != null
          ? () {
              final dash = Get.find<DashboardController>();
              dash.selectItem(card.onTapNavIndex!);
            }
          : null,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    card.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.space2),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: card.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Icon(
                    card.icon,
                    size: AppDimensions.iconMd,
                    color: card.color,
                  ),
                ),
              ],
            ),
            Text(
              card.value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Orders Card ─────────────────────────────────────────────────────────

class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final orderCtrl = Get.find<OrderController>();
    final dashCtrl = Get.find<DashboardController>();
    final fmt = DateFormat('dd MMM');

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Orders', style: theme.textTheme.titleMedium),
              TextButton(
                onPressed: () => dashCtrl.selectItem(3), // Navigate to Orders
                child: Text(
                  'View all',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space2),
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
          const SizedBox(height: AppDimensions.space2),
          Obx(() {
            final orders = orderCtrl.orders.take(5).toList();
            if (orders.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
                child: Center(
                  child: Text(
                    'No orders placed yet.',
                    style: theme.textTheme.bodySmall?.copyWith(color: secColor),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              itemBuilder: (context, index) {
                final o = orders[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.space3,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.customerName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '#${o.id.substring(0, 8).toUpperCase()} · ${fmt.format(o.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs. ${o.totalAmount.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space3),
                      _SmallOrderStatusBadge(status: o.status),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

// ── Recent Reviews Card ────────────────────────────────────────────────────────

class _RecentReviewsCard extends StatelessWidget {
  const _RecentReviewsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final reviewCtrl = Get.find<ReviewController>();
    final dashCtrl = Get.find<DashboardController>();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Reviews', style: theme.textTheme.titleMedium),
              TextButton(
                onPressed: () => dashCtrl.selectItem(5), // Navigate to Reviews
                child: Text(
                  'View all',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space2),
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
          const SizedBox(height: AppDimensions.space2),
          Obx(() {
            final reviews = reviewCtrl.reviews.take(5).toList();
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
                child: Center(
                  child: Text(
                    'No reviews submitted yet.',
                    style: theme.textTheme.bodySmall?.copyWith(color: secColor),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              itemBuilder: (context, index) {
                final r = reviews[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.space3,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          r.userInitials,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.userName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              r.productName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secColor,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.warning, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            r.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: child,
    );
  }
}

class _SmallOrderStatusBadge extends StatelessWidget {
  const _SmallOrderStatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = AppColors.warning;
        break;
      case OrderStatus.processing:
        color = AppColors.info;
        break;
      case OrderStatus.shipped:
        color = AppColors.accent;
        break;
      case OrderStatus.delivered:
        color = AppColors.success;
        break;
      case OrderStatus.cancelled:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
