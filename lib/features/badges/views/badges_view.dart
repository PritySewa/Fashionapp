import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/status_badge.dart';
import '../controllers/badge_controller.dart';
import '../models/badge_model.dart';
import '../widgets/badge_delete_dialog.dart';
import '../widgets/badge_form_dialog.dart';

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

// ── BadgesView ─────────────────────────────────────────────────────────────────

/// Badges management screen.
class BadgesView extends GetView<BadgeController> {
  const BadgesView({super.key});

  @override
  Widget build(BuildContext context) {
    return _BadgesBody(controller: controller);
  }
}

// ── Body (StatefulWidget for local search state) ───────────────────────────────

class _BadgesBody extends StatefulWidget {
  const _BadgesBody({required this.controller});
  final BadgeController controller;

  @override
  State<_BadgesBody> createState() => _BadgesBodyState();
}

class _BadgesBodyState extends State<_BadgesBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  BadgeController get _ctrl => widget.controller;

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

  List<BadgeModel> _filteredList(List<BadgeModel> all) {
    if (_query.isEmpty) return all;
    return all
        .where(
          (b) =>
              b.name.toLowerCase().contains(_query) || b.slug.contains(_query),
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
            final allBadges = _ctrl.badges.toList();
            final error = _ctrl.errorMessage.value;
            final loading = _ctrl.isLoading.value;

            // Loading + no data yet
            if (loading && allBadges.isEmpty) {
              return const SizedBox(
                height: 320,
                child: AppLoading(message: 'Loading badges…'),
              );
            }

            // Stream error + no data in memory
            if (error != null && allBadges.isEmpty) {
              return SizedBox(
                height: 320,
                child: AppError(message: error, onRetry: _ctrl.refresh),
              );
            }

            // Search toolbar (always visible once data arrives)
            final filtered = _filteredList(allBadges);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Toolbar(
                  searchCtrl: _searchCtrl,
                  totalCount: allBadges.length,
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(height: AppDimensions.space5),

                // Empty: no badges at all
                if (allBadges.isEmpty)
                  _EmptyState(
                    onAdd: () => BadgeFormDialog.show(context, badge: null),
                  )
                // Empty: search returned nothing
                else if (filtered.isEmpty)
                  _EmptySearch(query: _searchCtrl.text.trim())
                // Data table (desktop) or card list (mobile/tablet)
                else if (isDesktop)
                  _BadgesTable(badges: filtered, isDark: isDark, theme: theme)
                else
                  _BadgeCardList(
                    badges: filtered,
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
        Text('Badges', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppDimensions.space1),
        Text(
          'Manage promotional and status badges for products.',
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
      onPressed: () => BadgeFormDialog.show(context, badge: null),
      icon: const Icon(Icons.add_rounded, size: AppDimensions.iconMd),
      label: const Text('Add Badge'),
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
        '$count ${count == 1 ? 'badge' : 'badges'}',
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
                Icons.military_tech_outlined,
                size: AppDimensions.iconXl,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: AppDimensions.space5),
            Text('No badges yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppDimensions.space2),
            Text(
              'Add your first promotional badge to get started.',
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
              label: const Text('Add Badge'),
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

// ── Action Buttons ─────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.badge, required this.isDark});
  final BadgeModel badge;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BadgeController>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle active
        Tooltip(
          message: badge.isActive ? 'Deactivate' : 'Activate',
          child: IconButton(
            icon: Icon(
              badge.isActive
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_rounded,
              color: badge.isActive
                  ? AppColors.success
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              size: AppDimensions.iconLg,
            ),
            onPressed: () async {
              final result = await ctrl.toggleBadgeActive(badge);
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
            onPressed: () => BadgeFormDialog.show(context, badge: badge),
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
            onPressed: () => BadgeDeleteDialog.show(context, badge),
          ),
        ),
      ],
    );
  }
}

// ── Desktop Table ──────────────────────────────────────────────────────────────

class _BadgesTable extends StatelessWidget {
  const _BadgesTable({
    required this.badges,
    required this.isDark,
    required this.theme,
  });
  final List<BadgeModel> badges;
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
                _HeaderCell(label: 'Badge Name', flex: 3),
                _HeaderCell(label: 'Slug', flex: 2),
                _HeaderCell(label: 'Color Preview', width: 80),
                _HeaderCell(label: 'Icon Preview', flex: 2),
                _HeaderCell(label: 'Sort Order', width: 90),
                _HeaderCell(label: 'Status', width: 80),
                _HeaderCell(label: 'Updated', width: 95),
                _HeaderCell(label: 'Actions', width: 150, alignRight: true),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // ── Table rows ───────────────────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            separatorBuilder: (_, i) => Divider(height: 1, color: borderColor),
            itemBuilder: (context, i) => _TableRow(
              badge: badges[i],
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
    required this.badge,
    required this.isDark,
    required this.theme,
    required this.secondaryColor,
  });
  final BadgeModel badge;
  final bool isDark;
  final ThemeData theme;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final parsedColor = parseHexColor(badge.color);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space3,
      ),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 3,
            child: Text(
              badge.name,
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
              badge.slug,
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryColor,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // Color Preview
          SizedBox(
            width: 80,
            child: Row(
              children: [
                if (parsedColor != Colors.transparent)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: parsedColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                    ),
                  ),
                const SizedBox(width: AppDimensions.space2),
                Expanded(
                  child: Text(
                    badge.color.isEmpty ? '—' : badge.color,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          // Icon Preview
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  getBadgeIconData(badge.icon),
                  size: 16,
                  color: parsedColor != Colors.transparent
                      ? parsedColor
                      : secondaryColor,
                ),
                const SizedBox(width: AppDimensions.space2),
                Expanded(
                  child: Text(
                    badge.icon.isEmpty ? '—' : badge.icon,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          // Sort order
          SizedBox(
            width: 90,
            child: Text(
              badge.sortOrder.toString(),
              style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
            ),
          ),

          // Status badge
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(isActive: badge.isActive),
            ),
          ),

          // Updated date
          SizedBox(
            width: 95,
            child: Text(
              _formatDate(badge.updatedAt),
              style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
            ),
          ),

          // Actions
          SizedBox(
            width: 150,
            child: Align(
              alignment: Alignment.centerRight,
              child: _ActionButtons(badge: badge, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile / Tablet Card List ──────────────────────────────────────────────────

class _BadgeCardList extends StatelessWidget {
  const _BadgeCardList({
    required this.badges,
    required this.isDark,
    required this.theme,
  });
  final List<BadgeModel> badges;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      separatorBuilder: (_, i) => const SizedBox(height: AppDimensions.space3),
      itemBuilder: (context, i) =>
          _BadgeCard(badge: badges[i], isDark: isDark, theme: theme),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.isDark,
    required this.theme,
  });
  final BadgeModel badge;
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
    final parsedColor = parseHexColor(badge.color);

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
          // Name + status
          Row(
            children: [
              Expanded(
                child: Text(
                  badge.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.space2),
              StatusBadge(isActive: badge.isActive),
            ],
          ),

          const SizedBox(height: AppDimensions.space1),

          // Slug
          Text(
            badge.slug,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryColor,
              fontFamily: 'monospace',
            ),
          ),

          const SizedBox(height: AppDimensions.space3),

          // Details row (Color and Icon previews)
          Row(
            children: [
              // Color Circle
              if (parsedColor != Colors.transparent) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: parsedColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(badge.color, style: theme.textTheme.bodySmall),
              ] else ...[
                Text(
                  'No Color',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryColor,
                  ),
                ),
              ],
              const SizedBox(width: AppDimensions.space4),
              // Icon
              Icon(
                getBadgeIconData(badge.icon),
                size: 16,
                color: parsedColor != Colors.transparent
                    ? parsedColor
                    : secondaryColor,
              ),
              const SizedBox(width: 6),
              Text(badge.icon, style: theme.textTheme.bodySmall),
            ],
          ),

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
                'Order: ${badge.sortOrder}',
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
                _formatDate(badge.updatedAt),
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
            children: [_ActionButtons(badge: badge, isDark: isDark)],
          ),
        ],
      ),
    );
  }
}
