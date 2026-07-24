import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';

/// Confirmation dialog shown before permanently deleting a category.
///
/// Displays the category name, a cannot-be-undone warning, and
/// Cancel + Delete buttons. Only deletes after the user explicitly confirms.
///
/// Delegates the actual deletion to [CategoryController.deleteCategory].
/// Shows a success or error snackbar and pops itself when done.
class CategoryDeleteDialog extends StatefulWidget {
  const CategoryDeleteDialog({super.key, required this.category});

  final CategoryModel category;

  /// Convenience static method — show the dialog.
  static Future<void> show(BuildContext context, CategoryModel category) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CategoryDeleteDialog(category: category),
    );
  }

  @override
  State<CategoryDeleteDialog> createState() => _CategoryDeleteDialogState();
}

class _CategoryDeleteDialogState extends State<CategoryDeleteDialog> {
  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    setState(() => _isDeleting = true);

    final controller = Get.find<CategoryController>();
    final result = await controller.deleteCategory(widget.category.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    Navigator.of(context).pop();

    if (result.success) {
      Get.snackbar(
        'Category Deleted',
        '"${widget.category.name}" has been permanently deleted.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(AppDimensions.space4),
      );
    } else {
      Get.snackbar(
        'Delete Failed',
        result.error ?? 'Failed to delete category. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(AppDimensions.space4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      // ── Icon + title ─────────────────────────────────────────────────────
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          size: AppDimensions.iconLg,
          color: AppColors.error,
        ),
      ),
      title: Text(
        'Delete Category',
        style: theme.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category name highlight
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                const TextSpan(text: 'Are you sure you want to delete '),
                TextSpan(
                  text: '"${widget.category.name}"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space3),
          // Warning line
          Text(
            'This action cannot be undone.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
          onPressed: _isDeleting ? null : _confirmDelete,
          child: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}
