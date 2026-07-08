/// App-wide string constants.
/// Keep all user-visible strings here for easy localization later.
abstract final class AppStrings {
  // ── App meta ───────────────────────────────────────────────────────────────
  static const String appName = 'Marketplace Admin';
  static const String appTagline = 'Manage your store with confidence';

  // ── Navigation ─────────────────────────────────────────────────────────────
  static const String navDashboard = 'Dashboard';
  static const String navProducts = 'Products';
  static const String navOrders = 'Orders';
  static const String navCustomers = 'Customers';
  static const String navAnalytics = 'Analytics';
  static const String navSettings = 'Settings';

  // ── Splash / Loading ───────────────────────────────────────────────────────
  static const String splashTitle = 'Marketplace Admin';
  static const String splashSubtitle = 'Setting up your workspace…';
  static const String loading = 'Loading…';

  // ── Common actions ─────────────────────────────────────────────────────────
  static const String actionSave = 'Save';
  static const String actionCancel = 'Cancel';
  static const String actionDelete = 'Delete';
  static const String actionEdit = 'Edit';
  static const String actionAdd = 'Add';
  static const String actionConfirm = 'Confirm';
  static const String actionRetry = 'Retry';

  // ── Error / Empty states ───────────────────────────────────────────────────
  static const String errorGeneral = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection.';
  static const String emptyState = 'Nothing here yet.';
}
