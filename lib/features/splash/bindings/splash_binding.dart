import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

/// Injects dependencies required exclusively by the Splash screen.
///
/// [AuthRepository] is intentionally NOT registered here.
/// It is an application-level dependency registered once by [AppBinding]
/// and resolved via [Get.find<AuthRepository>()] wherever needed.
///
/// This binding is responsible only for [SplashController].
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}
