import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// A small pill badge that displays "Active" or "Inactive" depending on
/// [isActive].
///
/// Used by any admin module that exposes an active/inactive status field
/// (Categories, Badges, Products, etc.).
///
/// ```dart
/// StatusBadge(isActive: category.isActive)
/// StatusBadge(isActive: badge.isActive)
/// ```
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.textSecondaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
