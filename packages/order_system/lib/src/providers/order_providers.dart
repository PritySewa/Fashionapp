import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/order_repository.dart';
import '../models/order.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirebaseOrderRepository();
});

final ordersProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).watchOrders();
});
