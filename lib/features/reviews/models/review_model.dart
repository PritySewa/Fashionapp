import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ReviewStatus {
  pending,
  approved,
  rejected;

  String get value => name; // 'pending', 'approved', 'rejected'

  static ReviewStatus fromString(String? raw) {
    return ReviewStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ReviewStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case ReviewStatus.pending:
        return 'Pending';
      case ReviewStatus.approved:
        return 'Approved';
      case ReviewStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Immutable snapshot of a review from the [reviews] collection.
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.rating,
    required this.comment,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String userId;
  final String userName;
  final String? userImage;
  final double rating;
  final String comment;
  final List<String> imageUrls;
  final ReviewStatus status;
  final DateTime createdAt;

  factory ReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final id = snapshot.id;

    DateTime safeTimestamp(String field) {
      final raw = data[field];
      if (raw is Timestamp) return raw.toDate();
      debugPrint(
        '[ReviewModel] WARNING: document $id missing "$field". Falling back to epoch.',
      );
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final rawImages = data['imageUrls'];
    final images = rawImages is List
        ? rawImages.whereType<String>().toList()
        : <String>[];

    return ReviewModel(
      id: id,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? 'Product',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Customer',
      userImage: data['userImage'] as String?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String? ?? '',
      imageUrls: images,
      status: ReviewStatus.fromString(data['status'] as String?),
      createdAt: safeTimestamp('createdAt'),
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'userId': userId,
    'userName': userName,
    if (userImage != null) 'userImage': userImage,
    'rating': rating,
    'comment': comment,
    'imageUrls': imageUrls,
    'status': status.value,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  ReviewModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? userId,
    String? userName,
    String? userImage,
    double? rating,
    String? comment,
    List<String>? imageUrls,
    ReviewStatus? status,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get userInitials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }
}
