import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

// ── Nav Item model ─────────────────────────────────────────────────────────────

/// A single sidebar navigation entry.
class NavItem {
  const NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

// ── DashboardController ────────────────────────────────────────────────────────

/// GetX controller for the admin panel shell (Dashboard screen and beyond).
///
/// Responsibilities:
///   - [selectedIndex]        — tracks the active sidebar navigation item.
///   - [isMobileSidebarOpen]  — tracks mobile/tablet Drawer open state.
///   - [selectItem]           — changes the active item and closes any Drawer.
///   - [toggleTheme]          — switches between light and dark theme.
///   - [logout]               — signs out and navigates to Login.
///
/// All Firestore data fetching (statistics, orders, etc.) belongs to Phase 3.2+.
/// This controller deliberately contains no I/O or business-domain logic.
///
/// ## Dependency resolution
///
/// [AuthRepository] is a permanent application-level dependency registered by
/// [AppBinding]. It is resolved here via [Get.find] — not re-registered.
class DashboardController extends GetxController {
  // ── Dependencies ────────────────────────────────────────────────────────────

  final AuthRepository _auth = Get.find<AuthRepository>();

  // ── Sidebar navigation items ─────────────────────────────────────────────────

  /// Ordered list of admin panel sidebar navigation items.
  ///
  /// Index 0 is always Dashboard and is the default selected item.
  /// Widgets reference this list via [DashboardController.navItems] to keep
  /// the label/icon definitions in one canonical place.
  static const List<NavItem> navItems = [
    NavItem(label: AppStrings.navDashboard, icon: Icons.dashboard_rounded),
    NavItem(label: AppStrings.navProducts, icon: Icons.inventory_2_rounded),
    NavItem(label: AppStrings.navCategories, icon: Icons.category_rounded),
    NavItem(label: AppStrings.navOrders, icon: Icons.receipt_long_rounded),
    NavItem(label: AppStrings.navCustomers, icon: Icons.people_rounded),
    NavItem(label: AppStrings.navReviews, icon: Icons.star_rounded),
    NavItem(label: AppStrings.navBadges, icon: Icons.military_tech_rounded),
    NavItem(label: AppStrings.navBanners, icon: Icons.view_carousel_rounded),
    NavItem(label: AppStrings.navSettings, icon: Icons.settings_rounded),
  ];

  // ── Reactive state ──────────────────────────────────────────────────────────

  /// Index of the currently active sidebar item. Default: 0 (Dashboard).
  final RxInt selectedIndex = 0.obs;

  /// Whether the mobile/tablet Drawer is logically open.
  ///
  /// The Scaffold manages the actual drawer animation; this mirrors that state
  /// so it can be asserted in unit tests without a widget environment.
  final RxBool isMobileSidebarOpen = false.obs;

  // ── Actions ─────────────────────────────────────────────────────────────────

  /// Selects the navigation item at [index] and closes any open Drawer.
  void selectItem(int index) {
    selectedIndex.value = index;
    isMobileSidebarOpen.value = false;
  }

  /// Toggles between light and dark theme application-wide.
  ///
  /// [Get.changeThemeMode] triggers a full rebuild of [GetMaterialApp],
  /// so all descendent widgets automatically reflect the new theme without
  /// any additional reactive wrappers.
  void toggleTheme() {
    if (Get.isDarkMode) {
      Get.changeThemeMode(ThemeMode.light);
    } else {
      Get.changeThemeMode(ThemeMode.dark);
    }
  }

  /// Signs out the current user and navigates to the Login screen.
  ///
  /// Sign-out errors are swallowed so the navigation always completes;
  /// the Firebase session becomes invalid regardless of a caught error.
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Best-effort sign-out; navigate regardless.
    }
    Get.offAllNamed(AppRoutes.login);
  }
}
