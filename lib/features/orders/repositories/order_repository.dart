import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';

/// Repository for all Firestore operations on the [orders] collection.
///
/// Registered permanently in [AppBinding] so it survives route navigation.
class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'orders';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Realtime stream of all orders, newest first.
  Stream<List<OrderModel>> watchOrders() {
    return _ref.orderBy('createdAt', descending: true).snapshots().map((snap) {
      final orders = snap.docs.map(OrderModel.fromFirestore).toList();
      debugPrint('[OrderRepository] stream emitted ${orders.length} orders');
      return orders;
    });
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  /// One-time fetch of a single order by [id].
  Future<OrderModel?> getOrderById(String id) async {
    try {
      final doc = await _ref.doc(id).get();
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[OrderRepository] getOrderById error: $e');
      rethrow;
    }
  }

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Updates the [status] field of order [id].
  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    debugPrint('[OrderRepository] updateOrderStatus id=$id status=${status.value}');
    await _ref.doc(id).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the [paymentStatus] field of order [id].
  Future<void> updatePaymentStatus(String id, PaymentStatus status) async {
    debugPrint('[OrderRepository] updatePaymentStatus id=$id status=${status.value}');
    await _ref.doc(id).update({
      'paymentStatus': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Permanently deletes order [id].
  Future<void> deleteOrder(String id) async {
    debugPrint('[OrderRepository] deleteOrder id=$id');
    await _ref.doc(id).delete();
  }
}
