import 'package:get/get.dart';
import '../features/auth/views/dashboard_placeholder_view.dart';
import '../features/auth/views/login_view.dart';
import '../features/splash/bindings/splash_binding.dart';
import '../features/splash/views/splash_view.dart';
import 'app_routes.dart';

/// Central route registry for GetX.
///
/// Add a [GetPage] entry here for every new screen.
/// Bindings are only added when a screen has a controller or
/// dependencies to inject.
abstract final class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> routes = [
    // ── Splash ───────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ── Login ─────────────────────────────────────────────────────────────────
    // No binding: LoginView is a stateless placeholder in Phase 2A.
    // LoginBinding will be added in Phase 2B when LoginController exists.
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ── Dashboard (placeholder) ────────────────────────────────────────────────
    // No binding: DashboardPlaceholderView is stateless in Phase 2A.
    // DashboardBinding will be added in Phase 3 with the real Dashboard.
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPlaceholderView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
