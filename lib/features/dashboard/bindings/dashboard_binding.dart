import 'package:get/get.dart';
import '../../badges/controllers/badge_controller.dart';
import '../../banners/controllers/banner_controller.dart';
import '../../categories/controllers/category_controller.dart';
import '../../customers/controllers/customer_controller.dart';
import '../../orders/controllers/order_controller.dart';
import '../../products/controllers/product_controller.dart';
import '../../reviews/controllers/review_controller.dart';
import '../controllers/dashboard_controller.dart';

/// Injects [DashboardController] and feature controllers for the /dashboard route.
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<CategoryController>(() => CategoryController());
    Get.lazyPut<BadgeController>(() => BadgeController());
    Get.lazyPut<ProductController>(() => ProductController());
    Get.lazyPut<OrderController>(() => OrderController());
    Get.lazyPut<CustomerController>(() => CustomerController());
    Get.lazyPut<BannerController>(() => BannerController());
    Get.lazyPut<ReviewController>(() => ReviewController());
  }
}
