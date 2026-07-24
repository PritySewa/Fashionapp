import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../controllers/review_controller.dart';
import '../models/review_model.dart';
import '../widgets/review_detail_dialog.dart';

class ReviewsView extends GetView<ReviewController> {
  const ReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReviewsBody(controller: controller);
  }
}

class _ReviewsBody extends StatefulWidget {
  const _ReviewsBody({required this.controller});
  final ReviewController controller;

  @override
  State<_ReviewsBody> createState() => _ReviewsBodyState();
}

class _ReviewsBodyState extends State<_ReviewsBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  ReviewStatus? _statusFilter; // null = All

  ReviewController get _ctrl => widget.controller;

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

  List<ReviewModel> _filtered(List<ReviewModel> all) {
    var list = all;
    if (_statusFilter != null) {
      list = list.where((r) => r.status == _statusFilter).toList();
    }
    if (_query.isEmpty) return list;
    return list.where((r) {
      return r.userName.toLowerCase().contains(_query) ||
          r.productName.toLowerCase().contains(_query) ||
          r.comment.toLowerCase().contains(_query);
    }).toList();
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
          // Header
          Text('Review Moderation', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            'Moderate and review customer feedback submitted from the mobile app',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.space6),

          // Search + Filter Bar
          _SearchFilterRow(
            searchCtrl: _searchCtrl,
            statusFilter: _statusFilter,
            onStatusChanged: (v) => setState(() => _statusFilter = v),
            isDesktop: isDesktop,
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
            if (_ctrl.reviews.isEmpty && !_ctrl.isLoading.value) {
              return _EmptyReviews();
            }
            if (_ctrl.reviews.isEmpty) {
              return const AppLoading();
            }

            final filtered = _filtered(_ctrl.reviews);
            if (filtered.isEmpty) {
              return _NoResults(query: _query);
            }

            if (isDesktop) {
              return _ReviewsTable(reviews: filtered, controller: _ctrl);
            }
            return _ReviewsCardList(reviews: filtered, controller: _ctrl);
          }),
        ],
      ),
    );
  }
}

// ── Search & Filter Row ───────────────────────────────────────────────────────

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow({
    required this.searchCtrl,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.isDesktop,
  });

  final TextEditingController searchCtrl;
  final ReviewStatus? statusFilter;
  final ValueChanged<ReviewStatus?> onStatusChanged;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final searchBox = SizedBox(
      height: 40,
      child: TextField(
        controller: searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search by customer or product name…',
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
    );

    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: statusFilter == null,
            onTap: () => onStatusChanged(null),
          ),
          ...ReviewStatus.values.map(
            (s) => _FilterChip(
              label: s.label,
              selected: statusFilter == s,
              color: s == ReviewStatus.approved
                  ? AppColors.success
                  : s == ReviewStatus.rejected
                      ? AppColors.error
                      : AppColors.warning,
              onTap: () => onStatusChanged(statusFilter == s ? null : s),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(flex: 2, child: searchBox),
          const SizedBox(width: AppDimensions.space4),
          Expanded(flex: 3, child: chips),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        searchBox,
        const SizedBox(height: AppDimensions.space3),
        chips,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.space2),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: selected ? c : AppColors.borderLight,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? c : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Desktop Table ─────────────────────────────────────────────────────────────

class _ReviewsTable extends StatelessWidget {
  const _ReviewsTable({required this.reviews, required this.controller});

  final List<ReviewModel> reviews;
  final ReviewController controller;

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
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space4,
              vertical: AppDimensions.space3,
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('CUSTOMER', style: headerStyle)),
                Expanded(flex: 3, child: Text('PRODUCT', style: headerStyle)),
                Expanded(flex: 2, child: Text('RATING', style: headerStyle)),
                Expanded(flex: 2, child: Text('STATUS', style: headerStyle)),
                Expanded(flex: 2, child: Text('DATE', style: headerStyle)),
                const SizedBox(width: 100), // Actions
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          // Content Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            itemBuilder: (context, index) => _ReviewTableRow(
              review: reviews[index],
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTableRow extends StatelessWidget {
  const _ReviewTableRow({required this.review, required this.controller});

  final ReviewModel review;
  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fmt = DateFormat('dd MMM yyyy');
    final r = review;

    return InkWell(
      onTap: () => ReviewDetailDialog.show(context, review: r, controller: controller),
      hoverColor: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space4,
          vertical: AppDimensions.space3,
        ),
        child: Row(
          children: [
            // Customer
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage: r.userImage != null && r.userImage!.isNotEmpty
                        ? NetworkImage(r.userImage!)
                        : null,
                    child: r.userImage == null || r.userImage!.isEmpty
                        ? Text(
                            r.userInitials,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.userName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Product
            Expanded(
              flex: 3,
              child: Text(
                r.productName,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Rating
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    r.rating.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: _ReviewStatusBadge(status: r.status),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                fmt.format(r.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            // Action Buttons
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (r.status != ReviewStatus.approved)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 18),
                      tooltip: 'Approve',
                      onPressed: () =>
                          controller.updateStatus(r.id, ReviewStatus.approved),
                    ),
                  if (r.status != ReviewStatus.rejected)
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined,
                          color: AppColors.error, size: 18),
                      tooltip: 'Reject',
                      onPressed: () =>
                          controller.updateStatus(r.id, ReviewStatus.rejected),
                    ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    tooltip: 'View details',
                    onPressed: () => ReviewDetailDialog.show(context,
                        review: r, controller: controller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Card List ──────────────────────────────────────────────────────────

class _ReviewsCardList extends StatelessWidget {
  const _ReviewsCardList({required this.reviews, required this.controller});

  final List<ReviewModel> reviews;
  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.space2),
      itemBuilder: (context, index) => _ReviewCard(
        review: reviews[index],
        controller: controller,
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.controller});

  final ReviewModel review;
  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fmt = DateFormat('dd MMM yyyy');
    final r = review;

    return GestureDetector(
      onTap: () =>
          ReviewDetailDialog.show(context, review: r, controller: controller),
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
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage: r.userImage != null && r.userImage!.isNotEmpty
                      ? NetworkImage(r.userImage!)
                      : null,
                  child: r.userImage == null || r.userImage!.isEmpty
                      ? Text(
                          r.userInitials,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.userName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _ReviewStatusBadge(status: r.status),
              ],
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              'Product: ${r.productName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: i < r.rating ? AppColors.warning : AppColors.borderDark,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  fmt.format(r.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            if (r.comment.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space2),
              Text(
                r.comment,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewStatusBadge extends StatelessWidget {
  const _ReviewStatusBadge({required this.status});

  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == ReviewStatus.approved
        ? AppColors.success
        : status == ReviewStatus.rejected
            ? AppColors.error
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
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
            Icon(Icons.rate_review_outlined, size: 48, color: secColor),
            const SizedBox(height: AppDimensions.space4),
            Text('No reviews yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppDimensions.space1),
            Text(
              'Customer submitted reviews will appear here for moderation.',
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
              'No reviews match "$query"',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
