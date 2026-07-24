import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/banner_model.dart';

/// Repository for all Firestore & Storage operations on the [banners] collection.
class BannerRepository {
  BannerRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const String _collection = 'banners';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  // ── Watch Stream ───────────────────────────────────────────────────────────

  /// Streams all banners ordered by [displayOrder] ascending.
  Stream<List<BannerModel>> watchBanners() {
    return _ref.orderBy('displayOrder', descending: false).snapshots().map((snap) {
      final banners = snap.docs.map(BannerModel.fromFirestore).toList();
      debugPrint('[BannerRepository] watchBanners emitted ${banners.length} items');
      return banners;
    });
  }

  // ── Storage Upload Helper ──────────────────────────────────────────────────

  Future<String> _uploadImage(String bannerId, PickedBannerImage image) async {
    if (image.isRemote) return image.url!;
    if (!image.isLocal) throw ArgumentError('Banner image contains no data.');

    final ext = image.name != null && image.name!.contains('.')
        ? image.name!.split('.').last.toLowerCase()
        : 'jpg';
    final storageRef =
        _storage.ref().child('banners/$bannerId/image_$ext');

    final metadata = SettableMetadata(
      contentType: 'image/$ext',
      customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
    );

    debugPrint('[BannerRepository] uploading image to ${storageRef.fullPath}');
    final uploadTask = await storageRef.putData(image.bytes!, metadata);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    debugPrint('[BannerRepository] image upload complete: $downloadUrl');
    return downloadUrl;
  }

  // ── CRUD Operations ────────────────────────────────────────────────────────

  /// Creates a new banner document in Firestore, uploading image if provided.
  Future<void> createBanner({
    required String title,
    required String subtitle,
    required PickedBannerImage image,
    required BannerTargetType targetType,
    String? targetId,
    String? externalUrl,
    required int displayOrder,
    bool isActive = true,
  }) async {
    final docRef = _ref.doc();
    final bannerId = docRef.id;

    String downloadUrl = '';
    if (image.isLocal) {
      downloadUrl = await _uploadImage(bannerId, image);
    } else if (image.isRemote) {
      downloadUrl = image.url!;
    }

    final data = {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': downloadUrl,
      'targetType': targetType.value,
      'targetId': targetId,
      'externalUrl': externalUrl,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data);
    debugPrint('[BannerRepository] created banner $bannerId');
  }

  /// Updates an existing banner document.
  Future<void> updateBanner({
    required String id,
    String? title,
    String? subtitle,
    PickedBannerImage? image,
    BannerTargetType? targetType,
    String? targetId,
    bool clearTargetId = false,
    String? externalUrl,
    bool clearExternalUrl = false,
    int? displayOrder,
    bool? isActive,
  }) async {
    final docRef = _ref.doc(id);
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updates['title'] = title;
    if (subtitle != null) updates['subtitle'] = subtitle;
    if (targetType != null) updates['targetType'] = targetType.value;
    if (displayOrder != null) updates['displayOrder'] = displayOrder;
    if (isActive != null) updates['isActive'] = isActive;

    if (clearTargetId) {
      updates['targetId'] = FieldValue.delete();
    } else if (targetId != null) {
      updates['targetId'] = targetId;
    }

    if (clearExternalUrl) {
      updates['externalUrl'] = FieldValue.delete();
    } else if (externalUrl != null) {
      updates['externalUrl'] = externalUrl;
    }

    if (image != null) {
      if (image.isLocal) {
        final downloadUrl = await _uploadImage(id, image);
        updates['imageUrl'] = downloadUrl;
      } else if (image.isRemote) {
        updates['imageUrl'] = image.url;
      }
    }

    await docRef.update(updates);
    debugPrint('[BannerRepository] updated banner $id');
  }

  /// Toggles [isActive] on banner [id].
  Future<void> toggleBannerActive(String id, {required bool isActive}) async {
    await _ref.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes banner document [id].
  Future<void> deleteBanner(String id) async {
    await _ref.doc(id).delete();
    debugPrint('[BannerRepository] deleted banner $id');
  }
}
