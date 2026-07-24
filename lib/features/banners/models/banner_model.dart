import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Target type for a marketing banner.
enum BannerTargetType {
  product,
  category,
  external;

  String get value => name; // 'product', 'category', 'external'

  static BannerTargetType fromString(String? raw) {
    return BannerTargetType.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => BannerTargetType.product,
    );
  }

  String get label {
    switch (this) {
      case BannerTargetType.product:
        return 'Product';
      case BannerTargetType.category:
        return 'Category';
      case BannerTargetType.external:
        return 'External Link';
    }
  }
}

/// Helper class to represent a banner image candidate during form editing.
class PickedBannerImage {
  const PickedBannerImage.fromUrl(this.url)
    : bytes = null,
      name = null;

  const PickedBannerImage.fromBytes({required this.bytes, required this.name})
    : url = null;

  final String? url;
  final Uint8List? bytes;
  final String? name;

  bool get isRemote => url != null && url!.isNotEmpty;
  bool get isLocal => bytes != null && bytes!.isNotEmpty;
}

/// Immutable model representing a single document from the [banners] collection.
class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.targetType,
    this.targetId,
    this.externalUrl,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final BannerTargetType targetType;
  final String? targetId;
  final String? externalUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BannerModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final id = snapshot.id;

    DateTime safeTimestamp(String field) {
      final raw = data[field];
      if (raw is Timestamp) return raw.toDate();
      debugPrint(
        '[BannerModel] WARNING: document $id missing "$field". Falling back to epoch.',
      );
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return BannerModel(
      id: id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      targetType: BannerTargetType.fromString(data['targetType'] as String?),
      targetId: data['targetId'] as String?,
      externalUrl: data['externalUrl'] as String?,
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: safeTimestamp('createdAt'),
      updatedAt: safeTimestamp('updatedAt'),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'targetType': targetType.value,
    if (targetId != null) 'targetId': targetId,
    if (externalUrl != null) 'externalUrl': externalUrl,
    'displayOrder': displayOrder,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  BannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    BannerTargetType? targetType,
    String? targetId,
    String? externalUrl,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      externalUrl: externalUrl ?? this.externalUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
