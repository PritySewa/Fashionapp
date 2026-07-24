import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/utils/slug_utils.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

/// GetX controller for the Products feature.
///
/// ## Responsibilities
/// - Subscribe to [ProductRepository.watchProducts] and expose the realtime list.
/// - Expose [isLoading] and [errorMessage] reactive state.
/// - Perform duplicate slug checks in-memory (no extra Firestore queries).
/// - Expose status updates (active toggle, featured toggle) and CRUD methods.
/// - Clean up subscription on dispose.
class ProductController extends GetxController {
  // ── Dependencies ────────────────────────────────────────────────────────────

  final ProductRepository _repository = Get.find<ProductRepository>();

  // ── Reactive state ──────────────────────────────────────────────────────────

  /// The live list of products.
  final RxList<ProductModel> products = <ProductModel>[].obs;

  /// True while an async write operation is in flight.
  final RxBool isLoading = false.obs;

  /// Error message to display to the user on failure.
  final RxnString errorMessage = RxnString();

  // ── Stream subscription ─────────────────────────────────────────────────────

  StreamSubscription<List<ProductModel>>? _productSubscription;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _subscribeToProducts();
  }

  @override
  void onClose() {
    _productSubscription?.cancel();
    _productSubscription = null;
    super.onClose();
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  void _subscribeToProducts() {
    _productSubscription = _repository.watchProducts().listen(
      (list) {
        products.assignAll(list);
        errorMessage.value = null;
        debugPrint(
          '[ProductController] stream update — ${list.length} products',
        );
      },
      onError: (Object error, StackTrace st) {
        debugPrint('[ProductController] stream error: $error');
        debugPrint('[ProductController] StackTrace: $st');
        errorMessage.value =
            'Failed to load products. Please check your connection.';
      },
    );
  }

  /// Cancels and re-subscribes the Firestore stream.
  @override
  void refresh() {
    _productSubscription?.cancel();
    _productSubscription = null;
    errorMessage.value = null;
    _subscribeToProducts();
  }

  /// Returns true if a product with [slug] already exists in the list,
  /// optionally excluding [excludeId] (used when updating).
  bool _slugExists(String slug, {String? excludeId}) {
    return products.any((p) => p.slug == slug && p.id != excludeId);
  }

  // ── Public actions ──────────────────────────────────────────────────────────

  /// Creates a new product after validating slug uniqueness.
  ///
  /// Returns a record indicating success or the localized error string.
  Future<({bool success, String? error})> createProduct({
    required String name,
    String? customSlug,
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
    required List<PickedProductImage> images,
    PickedThumbnail? thumbnail,
  }) async {
    final sw = Stopwatch()..start();
    debugPrint('[CTRL] createProduct ENTER  t=0ms');

    final slug = SlugUtils.toSlug(customSlug ?? name);
    if (slug.isEmpty) {
      debugPrint('[CTRL] createProduct REJECT empty slug  t=${sw.elapsedMilliseconds}ms');
      return (success: false, error: 'Product name must contain at least one alphanumeric character.');
    }
    if (_slugExists(slug)) {
      debugPrint('[CTRL] createProduct REJECT duplicate slug=$slug  t=${sw.elapsedMilliseconds}ms');
      return (success: false, error: 'A product with the slug "$slug" already exists. Please choose a different name.');
    }

    isLoading.value = true;
    errorMessage.value = null;
    debugPrint('[CTRL] isLoading=true  t=${sw.elapsedMilliseconds}ms');

    try {
      debugPrint('[CTRL] await _repository.createProduct START  t=${sw.elapsedMilliseconds}ms');
      await _repository.createProduct(
        name: name,
        slug: slug,
        description: description,
        categoryId: categoryId,
        badgeIds: badgeIds,
        sku: sku,
        price: price,
        comparePrice: comparePrice,
        costPrice: costPrice,
        stock: stock,
        isActive: isActive,
        isFeatured: isFeatured,
        thumbnail: thumbnail,
        images: images,
      );
      debugPrint('[CTRL] await _repository.createProduct DONE  t=${sw.elapsedMilliseconds}ms');
      return (success: true, error: null);
    } catch (e, st) {
      debugPrint('[CTRL] createProduct EXCEPTION  t=${sw.elapsedMilliseconds}ms: $e');
      debugPrint('[CTRL] Stack:\n$st');
      final errorMsg = e is ArgumentError ? e.message.toString() : 'Failed to create product. Please try again.';
      errorMessage.value = errorMsg;
      return (success: false, error: errorMsg);
    } finally {
      isLoading.value = false;
      debugPrint('[CTRL] createProduct FINALLY isLoading=false  t=${sw.elapsedMilliseconds}ms');
    }
  }

  /// Updates an existing product identified by [id].
  ///
  /// Returns a record indicating success or the localized error string.
  Future<({bool success, String? error})> updateProduct({
    required String id,
    String? name,
    String? customSlug,
    String? description,
    String? categoryId,
    List<String>? badgeIds,
    String? sku,
    double? price,
    double? comparePrice,
    bool clearComparePrice = false,
    double? costPrice,
    bool clearCostPrice = false,
    int? stock,
    bool? isActive,
    bool? isFeatured,
    List<PickedProductImage>? images,
    PickedThumbnail? thumbnail,
    bool deleteThumbnail = false,
  }) async {
    final sw = Stopwatch()..start();
    debugPrint('[CTRL] updateProduct ENTER  t=0ms');

    String? slug;
    if (customSlug != null || name != null) {
      slug = SlugUtils.toSlug(customSlug ?? name!);
      if (slug.isEmpty) {
        debugPrint('[CTRL] updateProduct REJECT empty slug  t=${sw.elapsedMilliseconds}ms');
        return (success: false, error: 'Product name must contain at least one alphanumeric character.');
      }
      if (_slugExists(slug, excludeId: id)) {
        debugPrint('[CTRL] updateProduct REJECT duplicate slug=$slug  t=${sw.elapsedMilliseconds}ms');
        return (success: false, error: 'A product with the slug "$slug" already exists.');
      }
    }

    isLoading.value = true;
    errorMessage.value = null;
    debugPrint('[CTRL] isLoading=true  t=${sw.elapsedMilliseconds}ms');

    try {
      debugPrint('[CTRL] await _repository.updateProduct START  t=${sw.elapsedMilliseconds}ms');
      await _repository.updateProduct(
        id: id,
        name: name,
        slug: slug,
        description: description,
        categoryId: categoryId,
        badgeIds: badgeIds,
        sku: sku,
        price: price,
        comparePrice: comparePrice,
        clearComparePrice: clearComparePrice,
        costPrice: costPrice,
        clearCostPrice: clearCostPrice,
        stock: stock,
        isActive: isActive,
        isFeatured: isFeatured,
        thumbnail: thumbnail,
        deleteThumbnail: deleteThumbnail,
        images: images,
      );
      debugPrint('[CTRL] await _repository.updateProduct DONE  t=${sw.elapsedMilliseconds}ms');
      return (success: true, error: null);
    } catch (e, st) {
      debugPrint('[CTRL] updateProduct EXCEPTION  t=${sw.elapsedMilliseconds}ms: $e');
      debugPrint('[CTRL] Stack:\n$st');
      final errorMsg = e is ArgumentError ? e.message.toString() : 'Failed to update product. Please try again.';
      errorMessage.value = errorMsg;
      return (success: false, error: errorMsg);
    } finally {
      isLoading.value = false;
      debugPrint('[CTRL] updateProduct FINALLY isLoading=false  t=${sw.elapsedMilliseconds}ms');
    }
  }

  /// Permanently deletes the product identified by [id].
  Future<({bool success, String? error})> deleteProduct(String id) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.deleteProduct(id);
      debugPrint('[ProductController] deleteProduct success id=$id');
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[ProductController] deleteProduct error: $e');
      errorMessage.value = 'Failed to delete product. Please try again.';
      return (
        success: false,
        error: 'Failed to delete product. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggles the [isActive] flag on [product].
  Future<({bool success, String? error})> toggleProductActive(
    ProductModel product,
  ) async {
    final newValue = !product.isActive;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.setProductActive(product.id, isActive: newValue);
      debugPrint(
        '[ProductController] toggleProductActive id=${product.id} → $newValue',
      );
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[ProductController] toggleProductActive error: $e');
      errorMessage.value = 'Failed to update product status. Please try again.';
      return (
        success: false,
        error: 'Failed to update product status. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggles the [isFeatured] flag on [product].
  Future<({bool success, String? error})> toggleProductFeatured(
    ProductModel product,
  ) async {
    final newValue = !product.isFeatured;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.setProductFeatured(product.id, isFeatured: newValue);
      debugPrint(
        '[ProductController] toggleProductFeatured id=${product.id} → $newValue',
      );
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[ProductController] toggleProductFeatured error: $e');
      errorMessage.value =
          'Failed to update product featured status. Please try again.';
      return (
        success: false,
        error: 'Failed to update product featured status. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
