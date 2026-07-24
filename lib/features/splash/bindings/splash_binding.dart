import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

/// Injects dependencies required exclusively by the Splash screen.
///
/// [AuthRepository] is intentionally NOT registered here.
/// It is an application-level dependency registered once by [AppBinding]
/// and resolved via [Get.find<AuthRepository>()] wherever needed.
///
/// Uses [Get.put] (not [Get.lazyPut]) so [SplashController] is instantiated
/// immediately when the binding runs and its [onReady] lifecycle hook is
/// guaranteed to fire after the first frame — lazyPut defers instantiation
/// until the first [Get.find] call, which on Flutter Web can occur too late
/// in the frame pipeline for [onReady] to be scheduled correctly.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(SplashController());
  }
}
