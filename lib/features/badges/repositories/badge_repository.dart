import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/badge_model.dart';

/// Repository responsible for all Firestore operations on the [badges]
/// collection.
///
/// Registered permanently at the application level via [AppBinding] so that
/// [BadgeController] and any future feature can resolve it via
/// `Get.find<BadgeRepository>()` without re-creating the Firestore handle
/// or the realtime stream subscription.
///
/// ## Architecture
/// ```
/// BadgeController
///   ↓
/// BadgeRepository
///   ↓
/// Cloud Firestore  badges/{badgeId}
///   ↓
/// BadgeModel
/// ```
///
/// ## Firestore document structure
/// ```
/// badges/{badgeId}        ← Firestore auto-generated ID
///   name:        String
///   slug:        String   (unique per collection)
///   color:       String   (hex colour, e.g. "#FF5733")
///   icon:        String   (Material icon name, e.g. "local_fire_department")
///   isActive:    bool
///   sortOrder:   int
///   createdAt:   Timestamp  (server timestamp, set once on create)
///   updatedAt:   Timestamp  (server timestamp, updated on every write)
/// ```
///
/// ## Testing strategy
///
/// The [FirebaseFirestore] instance is injected via the constructor so tests
/// can supply a fake without touching the live project:
///
/// ```dart
/// final repo = BadgeRepository(firestore: _FakeFirestore());
/// ```
class BadgeRepository {
  BadgeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'badges';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a realtime [Stream] of all badges ordered by [sortOrder].
  ///
  /// Uses Firestore's [snapshots()] so the admin UI updates automatically
  /// whenever a badge document is created, updated, or deleted.
  Stream<List<BadgeModel>> watchBadges() {
    return _firestore
        .collection(_collection)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(BadgeModel.fromFirestore).toList(),
        );
  }

  /// Fetches a single badge document by [id].
  ///
  /// Returns `null` if the document does not exist.
  Future<BadgeModel?> getBadge(String id) async {
    try {
      final snapshot = await _firestore.collection(_collection).doc(id).get();
      if (!snapshot.exists) return null;
      return BadgeModel.fromFirestore(snapshot);
    } catch (e, st) {
      debugPrint('[BadgeRepository] ERROR getBadge id=$id: $e');
      debugPrint('[BadgeRepository] StackTrace: $st');
      return null;
    }
  }

  /// Creates a new badge document and returns the Firestore-generated ID.
  ///
  /// Both [createdAt] and [updatedAt] use server timestamps to avoid
  /// clock skew issues.
  ///
  /// Throws the underlying Firestore exception on failure so that
  /// [BadgeController] can catch it and expose an appropriate error state.
  Future<String> createBadge({
    required String name,
    required String slug,
    String color = '',
    String icon = '',
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    debugPrint('[BadgeRepository] createBadge slug=$slug');

    final docRef = await _firestore.collection(_collection).add({
      'name': name,
      'slug': slug,
      'color': color,
      'icon': icon,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[BadgeRepository] created badge id=${docRef.id}');
    return docRef.id;
  }

  /// Updates an existing badge document identified by [id].
  ///
  /// Uses [DocumentReference.update] to patch only the supplied non-null
  /// fields. [updatedAt] is always refreshed.
  ///
  /// Throws the underlying Firestore exception on failure.
  Future<void> updateBadge({
    required String id,
    String? name,
    String? slug,
    String? color,
    String? icon,
    bool? isActive,
    int? sortOrder,
  }) async {
    debugPrint('[BadgeRepository] updateBadge id=$id');

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (slug != null) updates['slug'] = slug;
    if (color != null) updates['color'] = color;
    if (icon != null) updates['icon'] = icon;
    if (isActive != null) updates['isActive'] = isActive;
    if (sortOrder != null) updates['sortOrder'] = sortOrder;

    await _firestore.collection(_collection).doc(id).update(updates);
  }

  /// Permanently deletes the badge document identified by [id].
  ///
  /// This is a hard delete — the document cannot be recovered.
  ///
  /// ---
  /// TODO(phase-products): Before deleting a badge, check whether any
  /// Product documents reference this badgeId. If products exist with this
  /// badge, prevent deletion and surface a clear error. This guard must be
  /// implemented when the Products feature is built (Phase 3.3+).
  /// ---
  ///
  /// Throws the underlying Firestore exception on failure.
  Future<void> deleteBadge(String id) async {
    debugPrint('[BadgeRepository] deleteBadge id=$id');
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Convenience method to set a badge's [isActive] flag directly.
  ///
  /// Delegates to [updateBadge] with only [isActive] updated.
  /// [updatedAt] is refreshed automatically.
  ///
  /// Throws the underlying Firestore exception on failure.
  Future<void> setBadgeActive(String id, {required bool isActive}) async {
    debugPrint('[BadgeRepository] setBadgeActive id=$id isActive=$isActive');
    await updateBadge(id: id, isActive: isActive);
  }
}
