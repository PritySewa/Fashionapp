import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ── OrderStatus ────────────────────────────────────────────────────────────────

/// Lifecycle status of an order.
enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled;

  /// Serialized string stored in Firestore.
  String get value => name; // 'pending', 'processing', etc.

  static OrderStatus fromString(String? raw) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => OrderStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// ── PaymentStatus ──────────────────────────────────────────────────────────────

/// Payment status of an order.
enum PaymentStatus {
  unpaid,
  paid,
  refunded;

  String get value => name;

  static PaymentStatus fromString(String? raw) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => PaymentStatus.unpaid,
    );
  }

  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

// ── OrderItem ──────────────────────────────────────────────────────────────────

/// A single line-item inside an [OrderModel].
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
    this.imageUrl,
  });

  final String productId;
  final String name;
  final double price;
  final int qty;
  final String? imageUrl;

  double get lineTotal => price * qty;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'price': price,
    'qty': qty,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

// ── OrderAddress ───────────────────────────────────────────────────────────────

/// Shipping address embedded in an [OrderModel].
class OrderAddress {
  const OrderAddress({
    required this.name,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
  });

  final String name;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;

  factory OrderAddress.fromMap(Map<String, dynamic> map) {
    return OrderAddress(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      line1: map['line1'] as String? ?? '',
      line2: map['line2'] as String?,
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      pincode: map['pincode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'line1': line1,
    if (line2 != null) 'line2': line2,
    'city': city,
    'state': state,
    'pincode': pincode,
  };

  String get formatted =>
      '$line1${line2 != null ? ', $line2' : ''}, $city, $state — $pincode';
}

// ── OrderModel ─────────────────────────────────────────────────────────────────

/// Immutable snapshot of a single document from the Firestore [orders]
/// collection.
///
/// ## Firestore document structure
///
/// ```
/// orders/{orderId}
///   customerId:    String
///   customerName:  String
///   customerEmail: String
///   items:         List<Map>
///   totalAmount:   double
///   status:        String  ('pending'|'processing'|'shipped'|'delivered'|'cancelled')
///   paymentStatus: String  ('unpaid'|'paid'|'refunded')
///   paymentMethod: String
///   address:       Map
///   notes:         String?
///   createdAt:     Timestamp
///   updatedAt:     Timestamp
/// ```
class OrderModel {
  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final OrderAddress address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get itemCount => items.fold(0, (acc, i) => acc + i.qty);

  // ── Serialization ──────────────────────────────────────────────────────────

  factory OrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final id = snapshot.id;

    DateTime safeTimestamp(String field) {
      final raw = data[field];
      if (raw is Timestamp) return raw.toDate();
      debugPrint(
        '[OrderModel] WARNING: document $id missing "$field". Falling back to epoch.',
      );
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(OrderItem.fromMap)
              .toList()
        : <OrderItem>[];

    final rawAddress = data['address'];
    final address = rawAddress is Map<String, dynamic>
        ? OrderAddress.fromMap(rawAddress)
        : const OrderAddress(
            name: '',
            phone: '',
            line1: '',
            city: '',
            state: '',
            pincode: '',
          );

    return OrderModel(
      id: id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Unknown',
      customerEmail: data['customerEmail'] as String? ?? '',
      items: items,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromString(data['status'] as String?),
      paymentStatus: PaymentStatus.fromString(data['paymentStatus'] as String?),
      paymentMethod: data['paymentMethod'] as String? ?? '',
      address: address,
      notes: data['notes'] as String?,
      createdAt: safeTimestamp('createdAt'),
      updatedAt: safeTimestamp('updatedAt'),
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'items': items.map((i) => i.toMap()).toList(),
    'totalAmount': totalAmount,
    'status': status.value,
    'paymentStatus': paymentStatus.value,
    'paymentMethod': paymentMethod,
    'address': address.toMap(),
    if (notes != null) 'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    OrderAddress? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'OrderModel(id: $id, customer: $customerName, status: ${status.value}, total: $totalAmount)';
}
