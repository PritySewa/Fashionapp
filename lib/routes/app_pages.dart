import 'package:get/get.dart';
import '../features/splash/bindings/splash_binding.dart';
import '../features/splash/views/splash_view.dart';
import 'app_routes.dart';

/// Central route registry for GetX.
///
/// Add a [GetPage] entry here for every new screen.
/// Bindings are used for lazy dependency injection.
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

    // ── Login ────────────────────────────────────────────────────────────────
    // GetPage(
    //   name: AppRoutes.login,
    //   page: () => const LoginView(),
    //   binding: LoginBinding(),
    // ),

    // ── Dashboard ─────────────────────────────────────────────────────────────
    // GetPage(
    //   name: AppRoutes.dashboard,
    //   page: () => const DashboardView(),
    //   binding: DashboardBinding(),
    // ),
  ];
}
