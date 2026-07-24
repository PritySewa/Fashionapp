import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/order_model.dart';
import '../repositories/order_repository.dart';

/// GetX controller for the Orders feature.
///
/// ## Responsibilities
/// - Subscribe to [OrderRepository.watchOrders] and expose the realtime list.
/// - Expose [isLoading] and [errorMessage] reactive state.
/// - Delegate status/payment updates to the repository.
/// - Cancel subscription on dispose.
class OrderController extends GetxController {
  // ── Dependencies ────────────────────────────────────────────────────────────

  final OrderRepository _repository = Get.find<OrderRepository>();

  // ── Reactive state ──────────────────────────────────────────────────────────

  /// Live list of all orders.
  final RxList<OrderModel> orders = <OrderModel>[].obs;

  /// True while an async write is in flight.
  final RxBool isLoading = false.obs;

  /// Error message to display on failure.
  final RxnString errorMessage = RxnString();

  // ── Stream subscription ─────────────────────────────────────────────────────

  StreamSubscription<List<OrderModel>>? _subscription;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _subscribeToOrders();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _subscription = null;
    super.onClose();
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  void _subscribeToOrders() {
    _subscription = _repository.watchOrders().listen(
      (list) {
        orders.assignAll(list);
        errorMessage.value = null;
        debugPrint('[OrderController] stream update — ${list.length} orders');
      },
      onError: (Object error, StackTrace st) {
        debugPrint('[OrderController] stream error: $error');
        errorMessage.value =
            'Failed to load orders. Please check your connection.';
      },
    );
  }

  @override
  void refresh() {
    _subscription?.cancel();
    _subscription = null;
    errorMessage.value = null;
    _subscribeToOrders();
  }

  // ── Public actions ──────────────────────────────────────────────────────────

  /// Updates the order status and returns success / error.
  Future<({bool success, String? error})> updateOrderStatus(
    String id,
    OrderStatus status,
  ) async {
    isLoading.value = true;
    try {
      await _repository.updateOrderStatus(id, status);
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[OrderController] updateOrderStatus error: $e');
      return (success: false, error: 'Failed to update order status.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates the payment status and returns success / error.
  Future<({bool success, String? error})> updatePaymentStatus(
    String id,
    PaymentStatus status,
  ) async {
    isLoading.value = true;
    try {
      await _repository.updatePaymentStatus(id, status);
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[OrderController] updatePaymentStatus error: $e');
      return (success: false, error: 'Failed to update payment status.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Deletes the order and returns success / error.
  Future<({bool success, String? error})> deleteOrder(String id) async {
    isLoading.value = true;
    try {
      await _repository.deleteOrder(id);
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[OrderController] deleteOrder error: $e');
      return (success: false, error: 'Failed to delete order.');
    } finally {
      isLoading.value = false;
    }
  }
}
