/// App-wide string constants.
/// Keep all user-visible strings here for easy localization later.
abstract final class AppStrings {
  // ── App meta ───────────────────────────────────────────────────────────────
  static const String appName = 'Marketplace Admin';
  static const String appTagline = 'Manage your store with confidence';

  // ── Navigation ─────────────────────────────────────────────────────────────
  static const String navDashboard = 'Dashboard';
  static const String navProducts = 'Products';
  static const String navCategories = 'Categories';
  static const String navOrders = 'Orders';
  static const String navCustomers = 'Customers';
  static const String navReviews = 'Reviews';
  static const String navBadges = 'Badges';
  static const String navBanners = 'Banners';
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

  // ── Login screen ───────────────────────────────────────────────────────────
  static const String loginHeading = 'Admin Panel';
  static const String loginWelcome = 'Welcome back! Sign in to your account.';
  static const String loginEmail = 'Email address';
  static const String loginPassword = 'Password';
  static const String loginButton = 'Sign In';
  static const String loginRememberMe = 'Remember me';
  static const String loginForgotPassword = 'Forgot password?';
  static const String loginForgotPasswordMessage =
      'Password reset will be available in the next authentication phase.';

  // ── Auth errors ────────────────────────────────────────────────────────────
  static const String authErrorInvalidCredentials =
      'Invalid email or password. Please check your credentials and try again.';
  static const String authErrorInvalidEmail = 'The email address is not valid.';
  static const String authErrorUserDisabled =
      'This account has been disabled. Please contact your administrator.';
  static const String authErrorTooManyRequests =
      'Too many failed attempts. Please wait a moment before trying again.';
  static const String authErrorNetwork =
      'Unable to connect. Please check your internet connection.';
  static const String authErrorUnexpected =
      'An unexpected error occurred. Please try again.';

  // ── Startup authorization errors (set by SplashController) ─────────────────
  static const String authStartupNotFound =
      'You are not authorized to access the Admin Panel.';
  static const String authStartupInactive = 'Your admin account is inactive.';
  static const String authStartupError =
      'Unable to verify admin access. Please try again.';
}
