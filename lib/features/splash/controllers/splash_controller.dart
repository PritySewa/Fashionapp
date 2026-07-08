import 'package:get/get.dart';

/// GetX controller for the Splash screen.
///
/// Responsibilities (this phase):
///   - Lifecycle management for the splash screen.
///   - Navigation to login once ready (stubbed for now).
///
/// Future phases:
///   - Check auth state via AuthRepository.
///   - Route to dashboard if already logged in, otherwise to login.
class SplashController extends GetxController {
  // Phase 2 will override onInit() to check authentication state.
  // Phase 2 will override onReady() to navigate after the check.
  //
  // Example:
  //
  // @override
  // void onReady() {
  //   super.onReady();
  //   await Future.delayed(const Duration(seconds: 2));
  //   Get.offAllNamed(AppRoutes.login);
  // }
}
