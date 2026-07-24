
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../badges/repositories/badge_repository.dart';
import '../../categories/repositories/category_repository.dart';
import '../models/product_model.dart';

/// Repository responsible for all Firestore operations on the [products]
/// collection.
///
/// Registered permanently at the application level via [AppBinding] so that
/// [ProductController] and any future feature can resolve it via
/// `Get.find<ProductRepository>()`.
///
/// ## Architecture
/// ```
/// ProductController
///   ↓
/// ProductRepository
///   ↓
/// Cloud Firestore  products/{productId}
///   ↓
/// ProductModel
/// ```
class ProductRepository {
  ProductRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    CategoryRepository? categoryRepository,
    BadgeRepository? badgeRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _categoryRepository =
           categoryRepository ?? Get.find<CategoryRepository>(),
       _badgeRepository = badgeRepository ?? Get.find<BadgeRepository>();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final CategoryRepository _categoryRepository;
  final BadgeRepository _badgeRepository;

  static const String _collection = 'products';


  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a realtime [Stream] of all products ordered by [createdAt] descending.
  Stream<List<ProductModel>> watchProducts() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs.map(ProductModel.fromFirestore).toList();
          debugPrint('[PRODUCT_READ] Step 1 Stream emitted ${products.length} products');
          for (final p in products) {
            debugPrint('[PRODUCT_READ] Step 2 Product ${p.id} thumbnailImage=${p.thumbnailImage}  displayImageUrl=${p.displayImageUrl}');
          }
          return products;
        });
  }

  /// Fetches a single product document by [id].
  ///
  /// Returns `null` if the document does not exist or logs a warning on error.
  Future<ProductModel?> getProduct(String id) async {
    try {
      final snapshot = await _firestore.collection(_collection).doc(id).get();
      if (!snapshot.exists) return null;
      return ProductModel.fromFirestore(snapshot);
    } catch (e, st) {
      debugPrint('[ProductRepository] ERROR getProduct id=$id: $e');
      debugPrint('[ProductRepository] StackTrace: $st');
      return null;
    }
  }

  /// Creates a new product document and returns the Firestore-generated ID.
  ///
  /// Before creation, this method validates that:
  /// 1. The referenced category [categoryId] exists.
  /// 2. All referenced badges in [badgeIds] exist.
  ///
  /// Throws [ArgumentError] if references are invalid.
  /// Throws the underlying Firestore exception on other database errors.
  Future<String> createProduct({
    required String name,
    required String slug,
    required String description,
    required String categoryId,
    required List<String> badgeIds,
    required String sku,
    required double price,
    double? comparePrice,
    double? costPrice,
    required int stock,
    bool isActive = true,
    bool isFeatured = false,
    PickedThumbnail? thumbnail,
    required List<PickedProductImage> images,
  }) async {
    final sw = Stopwatch()..start();
    debugPrint('[PRODUCT_CREATE] Step 1 ENTER  slug=$slug  bucket=${_storage.bucket}');

    // 1. Validate Category
    final category = await _categoryRepository.getCategory(categoryId);
    if (category == null) {
      throw ArgumentError('Referenced category does not exist.');
    }
    debugPrint('[PRODUCT_CREATE] Step 1 category validated  t=${sw.elapsedMilliseconds}ms');

    // 2. Validate Badges (parallel)
    if (badgeIds.isNotEmpty) {
      final badgeResults = await Future.wait(
        badgeIds.map((id) => _badgeRepository.getBadge(id)),
      );
      for (int i = 0; i < badgeIds.length; i++) {
        if (badgeResults[i] == null) {
          throw ArgumentError('Referenced badge "${badgeIds[i]}" does not exist.');
        }
      }
    }
    debugPrint('[PRODUCT_CREATE] Step 1 badges validated  t=${sw.elapsedMilliseconds}ms');

    // 3. Generate doc ref
    final docRef = _firestore.collection(_collection).doc();
    final productId = docRef.id;

    // 4. Upload thumbnail
    String? thumbnailUrl;
    if (thumbnail != null && thumbnail.bytes != null) {
      final ext = _extractExtension(thumbnail.name);
      final ref = _storage.ref().child('products/$productId/thumbnail.$ext');
      debugPrint('[PRODUCT_CREATE] Step 2 Thumbnail upload START  path=${ref.fullPath}  bytes=${thumbnail.bytes!.length}  t=${sw.elapsedMilliseconds}ms');
      try {
        final task = await ref.putData(
          thumbnail.bytes!,
          SettableMetadata(contentType: 'image/$ext'),
        );
        thumbnailUrl = await task.ref.getDownloadURL();
        debugPrint('[PRODUCT_CREATE] Step 2 Thumbnail upload DONE  url=$thumbnailUrl  t=${sw.elapsedMilliseconds}ms');
      } catch (e, st) {
        debugPrint('[PRODUCT_CREATE] Step 2 Thumbnail upload ERROR  path=${ref.fullPath}  t=${sw.elapsedMilliseconds}ms: $e');
        debugPrint('[PRODUCT_CREATE] Stack:\n$st');
        throw Exception('Failed to upload thumbnail "${ref.fullPath}". If testing on web, please ensure CORS is configured on your Firebase Storage bucket. Error: $e');
      }
    } else {
      debugPrint('[PRODUCT_CREATE] Step 2 Thumbnail SKIPPED (thumbnail=${thumbnail != null}, bytes=${thumbnail?.bytes != null})  t=${sw.elapsedMilliseconds}ms');
    }

    // 5. Upload gallery images
    debugPrint('[PRODUCT_CREATE] Step 3 Gallery upload START (${images.length} images)  t=${sw.elapsedMilliseconds}ms');
    final List<String> imageUrls = [];
    for (int i = 0; i < images.length; i++) {
      final img = images[i];
      if (img.bytes != null) {
        final ext = _extractExtension(img.name);
        final storagePath =
            'products/$productId/gallery/image_${(i + 1).toString().padLeft(3, '0')}.$ext';
        try {
          debugPrint('[PRODUCT_CREATE] Step 3 Gallery image ${i + 1}/${images.length} START  path=$storagePath  bytes=${img.bytes!.length}  t=${sw.elapsedMilliseconds}ms');
          final task = await _storage.ref().child(storagePath).putData(
            img.bytes!,
            SettableMetadata(contentType: 'image/$ext'),
          );
          final url = await task.ref.getDownloadURL();
          debugPrint('[PRODUCT_CREATE] Step 3 Gallery image ${i + 1}/${images.length} DONE  url=$url  t=${sw.elapsedMilliseconds}ms');
          imageUrls.add(url);
        } catch (e, st) {
          debugPrint('[PRODUCT_CREATE] Step 3 Gallery image ${i + 1} ERROR  path=$storagePath  t=${sw.elapsedMilliseconds}ms: $e');
          debugPrint('[PRODUCT_CREATE] Stack:\n$st');
          throw Exception('Failed to upload image "$storagePath". If testing on web, please ensure CORS is configured on your Firebase Storage bucket. Error: $e');
        }
      }
    }
    debugPrint('[PRODUCT_CREATE] Step 3 Gallery upload DONE (${imageUrls.length} urls)  t=${sw.elapsedMilliseconds}ms');

    // 6. Firestore document creation
    // BUG-02 FIX: Build map without null optional fields to keep documents clean.
    debugPrint('[PRODUCT_CREATE] Step 4 Firestore write START  thumbnailUrl=$thumbnailUrl  imageUrls=${imageUrls.length}  t=${sw.elapsedMilliseconds}ms');
    final docData = <String, dynamic>{
      'name': name,
      'slug': slug,
      'description': description,
      'categoryId': categoryId,
      'badgeIds': badgeIds,
      'sku': sku,
      'price': price,
      'stock': stock,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'thumbnailImage': thumbnailUrl,
      'images': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (comparePrice != null) docData['comparePrice'] = comparePrice;
    if (costPrice != null) docData['costPrice'] = costPrice;
    await docRef.set(docData);
    debugPrint('[PRODUCT_CREATE] Step 4 Firestore write DONE  t=${sw.elapsedMilliseconds}ms');
    debugPrint('[PRODUCT_CREATE] Step 5 COMPLETE  id=$productId  t=${sw.elapsedMilliseconds}ms');
    return productId;
  }

  /// Updates an existing product document identified by [id].
  ///
  /// Before updating, this method validates the referenced category and badges
  /// if they are provided (non-null).
  ///
  /// Throws [ArgumentError] if references are invalid.
  /// Throws the underlying Firestore exception on other database errors.
  Future<void> updateProduct({
    required String id,
    String? name,
    String? slug,
    String? description,
    String? categoryId,
    List<String>? badgeIds,
    String? sku,
    double? price,
    double? comparePrice,
    // BUG-03 FIX: When true, deletes the Firestore field so clearing the
    // price on Edit actually takes effect instead of silently preserving
    // the old value.
    bool clearComparePrice = false,
    double? costPrice,
    bool clearCostPrice = false,
    int? stock,
    bool? isActive,
    bool? isFeatured,
    PickedThumbnail? thumbnail,
    bool deleteThumbnail = false,
    List<PickedProductImage>? images,
  }) async {
    final sw = Stopwatch()..start();
    debugPrint('[PRODUCT_UPDATE] Step 1 ENTER  id=$id');

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 1. Validate Category
    if (categoryId != null) {
      final category = await _categoryRepository.getCategory(categoryId);
      if (category == null) {
        throw ArgumentError('Referenced category does not exist.');
      }
      updates['categoryId'] = categoryId;
    }
    debugPrint('[PRODUCT_UPDATE] Step 1 category validated  t=${sw.elapsedMilliseconds}ms');

    // 2. Validate Badges (parallel)
    if (badgeIds != null) {
      if (badgeIds.isNotEmpty) {
        final badgeResults = await Future.wait(
          badgeIds.map((id) => _badgeRepository.getBadge(id)),
        );
        for (int i = 0; i < badgeIds.length; i++) {
          if (badgeResults[i] == null) {
            throw ArgumentError('Referenced badge "${badgeIds[i]}" does not exist.');
          }
        }
      }
      updates['badgeIds'] = badgeIds;
    }
    debugPrint('[PRODUCT_UPDATE] Step 1 badges validated  t=${sw.elapsedMilliseconds}ms');

    // 3. Simple field updates
    if (name != null) updates['name'] = name;
    if (slug != null) updates['slug'] = slug;
    if (description != null) updates['description'] = description;
    if (sku != null) updates['sku'] = sku;
    if (price != null) updates['price'] = price;
    // BUG-03 FIX: clearComparePrice=true means the user wiped the field;
    // use FieldValue.delete() to actually remove it from Firestore.
    if (clearComparePrice) {
      updates['comparePrice'] = FieldValue.delete();
      debugPrint('[PRODUCT_UPDATE] comparePrice CLEARED (FieldValue.delete)');
    } else if (comparePrice != null) {
      updates['comparePrice'] = comparePrice;
    }
    if (clearCostPrice) {
      updates['costPrice'] = FieldValue.delete();
      debugPrint('[PRODUCT_UPDATE] costPrice CLEARED (FieldValue.delete)');
    } else if (costPrice != null) {
      updates['costPrice'] = costPrice;
    }
    if (stock != null) updates['stock'] = stock;
    if (isActive != null) updates['isActive'] = isActive;
    if (isFeatured != null) updates['isFeatured'] = isFeatured;

    // 4. Thumbnail handling
    debugPrint('[PRODUCT_UPDATE] Step 2 Thumbnail changed? deleteThumbnail=$deleteThumbnail  newThumbnail=${thumbnail != null}  isRemote=${thumbnail?.isRemote}  hasBytes=${thumbnail?.bytes != null}  t=${sw.elapsedMilliseconds}ms');
    if (deleteThumbnail) {
      debugPrint('[PRODUCT_UPDATE] Step 3 Old thumbnail delete START  t=${sw.elapsedMilliseconds}ms');
      await _deleteStorageFile('products/$id/thumbnail');
      updates['thumbnailImage'] = null;
      debugPrint('[PRODUCT_UPDATE] Step 3 Old thumbnail delete DONE  t=${sw.elapsedMilliseconds}ms');
    } else if (thumbnail != null) {
      if (thumbnail.isRemote) {
        updates['thumbnailImage'] = thumbnail.url;
        debugPrint('[PRODUCT_UPDATE] Step 3 Thumbnail unchanged (remote url kept)  t=${sw.elapsedMilliseconds}ms');
      } else if (thumbnail.bytes != null) {
        debugPrint('[PRODUCT_UPDATE] Step 3 Old thumbnail delete START  t=${sw.elapsedMilliseconds}ms');
        await _deleteStorageFile('products/$id/thumbnail');
        debugPrint('[PRODUCT_UPDATE] Step 3 Old thumbnail delete DONE  t=${sw.elapsedMilliseconds}ms');
        final ext = _extractExtension(thumbnail.name);
        final ref = _storage.ref().child('products/$id/thumbnail.$ext');
        debugPrint('[PRODUCT_UPDATE] Step 4 New thumbnail upload START  path=${ref.fullPath}  bytes=${thumbnail.bytes!.length}  t=${sw.elapsedMilliseconds}ms');
        try {
          final task = await ref.putData(
            thumbnail.bytes!,
            SettableMetadata(contentType: 'image/$ext'),
          );
          updates['thumbnailImage'] = await task.ref.getDownloadURL();
          debugPrint('[PRODUCT_UPDATE] Step 4 New thumbnail upload DONE  url=${updates['thumbnailImage']}  t=${sw.elapsedMilliseconds}ms');
        } catch (e, st) {
          debugPrint('[PRODUCT_UPDATE] Step 4 New thumbnail upload ERROR  path=${ref.fullPath}  t=${sw.elapsedMilliseconds}ms: $e');
          debugPrint('[PRODUCT_UPDATE] Stack:\n$st');
          throw Exception('Failed to upload thumbnail "${ref.fullPath}". If testing on web, please ensure CORS is configured on your Firebase Storage bucket. Error: $e');
        }
      }
    }

    // 5. Gallery image handling
    if (images != null) {
      final existingDoc = await getProduct(id);
      final oldUrls = existingDoc?.images ?? [];

      // Delete removed images from Storage
      final keptUrls = images
          .where((img) => img.isRemote)
          .map((img) => img.url!)
          .toList();
      for (final url in oldUrls) {
        if (!keptUrls.contains(url)) {
          try {
            await _storage.refFromURL(url).delete();
          } catch (e) {
            debugPrint('[REPO] Warning: failed to delete old image: $e');
          }
        }
      }

      // Determine next sequential index for new uploads
      int maxIndex = 0;
      final regExp = RegExp(r'image_(\d+)');
      for (final url in oldUrls) {
        final match = regExp.firstMatch(url);
        if (match != null) {
          final idx = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (idx > maxIndex) maxIndex = idx;
        }
      }

      // Build final URL list — keep remote URLs, upload new ones sequentially
      // TODO(debug): Sequential uploads with per-image instrumentation.
      //              Restore Future.wait() parallel uploads after root cause is found.
      final finalUrls = <String>[];
      for (int i = 0; i < images.length; i++) {
        final img = images[i];
        debugPrint('[REPO] gallery[$i] isRemote=${img.isRemote}  hasBytes=${img.bytes != null}  bytesLen=${img.bytes?.length}  name=${img.name}  t=${sw.elapsedMilliseconds}ms');
        if (img.isRemote) {
          finalUrls.add(img.url!);
          debugPrint('[REPO] gallery[$i] KEPT remote url=${img.url}  t=${sw.elapsedMilliseconds}ms');
        } else if (img.bytes != null) {
          final ext = _extractExtension(img.name);
          maxIndex++;
          final storagePath =
              'products/$id/gallery/image_${maxIndex.toString().padLeft(3, '0')}.$ext';
          try {
            debugPrint('[REPO] gallery[$i] putData START  path=$storagePath  bytes=${img.bytes!.length}  t=${sw.elapsedMilliseconds}ms');
            final task = await _storage.ref().child(storagePath).putData(
              img.bytes!,
              SettableMetadata(contentType: 'image/$ext'),
            );
            debugPrint('[REPO] gallery[$i] putData DONE  state=${task.state}  t=${sw.elapsedMilliseconds}ms');
            final url = await task.ref.getDownloadURL();
            debugPrint('[REPO] gallery[$i] getDownloadURL DONE  url=$url  t=${sw.elapsedMilliseconds}ms');
            finalUrls.add(url);
          } catch (e, st) {
            debugPrint('[REPO] gallery[$i] FAILED  path=$storagePath  t=${sw.elapsedMilliseconds}ms');
            debugPrint('[REPO] gallery[$i] exception: $e');
            debugPrint('[REPO] gallery[$i] stack:\n$st');
            throw Exception('Failed to upload image "$storagePath". If testing on web, please ensure CORS is configured on your Firebase Storage bucket. Error: $e');
          }
        } else {
          debugPrint('[REPO] gallery[$i] SKIPPED (bytes==null)  t=${sw.elapsedMilliseconds}ms');
        }
      }
      updates['images'] = finalUrls;
      debugPrint('[REPO] gallery complete: ${finalUrls.length} images  t=${sw.elapsedMilliseconds}ms');
    }

    // 6. Firestore update
    debugPrint('[PRODUCT_UPDATE] Step 5 Firestore update START  keys=${updates.keys.toList()}  t=${sw.elapsedMilliseconds}ms');
    await _firestore.collection(_collection).doc(id).update(updates);
    debugPrint('[PRODUCT_UPDATE] Step 5 Firestore update DONE  t=${sw.elapsedMilliseconds}ms');
    debugPrint('[PRODUCT_UPDATE] Step 6 COMPLETE  id=$id  t=${sw.elapsedMilliseconds}ms');
  }

  /// Permanently deletes the product document identified by [id].
  Future<void> deleteProduct(String id) async {
    final sw = Stopwatch()..start();
    debugPrint('[PRODUCT_DELETE] Step 1 ENTER  id=$id');
    // Delete all files in Storage (thumbnail + gallery)
    try {
      final root = _storage.ref().child('products/$id');
      debugPrint('[PRODUCT_DELETE] Step 2 listAll START  t=${sw.elapsedMilliseconds}ms');
      final listResult = await root.listAll();
      debugPrint('[PRODUCT_DELETE] Step 2 listAll DONE  items=${listResult.items.length}  prefixes=${listResult.prefixes.length}  t=${sw.elapsedMilliseconds}ms');
      // Delete top-level files (thumbnail)
      for (final ref in listResult.items) {
        debugPrint('[PRODUCT_DELETE] Step 3 delete item START  path=${ref.fullPath}  t=${sw.elapsedMilliseconds}ms');
        try {
          await ref.delete();
          debugPrint('[PRODUCT_DELETE] Step 3 delete item DONE  path=${ref.fullPath}  t=${sw.elapsedMilliseconds}ms');
        } on FirebaseException catch (e) {
          debugPrint('[PRODUCT_DELETE] Step 3 delete item FIREBASE ERROR  path=${ref.fullPath}  code=${e.code}  plugin=${e.plugin}  message=${e.message}  t=${sw.elapsedMilliseconds}ms');
        }
      }
      // Delete subdirectories (gallery/)
      for (final prefix in listResult.prefixes) {
        debugPrint('[PRODUCT_DELETE] Step 4 listAll sub START  prefix=${prefix.fullPath}  t=${sw.elapsedMilliseconds}ms');
        final subList = await prefix.listAll();
        debugPrint('[PRODUCT_DELETE] Step 4 listAll sub DONE  items=${subList.items.length}  t=${sw.elapsedMilliseconds}ms');
        for (final ref in subList.items) {
          debugPrint('[PRODUCT_DELETE] Step 4 delete sub item START  path=${ref.fullPath}  t=${sw.elapsedMilliseconds}ms');
          try {
            await ref.delete();
            debugPrint('[PRODUCT_DELETE] Step 4 delete sub item DONE  path=${ref.fullPath}  t=${sw.elapsedMilliseconds}ms');
          } on FirebaseException catch (e) {
            debugPrint('[PRODUCT_DELETE] Step 4 delete sub item FIREBASE ERROR  path=${ref.fullPath}  code=${e.code}  plugin=${e.plugin}  message=${e.message}  t=${sw.elapsedMilliseconds}ms');
          }
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('[PRODUCT_DELETE] Step 2 listAll FIREBASE ERROR  code=${e.code}  plugin=${e.plugin}  message=${e.message}  t=${sw.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint(
        '[PRODUCT_DELETE] Warning: failed to clean storage for $id: $e  t=${sw.elapsedMilliseconds}ms',
      );
    }
    // Delete Firestore document
    debugPrint('[PRODUCT_DELETE] Step 5 Firestore delete START  t=${sw.elapsedMilliseconds}ms');
    await _firestore.collection(_collection).doc(id).delete();
    debugPrint('[PRODUCT_DELETE] Step 5 Firestore delete DONE  t=${sw.elapsedMilliseconds}ms');
    debugPrint('[PRODUCT_DELETE] Step 6 COMPLETE  t=${sw.elapsedMilliseconds}ms');
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Deletes any file matching the prefix (ignoring extension) from Storage.
  /// Used for thumbnail replacement where the extension may change.
  Future<void> _deleteStorageFile(String pathPrefix) async {
    try {
      // List files in the parent directory and match by name prefix
      final parentPath = pathPrefix.substring(0, pathPrefix.lastIndexOf('/'));
      final fileName = pathPrefix.substring(pathPrefix.lastIndexOf('/') + 1);
      final listResult = await _storage.ref().child(parentPath).listAll();
      for (final ref in listResult.items) {
        if (ref.name.startsWith(fileName)) {
          await ref.delete();
          debugPrint('[ProductRepository] Deleted storage file: ${ref.fullPath}');
        }
      }
    } catch (e) {
      debugPrint('[ProductRepository] Warning: _deleteStorageFile failed: $e');
    }
  }

  /// Extracts file extension from a filename, defaulting to 'jpeg'.
  ///
  /// BUG-01 FIX: Normalises 'jpg' → 'jpeg' so the Firebase Storage
  /// contentType is always a valid MIME type ('image/jpeg', not 'image/jpg').
  /// An invalid MIME type can cause Storage to reject uploads or serve the
  /// file without a proper Content-Type header, breaking browser rendering.
  String _extractExtension(String? name) {
    if (name != null && name.contains('.')) {
      final ext = name.split('.').last.toLowerCase();
      return ext == 'jpg' ? 'jpeg' : ext;
    }
    return 'jpeg'; // safe default — was 'jpg' (invalid MIME)
  }

  /// Convenience method to toggle a product's [isActive] flag.
  Future<void> setProductActive(String id, {required bool isActive}) async {
    debugPrint(
      '[ProductRepository] setProductActive id=$id isActive=$isActive',
    );
    await updateProduct(id: id, isActive: isActive);
  }

  /// Convenience method to toggle a product's [isFeatured] flag.
  Future<void> setProductFeatured(String id, {required bool isFeatured}) async {
    debugPrint(
      '[ProductRepository] setProductFeatured id=$id isFeatured=$isFeatured',
    );
    await updateProduct(id: id, isFeatured: isFeatured);
  }
}
