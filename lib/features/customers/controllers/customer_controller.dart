import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

/// GetX controller for the Customers feature.
///
/// ## Responsibilities
/// - Subscribe to [CustomerRepository.watchCustomers] and expose the realtime list.
/// - Expose [isLoading] and [errorMessage] reactive state.
/// - Delegate active toggle to the repository.
/// - Cancel subscription on dispose.
class CustomerController extends GetxController {
  // ── Dependencies ────────────────────────────────────────────────────────────

  final CustomerRepository _repository = Get.find<CustomerRepository>();

  // ── Reactive state ──────────────────────────────────────────────────────────

  /// Live list of all customers.
  final RxList<CustomerModel> customers = <CustomerModel>[].obs;

  /// True while an async write is in flight.
  final RxBool isLoading = false.obs;

  /// Error message to display on failure.
  final RxnString errorMessage = RxnString();

  // ── Stream subscription ─────────────────────────────────────────────────────

  StreamSubscription<List<CustomerModel>>? _subscription;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _subscribeToCustomers();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _subscription = null;
    super.onClose();
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  void _subscribeToCustomers() {
    _subscription = _repository.watchCustomers().listen(
      (list) {
        customers.assignAll(list);
        errorMessage.value = null;
        debugPrint(
          '[CustomerController] stream update — ${list.length} customers',
        );
      },
      onError: (Object error, StackTrace st) {
        debugPrint('[CustomerController] stream error: $error');
        errorMessage.value =
            'Failed to load customers. Please check your connection.';
      },
    );
  }

  @override
  void refresh() {
    _subscription?.cancel();
    _subscription = null;
    errorMessage.value = null;
    _subscribeToCustomers();
  }

  // ── Public actions ──────────────────────────────────────────────────────────

  /// Toggles the active state of [customer].
  Future<({bool success, String? error})> toggleActive(
    CustomerModel customer,
  ) async {
    final newValue = !customer.isActive;
    isLoading.value = true;
    try {
      await _repository.toggleCustomerActive(customer.id, isActive: newValue);
      debugPrint(
        '[CustomerController] toggleActive id=${customer.id} → $newValue',
      );
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[CustomerController] toggleActive error: $e');
      return (
        success: false,
        error: 'Failed to update customer status.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
