import 'package:get/get.dart';
import '../features/auth/repositories/auth_repository.dart';

/// Application-level GetX binding.
///
/// Registered as [GetMaterialApp.initialBinding] so it runs once before any
/// route is loaded — making its dependencies available for the full lifetime
/// of the app.
///
/// Why initialBinding instead of SplashBinding?
///   [AuthRepository] is a cross-cutting concern used by:
///     - [SplashController]  (auth-state check on startup)
///     - [LoginController]   (sign-in — Phase 2B)
///     - Logout actions      (any screen — Phase 3+)
///     - Auth guards         (route middleware — Phase 3+)
///   Scoping it to a single feature binding would cause it to be disposed
///   when that feature is popped from the navigation stack.
///   [permanent: true] + [initialBinding] ensures a single, long-lived
///   instance that survives [Get.offAllNamed()] calls.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthRepository>(AuthRepository(), permanent: true);
  }
}
