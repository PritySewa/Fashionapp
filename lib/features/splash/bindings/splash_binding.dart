import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

/// Injects dependencies required by the Splash screen.
///
/// GetX will automatically call [dependencies] before the route is built,
/// and dispose [SplashController] when the route is removed from the stack.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}
