import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/status_badge.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';
import '../widgets/category_delete_dialog.dart';
import '../widgets/category_form_dialog.dart';

// ── Date formatter ─────────────────────────────────────────────────────────────

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = _months[dt.month - 1];
  return '$d $m ${dt.year}';
}

// ── CategoriesView ─────────────────────────────────────────────────────────────

/// Categories management screen.
///
/// ## Features
///
/// - Realtime category list via [CategoryController.categories].
/// - Client-side search by name or slug.
/// - Loading / empty / error states using existing [AppLoading] and [AppError].
/// - Desktop: responsive data table.
/// - Mobile/tablet: card list.
/// - Add, edit, delete, and toggle-active actions delegated to the controller.
///
/// This view contains NO direct Firestore calls. All mutations go through
/// [CategoryController], which returns `({bool success, String? error})`
/// records. Snackbar feedback is shown by the action dialogs after the
/// controller resolves.
class CategoriesView extends GetView<CategoryController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return _CategoriesBody(controller: controller);
  }
}

// ── Body (StatefulWidget for local search state) ───────────────────────────────

class _CategoriesBody extends StatefulWidget {
  const _CategoriesBody({required this.controller});
  final CategoryController controller;

  @override
  State<_CategoriesBody> createState() => _CategoriesBodyState();
}

class _CategoriesBodyState extends State<_CategoriesBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  CategoryController get _ctrl => widget.controller;

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

  List<CategoryModel> _filteredList(List<CategoryModel> all) {
    if (_query.isEmpty) return all;
    return all
        .where(
          (c) =>
              c.name.toLowerCase().contains(_query) || c.slug.contains(_query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? AppDimensions.space4 : AppDimensions.pagePadding;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ────────────────────────────────────────────────────
          _PageHeader(isDark: isDark, theme: theme),
          const SizedBox(height: AppDimensions.space6),

          // ── Reactive content ───────────────────────────────────────────────
          Obx(() {
            final allCategories = _ctrl.categories.toList();
            final error = _ctrl.errorMessage.value;
            final loading = _ctrl.isLoading.value;

            // Loading + no data yet
            if (loading && allCategories.isEmpty) {
              return const SizedBox(
                height: 320,
                child: AppLoading(message: 'Loading categories…'),
              );
            }

            // Stream error + no data in memory
            if (error != null && allCategories.isEmpty) {
              return SizedBox(
                height: 320,
                child: AppError(message: error, onRetry: _ctrl.refresh),
              );
            }

            // Search toolbar (always visible once data arrives)
            final filtered = _filteredList(allCategories);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Toolbar(
                  searchCtrl: _searchCtrl,
                  totalCount: allCategories.length,
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(height: AppDimensions.space5),

                // Empty: no categories at all
                if (allCategories.isEmpty)
                  _EmptyState(
                    onAdd: () =>
                        CategoryFormDialog.show(context, category: null),
                  )
                // Empty: search returned nothing
                else if (filtered.isEmpty)
                  _EmptySearch(query: _searchCtrl.text.trim())
                // Data table (desktop) or card list (mobile/tablet)
                else if (isDesktop)
                  _CategoriesTable(
                    categories: filtered,
                    isDark: isDark,
                    theme: theme,
                  )
                else
                  _CategoryCardList(
                    categories: filtered,
                    isDark: isDark,
                    theme: theme,
                  ),
              ],
            );
          }),

          const SizedBox(height: AppDimensions.space8),
        ],
      ),
    );
  }
}

// ── Page Header ────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.isDark, required this.theme});
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final isMobile = Responsive.isMobile(context);

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categories', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppDimensions.space1),
        Text(
          'Manage product categories for the marketplace.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: secondaryColor,
          ),
        ),
      ],
    );

    final addButton = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
      ),
      onPressed: () => CategoryFormDialog.show(context, category: null),
      icon: const Icon(Icons.add_rounded, size: AppDimensions.iconMd),
      label: const Text('Add Category'),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleColumn,
          const SizedBox(height: AppDimensions.space4),
          SizedBox(width: double.infinity, child: addButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: titleColumn),
        const SizedBox(width: AppDimensions.space4),
        addButton,
      ],
    );
  }
}

// ── Toolbar ────────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchCtrl,
    required this.totalCount,
    required this.isDark,
    required this.theme,
  });
  final TextEditingController searchCtrl;
  final int totalCount;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search field
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: TextFormField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or slug…',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: AppDimensions.iconMd,
                ),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: searchCtrl.clear,
                        tooltip: 'Clear search',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space4,
                  vertical: AppDimensions.space3,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.space4),
        // Count chip
        _CountChip(count: totalCount, isDark: isDark, theme: theme),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.count,
    required this.isDark,
    required this.theme,
  });
  final int count;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space3,
        vertical: AppDimensions.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        '$count ${count == 1 ? 'category' : 'categories'}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
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
                Icons.category_outlined,
                size: AppDimensions.iconXl,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: AppDimensions.space5),
            Text('No categories yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppDimensions.space2),
            Text(
              'Add your first product category to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space6),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: AppDimensions.iconXl,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            const SizedBox(height: AppDimensions.space3),
            Text(
              'No results for "$query"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ───────────────────────────────────────────────────────────────
// Provided by core/widgets/status_badge.dart — imported above.

// ── Action Buttons ─────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.category, required this.isDark});
  final CategoryModel category;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CategoryController>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle active
        Tooltip(
          message: category.isActive ? 'Deactivate' : 'Activate',
          child: IconButton(
            icon: Icon(
              category.isActive
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_rounded,
              color: category.isActive
                  ? AppColors.success
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              size: AppDimensions.iconLg,
            ),
            onPressed: () async {
              final result = await ctrl.toggleCategoryActive(category);
              if (!result.success) {
                Get.snackbar(
                  'Error',
                  result.error ?? 'Could not update status.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(AppDimensions.space4),
                );
              }
            },
          ),
        ),

        // Edit
        Tooltip(
          message: 'Edit',
          child: IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: AppDimensions.iconMd,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            onPressed: () =>
                CategoryFormDialog.show(context, category: category),
          ),
        ),

        // Delete
        Tooltip(
          message: 'Delete',
          child: IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: AppDimensions.iconMd,
              color: AppColors.error,
            ),
            onPressed: () => CategoryDeleteDialog.show(context, category),
          ),
        ),
      ],
    );
  }
}

