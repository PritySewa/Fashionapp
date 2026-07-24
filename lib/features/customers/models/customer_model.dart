import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Immutable snapshot of a single document from the Firestore [users]
/// collection (customer-facing user records).
///
/// ## Firestore document structure
///
/// ```
/// users/{userId}
///   name:        String
///   email:       String
///   phone:       String?
///   avatarUrl:   String?
///   isActive:    bool
///   totalOrders: int
///   totalSpent:  double
///   createdAt:   Timestamp
///   updatedAt:   Timestamp
/// ```
class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.totalOrders,
    required this.totalSpent,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final int totalOrders;
  final double totalSpent;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Serialization ──────────────────────────────────────────────────────────

  factory CustomerModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final id = snapshot.id;

    DateTime safeTimestamp(String field) {
      final raw = data[field];
      if (raw is Timestamp) return raw.toDate();
      debugPrint(
        '[CustomerModel] WARNING: document $id missing "$field". Falling back to epoch.',
      );
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return CustomerModel(
      id: id,
      name: data['name'] as String? ?? 'Unknown',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0,
      createdAt: safeTimestamp('createdAt'),
      updatedAt: safeTimestamp('updatedAt'),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    if (phone != null) 'phone': phone,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'isActive': isActive,
    'totalOrders': totalOrders,
    'totalSpent': totalSpent,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  CustomerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    bool? isActive,
    int? totalOrders,
    double? totalSpent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the first letter of the name for avatar placeholder.
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  String toString() =>
      'CustomerModel(id: $id, name: $name, email: $email, isActive: $isActive)';
}
