/// All named route constants for the application.
///
/// Use these instead of raw strings to avoid typos and enable refactoring.
///
/// Example:
/// ```dart
/// Get.toNamed(AppRoutes.splash);
/// ```
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String productDetail = '/products/:id';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String customers = '/customers';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
}
