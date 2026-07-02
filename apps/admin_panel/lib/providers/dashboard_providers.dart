import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_system/order_system.dart';
import 'package:product_catalog/product_catalog.dart';

final totalRevenueProvider = Provider<AsyncValue<double>>((ref) {
  final ordersAsync = ref.watch(ordersProvider);
  
  return ordersAsync.whenData((orders) {
    double total = 0;
    for (var order in orders) {
      if (order.status != OrderStatus.cancelled) {
        total += order.totalAmount;
      }
    }
    return total;
  });
});

final activeOrdersCountProvider = Provider<AsyncValue<int>>((ref) {
  final ordersAsync = ref.watch(ordersProvider);
  
  return ordersAsync.whenData((orders) {
    return orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.processing).length;
  });
});

final totalProductsCountProvider = Provider<AsyncValue<int>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  
  return productsAsync.whenData((products) {
    return products.length; // Can filter by active if needed
  });
});

final recentOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(ordersProvider);
  
  return ordersAsync.whenData((orders) {
    // orders are already sorted descending by createdAt in the repository
    return orders.take(5).toList();
  });
});
