import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/category_model.dart';

/// Repository responsible for all Firestore operations on the [categories]
/// collection.
///
/// Registered permanently at the application level via [AppBinding] so that
/// [CategoryController] and any future feature can resolve it via
/// `Get.find<CategoryRepository>()` without re-creating the Firestore handle
/// or the realtime stream subscription.
///
/// ## Architecture
/// ```
/// CategoryController
///   ↓
/// CategoryRepository
///   ↓
/// Cloud Firestore  categories/{categoryId}
///   ↓
/// CategoryModel
/// ```
///
/// ## Firestore document structure
/// ```
/// categories/{categoryId}     ← Firestore auto-generated ID
///   name:        String
///   slug:        String       (unique per collection)
///   description: String
///   imageUrl:    String
///   isActive:    bool
///   sortOrder:   int
///   createdAt:   Timestamp    (server timestamp, set once on create)
///   updatedAt:   Timestamp    (server timestamp, updated on every write)
/// ```
///
/// ## Testing strategy
///
/// The [FirebaseFirestore] instance is injected via the constructor so tests
/// can supply a fake without touching the live project:
///
/// ```dart
/// final repo = CategoryRepository(firestore: _FakeFirestore());
/// ```
class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const String _collection = 'categories';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a realtime [Stream] of all categories ordered by [sortOrder].
  ///
  /// Uses Firestore's [snapshots()] so the admin UI updates automatically
  /// whenever a category document is created, updated, or deleted — without
  /// requiring the admin to manually refresh the page.
  ///
  /// The stream never completes under normal conditions; it only emits errors
  /// when Firestore is unavailable. The subscribing [CategoryController] is
  /// responsible for catching those errors.
  Stream<List<CategoryModel>> watchCategories() {
    return _firestore
        .collection(_collection)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(CategoryModel.fromFirestore).toList(),
        );
  }

  /// Fetches a single category document by [id].
  ///
  /// Returns `null` if the document does not exist.
  /// Returns `null` and logs a warning on any Firestore error.
  Future<CategoryModel?> getCategory(String id) async {
    try {
      final snapshot = await _firestore.collection(_collection).doc(id).get();
      if (!snapshot.exists) return null;
      return CategoryModel.fromFirestore(snapshot);
    } catch (e, st) {
      debugPrint('[CategoryRepository] ERROR getCategory id=$id: $e');
      debugPrint('[CategoryRepository] StackTrace: $st');
      return null;
    }
  }

  /// Creates a new category document and returns the Firestore-generated ID.
  ///
  /// Firestore generates the document ID automatically via [CollectionReference.add].
  /// Both [createdAt] and [updatedAt] are set to the Firestore server timestamp —
  /// never a client-side [DateTime] — to avoid clock skew issues.
  ///
  /// Throws the underlying Firestore exception on failure so that
  /// [CategoryController] can catch it and expose an appropriate error state.
  Future<String> createCategory({
    required String name,
    required String slug,
    required String description,
    String imageUrl = '',
    bool isActive = true,
    int sortOrder = 0,
    PickedCategoryImage? image,
  }) async {
    debugPrint('[CategoryRepository] createCategory slug=$slug');

    final docRef = _firestore.collection(_collection).doc();
    final categoryId = docRef.id;

    // Upload image to Storage if provided
    String resolvedImageUrl = imageUrl;
    if (image != null && image.bytes != null) {
      final ext = _extractExtension(image.name);
      final ref = _storage.ref().child('categories/$categoryId/image.$ext');
      try {
        final task = await ref.putData(
          image.bytes!,
          SettableMetadata(contentType: 'image/$ext'),
        );
        resolvedImageUrl = await task.ref.getDownloadURL();
      } catch (e) {
        debugPrint('[CategoryRepository] createCategory image upload failed: $e');
        throw Exception('Failed to upload category image "${ref.fullPath}". If testing on web, ensure CORS is configured on your Firebase Storage bucket. Error: $e');
      }
    }

    await docRef.set({
      'name': name,
      'slug': slug,
      'description': description,
      'imageUrl': resolvedImageUrl,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[CategoryRepository] created category id=$categoryId');
    return categoryId;
  }

  /// Updates an existing category document identified by [id].
  ///
  /// Uses [DocumentReference.update] to patch only the supplied fields.
  /// [createdAt] is never modified. [updatedAt] is always set to the
  /// current server timestamp regardless of which other fields change.
  ///
  /// Only non-null parameters are included in the Firestore update map.
  ///
  /// Throws the underlying Firestore exception on failure.
  Future<void> updateCategory({
    required String id,
    String? name,
    String? slug,
    String? description,
    String? imageUrl,
    bool? isActive,
    int? sortOrder,
    PickedCategoryImage? image,
    bool deleteImage = false,
  }) async {
    debugPrint('[CategoryRepository] updateCategory id=$id');

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (slug != null) updates['slug'] = slug;
    if (description != null) updates['description'] = description;
    if (isActive != null) updates['isActive'] = isActive;
    if (sortOrder != null) updates['sortOrder'] = sortOrder;

    // Image handling
    if (deleteImage) {
      await _deleteStorageDir('categories/$id');
      updates['imageUrl'] = '';
    } else if (image != null) {
      if (image.isRemote) {
        // Existing image unchanged
        updates['imageUrl'] = image.url;
      } else if (image.bytes != null) {
        // New or replaced image — delete old, upload new
        await _deleteStorageDir('categories/$id');
        final ext = _extractExtension(image.name);
        final ref = _storage.ref().child('categories/$id/image.$ext');
        try {
          final task = await ref.putData(
            image.bytes!,
            SettableMetadata(contentType: 'image/$ext'),
          );
          updates['imageUrl'] = await task.ref.getDownloadURL();
        } catch (e) {
          debugPrint('[CategoryRepository] updateCategory image upload failed: $e');
          throw Exception('Failed to upload category image "${ref.fullPath}". If testing on web, ensure CORS is configured on your Firebase Storage bucket. Error: $e');
        }
      }
    }
    // If imageUrl is explicitly passed (non-null string), include it
    if (imageUrl != null && image == null && !deleteImage) {
      updates['imageUrl'] = imageUrl;
    }

    await _firestore.collection(_collection).doc(id).update(updates);
  }

  /// Permanently deletes the category document identified by [id].
  ///
  /// This is a **hard delete**. The document is removed from Firestore
  /// and cannot be recovered.
  ///
  /// ---
  /// TODO(phase-products): Before deleting a category, check whether any
  /// Product documents reference this categoryId. If products exist in this
  /// category, prevent deletion and surface a clear error to the admin.
  /// This guard must be implemented when the Products feature is built
  /// (Phase 3.3+). Skipping it now would leave orphaned product documents
  /// pointing to a non-existent category.
  /// ---
  ///
  /// Throws the underlying Firestore exception on failure.
  Future<void> deleteCategory(String id) async {
    debugPrint('[CategoryRepository] deleteCategory id=$id');
    // Clean up Storage files
    await _deleteStorageDir('categories/$id');
    // Delete Firestore document
    await _firestore.collection(_collection).doc(id).delete();
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Extracts file extension from a filename, defaulting to 'jpeg'.
  /// Normalizes 'jpg' to 'jpeg' so contentType is a valid MIME type ('image/jpeg').
  String _extractExtension(String? name) {
    if (name != null && name.contains('.')) {
      final ext = name.split('.').last.toLowerCase();
      return ext == 'jpg' ? 'jpeg' : ext;
    }
    return 'jpeg';
  }

  /// Deletes all files in a Storage directory.
  Future<void> _deleteStorageDir(String path) async {
    try {
      final listResult = await _storage.ref().child(path).listAll();
      for (final ref in listResult.items) {
        await ref.delete();
      }
    } catch (e) {
      debugPrint(
        '[CategoryRepository] Warning: _deleteStorageDir failed for $path: $e',
      );
    }
  }

  /// Convenience method to toggle a category's [isActive] flag.
  ///
  /// Delegates to [updateCategory] with only the [isActive] field updated.
  /// [updatedAt] is refreshed automatically.
  ///
  /// Throws the underlying Firestore exception on failure.
  Future<void> setCategoryActive(String id, {required bool isActive}) async {
    debugPrint(
      '[CategoryRepository] setCategoryActive id=$id isActive=$isActive',
    );
    await updateCategory(id: id, isActive: isActive);
  }
}
