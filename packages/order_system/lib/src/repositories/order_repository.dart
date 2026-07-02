import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';

abstract class OrderRepository {
  Stream<List<Order>> watchOrders();
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
}

class FirebaseOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;

  FirebaseOrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Order>> watchOrders() {
    return _firestore.collection('orders').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Order.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(), // this gets mapped back to datetime if necessary on read
    });
  }
}
