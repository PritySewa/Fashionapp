import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// A bold section label for admin form dialogs.
///
/// Used above every input field in Add/Edit dialogs across all admin CRUD
/// modules (Categories, Badges, Products, etc.).
///
/// ```dart
/// AdminFieldLabel('Name *')
/// AdminFieldLabel('Sort Order')
/// ```
class AdminFieldLabel extends StatelessWidget {
  const AdminFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }
}

/// A red inline error banner shown inside admin form dialogs when a
/// controller action returns a failure.
///
/// Keeps the dialog open and displays the error alongside an icon so the
/// admin knows what went wrong without losing their form input.
///
/// ```dart
/// if (localError != null) AdminInlineError(localError!)
/// ```
class AdminInlineError extends StatelessWidget {
  const AdminInlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space3,
        vertical: AppDimensions.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: AppDimensions.iconMd,
            color: AppColors.error,
          ),
          const SizedBox(width: AppDimensions.space2),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
