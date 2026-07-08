import 'package:get/get.dart';
import '../controllers/login_controller.dart';

/// Injects dependencies required exclusively by the Login screen.
///
/// [AuthRepository] is NOT registered here — it is an application-level
/// permanent dependency already registered by [AppBinding].
///
/// This binding is responsible only for [LoginController].
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
