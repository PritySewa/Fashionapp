import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final double totalAmount;
  final String status;
  final List<Map<String, dynamic>> items;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.status,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json, String id) {
    return Order(
      id: id,
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'Pending',
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'status': status,
      'items': items,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
