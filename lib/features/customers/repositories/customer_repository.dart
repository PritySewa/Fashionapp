import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/customer_model.dart';

/// Repository for all Firestore operations on the [users] collection.
///
/// Registered permanently in [AppBinding] so it survives route navigation.
class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'users';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Realtime stream of all customers, newest first.
  Stream<List<CustomerModel>> watchCustomers() {
    return _ref.orderBy('createdAt', descending: true).snapshots().map((snap) {
      final customers = snap.docs.map(CustomerModel.fromFirestore).toList();
      debugPrint(
        '[CustomerRepository] stream emitted ${customers.length} customers',
      );
      return customers;
    });
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  /// One-time fetch of a single customer by [id].
  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      final doc = await _ref.doc(id).get();
      if (!doc.exists) return null;
      return CustomerModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[CustomerRepository] getCustomerById error: $e');
      rethrow;
    }
  }

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Sets [isActive] on the customer document [id].
  Future<void> toggleCustomerActive(String id, {required bool isActive}) async {
    debugPrint(
      '[CustomerRepository] toggleCustomerActive id=$id isActive=$isActive',
    );
    await _ref.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
