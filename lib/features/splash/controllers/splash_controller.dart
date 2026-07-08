import 'package:get/get.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

/// GetX controller for the Splash screen.
///
/// Checks Firebase Authentication state synchronously in [onReady] and
/// immediately replaces the splash route — no artificial delays.
///
/// [AuthRepository] is resolved via [Get.find] because it is registered
/// at the application level by [AppBinding] before any route runs.
class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() {
    final auth = Get.find<AuthRepository>();

    if (auth.currentUser != null) {
      // User already has an active Firebase session.
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      // No active session — send to login.
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
