import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../controllers/review_controller.dart';
import '../models/review_model.dart';

class ReviewDetailDialog extends StatelessWidget {
  const ReviewDetailDialog({
    super.key,
    required this.review,
    required this.controller,
  });

  final ReviewModel review;
  final ReviewController controller;

  static Future<void> show(
    BuildContext context, {
    required ReviewModel review,
    required ReviewController controller,
  }) {
    if (Responsive.isDesktop(context)) {
      return showDialog(
        context: context,
        builder: (_) => ReviewDetailDialog(review: review, controller: controller),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => _ReviewDetailSheet(
          review: review,
          controller: controller,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: SizedBox(
        width: 600,
        child: _ReviewDetailContent(
          review: review,
          controller: controller,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _ReviewDetailSheet extends StatelessWidget {
  const _ReviewDetailSheet({
    required this.review,
    required this.controller,
    required this.scrollController,
  });

  final ReviewModel review;
  final ReviewController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: _ReviewDetailContent(
        review: review,
        controller: controller,
        onClose: () => Navigator.of(context).pop(),
        scrollController: scrollController,
      ),
    );
  }
}

class _ReviewDetailContent extends StatelessWidget {
  const _ReviewDetailContent({
    required this.review,
    required this.controller,
    required this.onClose,
    this.scrollController,
  });

  final ReviewModel review;
  final ReviewController controller;
  final VoidCallback onClose;
  final ScrollController? scrollController;

  Future<void> _updateStatus(ReviewStatus status) async {
    final res = await controller.updateStatus(review.id, status);
    if (res.success) {
      onClose();
      Get.snackbar(
        'Success',
        'Review status updated to ${status.label}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppDimensions.space4),
      );
    } else {
      Get.snackbar(
        'Error',
        res.error ?? 'Failed to update review.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppDimensions.space4),
      );
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review?'),
        content: const Text('Are you sure you want to permanently delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await controller.deleteReview(review.id);
      if (res.success) {
        onClose();
        Get.snackbar(
          'Deleted',
          'Review deleted successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(AppDimensions.space4),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    final r = review;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.space6,
            AppDimensions.space5,
            AppDimensions.space4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('Review Details', style: theme.textTheme.titleLarge),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        // Content Body
        Flexible(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppDimensions.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Header Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: r.userImage != null && r.userImage!.isNotEmpty
                          ? NetworkImage(r.userImage!)
                          : null,
                      child: r.userImage == null || r.userImage!.isEmpty
                          ? Text(
                              r.userInitials,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: AppDimensions.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.userName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            fmt.format(r.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ReviewStatusBadge(status: r.status),
                  ],
                ),
                const SizedBox(height: AppDimensions.space5),

                // Product Info Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.space3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.space2),
                      Expanded(
                        child: Text(
                          'Product: ${r.productName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),

                // Rating Stars Display
                Row(
                  children: [
                    Text(
                      'Rating: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        if (r.rating >= starValue) {
                          return const Icon(Icons.star_rounded,
                              color: AppColors.warning, size: 20);
                        } else if (r.rating >= starValue - 0.5) {
                          return const Icon(Icons.star_half_rounded,
                              color: AppColors.warning, size: 20);
                        }
                        return Icon(
                          Icons.star_outline_rounded,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(width: AppDimensions.space2),
                    Text(
                      '(${r.rating.toStringAsFixed(1)})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space4),

                // Comment Box
                Text(
                  'Comment:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.space1),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.space4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    r.comment.isNotEmpty ? r.comment : 'No comment provided.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),

                // Review Images Gallery
                if (r.imageUrls.isNotEmpty) ...[
                  Text(
                    'Review Images (${r.imageUrls.length}):',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space2),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: r.imageUrls.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppDimensions.space2),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                          child: SizedBox(
                            width: 90,
                            height: 90,
                            child: Image.network(
                              r.imageUrls[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        // Actions
        Padding(
          padding: const EdgeInsets.all(AppDimensions.space4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Delete Review',
                onPressed: () => _delete(context),
              ),
              const Spacer(),
              if (r.status != ReviewStatus.rejected)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () => _updateStatus(ReviewStatus.rejected),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                ),
              const SizedBox(width: AppDimensions.space2),
              if (r.status != ReviewStatus.approved)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  onPressed: () => _updateStatus(ReviewStatus.approved),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                ),
            ],
          ),
        ),
      ],
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
