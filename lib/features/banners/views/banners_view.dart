import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/status_badge.dart';
import '../controllers/banner_controller.dart';
import '../models/banner_model.dart';
import '../widgets/banner_form_dialog.dart';

class BannersView extends GetView<BannerController> {
  const BannersView({super.key});

  @override
  Widget build(BuildContext context) {
    return _BannersBody(controller: controller);
  }
}

class _BannersBody extends StatefulWidget {
  const _BannersBody({required this.controller});
  final BannerController controller;

  @override
  State<_BannersBody> createState() => _BannersBodyState();
}

class _BannersBodyState extends State<_BannersBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  BannerController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onQueryChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q != _query) setState(() => _query = q);
  }

  List<BannerModel> _filtered(List<BannerModel> all) {
    if (_query.isEmpty) return all;
    return all.where((b) {
      return b.title.toLowerCase().contains(_query) ||
          b.subtitle.toLowerCase().contains(_query) ||
          b.targetType.label.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? AppDimensions.space4 : AppDimensions.pagePadding;

    final headerText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Banners', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(
          'Manage marketing banners and promotional links',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );

    final addButton = ElevatedButton.icon(
      onPressed: () => BannerFormDialog.show(context),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Banner'),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerText,
                const SizedBox(height: AppDimensions.space4),
                SizedBox(width: double.infinity, child: addButton),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: headerText),
                addButton,
              ],
            ),
          const SizedBox(height: AppDimensions.space6),

          // Search Box
          SizedBox(
            height: 40,
            width: isDesktop ? 360 : double.infinity,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by title, subtitle or type…',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),

          // Body Content
          Obx(() {
            if (_ctrl.errorMessage.value != null) {
              return AppError(
                message: _ctrl.errorMessage.value!,
                onRetry: _ctrl.refresh,
              );
            }
            if (_ctrl.banners.isEmpty && !_ctrl.isLoading.value) {
              return _EmptyBanners();
            }
            if (_ctrl.banners.isEmpty) {
              return const AppLoading();
            }

            final list = _filtered(_ctrl.banners);
            if (list.isEmpty) {
              return _NoResults(query: _query);
            }

            if (isDesktop) {
              return _BannersTable(banners: list, controller: _ctrl);
            }
            return _BannersCardList(banners: list, controller: _ctrl);
          }),
        ],
      ),
    );
  }
}

// ── Desktop Table ─────────────────────────────────────────────────────────────

class _BannersTable extends StatelessWidget {
  const _BannersTable({required this.banners, required this.controller});

  final List<BannerModel> banners;
  final BannerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space4,
              vertical: AppDimensions.space3,
            ),
            child: Row(
              children: [
                const SizedBox(width: 80), // Image column
                Expanded(flex: 3, child: Text('TITLE', style: headerStyle)),
                Expanded(flex: 2, child: Text('TARGET TYPE', style: headerStyle)),
                Expanded(flex: 1, child: Text('ORDER', style: headerStyle)),
                Expanded(flex: 1, child: Text('STATUS', style: headerStyle)),
                const SizedBox(width: 110), // Actions
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: banners.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            itemBuilder: (context, index) => _BannerTableRow(
              banner: banners[index],
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerTableRow extends StatelessWidget {
  const _BannerTableRow({required this.banner, required this.controller});

  final BannerModel banner;
  final BannerController controller;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner?'),
        content: Text('Are you sure you want to delete "${banner.title}"?'),
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
              controller.deleteBanner(banner.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final b = banner;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space3,
      ),
      child: Row(
        children: [
          // Banner Image Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: SizedBox(
              width: 72,
              height: 40,
              child: b.imageUrl.isNotEmpty
                  ? Image.network(b.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                      child: const Icon(Icons.image, size: 20),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Title + Subtitle
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.title.isNotEmpty ? b.title : 'Untitled Banner',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (b.subtitle.isNotEmpty)
                  Text(
                    b.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Target Type
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  b.targetType == BannerTargetType.product
                      ? Icons.inventory_2_outlined
                      : b.targetType == BannerTargetType.category
                          ? Icons.category_outlined
                          : Icons.link_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  b.targetType.label,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Display Order
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Text(
                '#${b.displayOrder}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Status Badge
          Expanded(flex: 1, child: StatusBadge(isActive: b.isActive)),
          // Actions
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Switch(
                  value: b.isActive,
                  onChanged: (_) => controller.toggleActive(b),
                  activeThumbColor: AppColors.success,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () =>
                      BannerFormDialog.show(context, banner: b),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.error),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Card List ──────────────────────────────────────────────────────────

class _BannersCardList extends StatelessWidget {
  const _BannersCardList({required this.banners, required this.controller});

  final List<BannerModel> banners;
  final BannerController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: banners.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.space2),
      itemBuilder: (context, index) => _BannerCard(
        banner: banners[index],
        controller: controller,
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.controller});

  final BannerModel banner;
  final BannerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final b = banner;

    return Container(
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
        children: [
          // Banner Image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: SizedBox(
              width: double.infinity,
              height: 120,
              child: b.imageUrl.isNotEmpty
                  ? Image.network(b.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                      child: const Icon(Icons.image, size: 32),
                    ),
            ),
          ),
          const SizedBox(height: AppDimensions.space3),
          Row(
            children: [
              Expanded(
                child: Text(
                  b.title.isNotEmpty ? b.title : 'Untitled Banner',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge(isActive: b.isActive),
            ],
          ),
          if (b.subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              b.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.space3),
          Row(
            children: [
              Chip(
                label: Text('${b.targetType.label} · Order #${b.displayOrder}'),
              ),
              const Spacer(),
              Switch(
                value: b.isActive,
                onChanged: (_) => controller.toggleActive(b),
                activeThumbColor: AppColors.success,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => BannerFormDialog.show(context, banner: b),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                onPressed: () => controller.deleteBanner(b.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBanners extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_carousel_outlined, size: 48, color: secColor),
            const SizedBox(height: AppDimensions.space4),
            Text('No banners yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppDimensions.space1),
            Text(
              'Add banners to feature products, categories, or links.',
              style: theme.textTheme.bodySmall?.copyWith(color: secColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppDimensions.space3),
            Text(
              'No banners match "$query"',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
