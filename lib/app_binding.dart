import 'package:get/get.dart';
import 'features/admin/repositories/admin_repository.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/badges/repositories/badge_repository.dart';
import 'features/banners/repositories/banner_repository.dart';
import 'features/categories/repositories/category_repository.dart';
import 'features/customers/repositories/customer_repository.dart';
import 'features/orders/repositories/order_repository.dart';
import 'features/products/repositories/product_repository.dart';
import 'features/reviews/repositories/review_repository.dart';

/// Application-level GetX binding.
///
/// Registered as [GetMaterialApp.initialBinding] so it runs once before any
/// route is loaded — making its dependencies available for the full lifetime
/// of the app.
///
/// ## Why initialBinding instead of per-feature bindings?
///
/// [AuthRepository], [AdminRepository], and [CategoryRepository] are
/// cross-cutting or stream-holding concerns:
///
///   [AuthRepository]:
///     - [SplashController]  (auth-state check on startup)
///     - [LoginController]   (sign-in — Phase 2B)
///     - Logout actions      (any screen — Phase 3+)
///     - Auth guards         (route middleware — Phase 3+)
///
///   [AdminRepository]:
///     - [SplashController]  (authorization check — Phase 2C.2+)
///     - [LoginController]   (post-login authorization — Phase 2C.2+)
///     - Any screen needing admin data (Phase 3+)
///
///   [CategoryRepository]:
///     - [CategoryController] (realtime Firestore stream — Phase 3.2A+)
///     - Scoped here (not in DashboardBinding) so the stream connection
///       survives route navigation without subscription churn.
///
/// Scoping any repository to a single feature binding would cause it to be
/// disposed when that feature is popped from the navigation stack.
/// [permanent: true] + [initialBinding] ensures a single, long-lived instance
/// that survives [Get.offAllNamed()] calls.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthRepository>(AuthRepository(), permanent: true);
    Get.put<AdminRepository>(AdminRepository(), permanent: true);
    Get.put<CategoryRepository>(CategoryRepository(), permanent: true);
    Get.put<BadgeRepository>(BadgeRepository(), permanent: true);
    Get.put<ProductRepository>(ProductRepository(), permanent: true);
    Get.put<OrderRepository>(OrderRepository(), permanent: true);
    Get.put<CustomerRepository>(CustomerRepository(), permanent: true);
    Get.put<BannerRepository>(BannerRepository(), permanent: true);
    Get.put<ReviewRepository>(ReviewRepository(), permanent: true);
  }
}