// ── Desktop Table ──────────────────────────────────────────────────────────────

class _CategoriesTable extends StatelessWidget {
  const _CategoriesTable({
    required this.categories,
    required this.isDark,
    required this.theme,
  });
  final List<CategoryModel> categories;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final headerColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Table header ─────────────────────────────────────────────────
          Container(
            color: headerColor,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space4,
              vertical: AppDimensions.space3,
            ),
            child: Row(
              children: [
                _HeaderCell(label: 'Image', width: 60),
                _HeaderCell(label: 'Name', flex: 3),
                _HeaderCell(label: 'Slug', flex: 2),
                _HeaderCell(label: 'Description', flex: 3),
                _HeaderCell(label: 'Sort', width: 60),
                _HeaderCell(label: 'Status', width: 80),
                _HeaderCell(label: 'Updated', width: 95),
                _HeaderCell(label: 'Actions', width: 140, alignRight: true),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // ── Table rows ───────────────────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, i) => Divider(height: 1, color: borderColor),
            itemBuilder: (context, i) => _TableRow(
              category: categories[i],
              isDark: isDark,
              theme: theme,
              secondaryColor: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    this.flex,
    this.width,
    this.alignRight = false,
  });
  final String label;
  final int? flex;
  final double? width;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final child = Text(
      label,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        letterSpacing: 0.3,
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex ?? 1, child: child);
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.category,
    required this.isDark,
    required this.theme,
    required this.secondaryColor,
  });
  final CategoryModel category;
  final bool isDark;
  final ThemeData theme;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space3,
      ),
      child: Row(
        children: [
          // Image
          SizedBox(
            width: 60,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  width: 0.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: category.imageUrl.isNotEmpty
                  ? Image.network(
                      category.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.category_outlined,
                        color: secondaryColor,
                        size: 20,
                      ),
                    )
                  : Icon(
                      Icons.category_outlined,
                      color: secondaryColor,
                      size: 20,
                    ),
            ),
          ),

          // Name
          Expanded(
            flex: 3,
            child: Text(
              category.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // Slug
          Expanded(
            flex: 2,
            child: Text(
              category.slug,
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryColor,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // Description
          Expanded(
            flex: 3,
            child: Text(
              category.description.isEmpty ? '—' : category.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: category.description.isEmpty ? secondaryColor : null,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // Sort order
          SizedBox(
            width: 60,
            child: Text(
              category.sortOrder.toString(),
              style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
            ),
          ),

          // Status badge
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(isActive: category.isActive),
            ),
          ),

          // Updated date
          SizedBox(
            width: 95,
            child: Text(
              _formatDate(category.updatedAt),
              style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
            ),
          ),

          // Actions
          SizedBox(
            width: 150,
            child: Align(
              alignment: Alignment.centerRight,
              child: _ActionButtons(category: category, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile / Tablet Card List ──────────────────────────────────────────────────

class _CategoryCardList extends StatelessWidget {
  const _CategoryCardList({
    required this.categories,
    required this.isDark,
    required this.theme,
  });
  final List<CategoryModel> categories;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (_, i) => const SizedBox(height: AppDimensions.space3),
      itemBuilder: (context, i) =>
          _CategoryCard(category: categories[i], isDark: isDark, theme: theme),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isDark,
    required this.theme,
  });
  final CategoryModel category;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(AppDimensions.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Name + status
          Row(
            children: [
              // Image
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 0.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: category.imageUrl.isNotEmpty
                    ? Image.network(
                        category.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.category_outlined,
                          color: secondaryColor,
                          size: 22,
                        ),
                      )
                    : Icon(
                        Icons.category_outlined,
                        color: secondaryColor,
                        size: 22,
                      ),
              ),
              const SizedBox(width: AppDimensions.space3),
              Expanded(
                child: Text(
                  category.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.space2),
              StatusBadge(isActive: category.isActive),
            ],
          ),

          const SizedBox(height: AppDimensions.space1),

          // Slug
          Text(
            category.slug,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryColor,
              fontFamily: 'monospace',
            ),
          ),

          // Description
          if (category.description.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.space2),
            Text(
              category.description,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppDimensions.space3),

          // Meta row
          Row(
            children: [
              Icon(
                Icons.sort_rounded,
                size: AppDimensions.iconSm,
                color: secondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Order: ${category.sortOrder}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryColor,
                ),
              ),
              const SizedBox(width: AppDimensions.space4),
              Icon(
                Icons.calendar_today_outlined,
                size: AppDimensions.iconSm,
                color: secondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(category.updatedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryColor,
                ),
              ),
            ],
          ),

          Divider(height: AppDimensions.space6, color: borderColor),

          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_ActionButtons(category: category, isDark: isDark)],
          ),
        ],
      ),
    );
  }
}
