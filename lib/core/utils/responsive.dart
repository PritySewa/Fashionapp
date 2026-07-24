import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

/// Provides responsive layout helpers based on screen width breakpoints.
///
/// Usage:
/// ```dart
/// if (Responsive.isDesktop(context)) { ... }
/// ```
abstract final class Responsive {
  /// Returns `true` when width < 768 (mobile).
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppDimensions.mobileBreakpoint;

  /// Returns `true` when 768 <= width < 1200 (tablet).
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= AppDimensions.mobileBreakpoint &&
        w < AppDimensions.tabletBreakpoint;
  }

  /// Returns `true` when width >= 1200 (desktop).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppDimensions.tabletBreakpoint;

  /// Returns a value based on the current breakpoint.
  ///
  /// [desktop] is required; [tablet] and [mobile] fall back to [desktop]
  /// when not provided.
  static T value<T>(
    BuildContext context, {
    required T desktop,
    T? tablet,
    T? mobile,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile ?? tablet ?? desktop;
  }

  /// Sidebar should be shown expanded for desktop/tablet layouts.
  static bool showSidebar(BuildContext context) => isDesktop(context);
}
