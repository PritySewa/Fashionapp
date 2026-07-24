import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/utils/slug_utils.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

/// GetX controller for the Categories feature.
///
/// ## Responsibilities
///
/// - Subscribe to [CategoryRepository.watchCategories] and expose the
///   realtime list as [categories].
/// - Expose [isLoading] and [errorMessage] reactive state for the UI.
/// - Provide create, update, delete, and toggle-active actions.
/// - Enforce slug uniqueness in-memory (no extra Firestore reads).
/// - Cancel the Firestore stream subscription when disposed.
///
/// ## What this controller does NOT do
///
/// - Access [FirebaseFirestore] directly — all Firestore calls go through
///   [CategoryRepository].
/// - Contain widget code, dialog code, or snackbar UI code.
///   UI feedback (snackbars, dialogs) is the responsibility of views.
/// - Perform duplicate slug checks via an extra Firestore query.
///   The in-memory [categories] list is used for instant, cheap validation.
///
/// ## Lifecycle
///
/// Registered via [DashboardBinding.lazyPut]. When GetX disposes this
/// controller (e.g. on route pop), [onClose] cancels [_categorySubscription]
/// so the Firestore stream does not leak.
class CategoryController extends GetxController {
  // ── Dependencies ────────────────────────────────────────────────────────────

  final CategoryRepository _repository = Get.find<CategoryRepository>();

  // ── Reactive state ──────────────────────────────────────────────────────────

  /// The live list of categories, updated automatically by the Firestore stream.
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  /// True while an async create / update / delete operation is in flight.
  /// The stream subscription itself does not set this flag.
  final RxBool isLoading = false.obs;

  /// Non-null when the most recent action or stream event produced an error.
  /// Null when everything is healthy.
  final RxnString errorMessage = RxnString();

  // ── Stream subscription ─────────────────────────────────────────────────────

  StreamSubscription<List<CategoryModel>>? _categorySubscription;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _subscribeToCategories();
  }

  @override
  void onClose() {
    _categorySubscription?.cancel();
    _categorySubscription = null;
    super.onClose();
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  void _subscribeToCategories() {
    _categorySubscription = _repository.watchCategories().listen(
      (list) {
        categories.assignAll(list);
        errorMessage.value = null;
        debugPrint(
          '[CategoryController] stream update — ${list.length} categories',
        );
      },
      onError: (Object error, StackTrace st) {
        debugPrint('[CategoryController] stream error: $error');
        debugPrint('[CategoryController] StackTrace: $st');
        errorMessage.value =
            'Failed to load categories. Please check your connection.';
      },
    );
  }

  /// Cancels and re-subscribes the Firestore stream.
  ///
  /// Called by [CategoriesView] when the user taps "Retry" in the error state.
  /// This is safe to call multiple times — the previous subscription is always
  /// cancelled before a new one is created.
  @override
  void refresh() {
    _categorySubscription?.cancel();
    _categorySubscription = null;
    errorMessage.value = null;
    _subscribeToCategories();
  }

  /// Returns true if a category with [slug] already exists in the
  /// in-memory [categories] list, optionally excluding [excludeId]
  /// (used when updating an existing category to ignore its own slug).
  bool _slugExists(String slug, {String? excludeId}) {
    return categories.any((c) => c.slug == slug && c.id != excludeId);
  }

  // ── Public actions ──────────────────────────────────────────────────────────

  /// Creates a new category after validating slug uniqueness.
  ///
  /// Returns a record:
  /// - `success: true` and `error: null` on success.
  /// - `success: false` and a non-null human-readable `error` on failure.
  ///
  /// The slug is auto-generated from [name] via [SlugUtils.toSlug].
  /// If [customSlug] is supplied it is used instead (after normalisation).
  ///
  /// The caller (view) is responsible for surfacing the error to the user.
  Future<({bool success, String? error})> createCategory({
    required String name,
    String? customSlug,
    String description = '',
    String imageUrl = '',
    bool isActive = true,
    int sortOrder = 0,
    PickedCategoryImage? image,
  }) async {
    final slug = SlugUtils.toSlug(customSlug ?? name);

    if (slug.isEmpty) {
      return (
        success: false,
        error:
            'Category name must contain at least one alphanumeric character.',
      );
    }

    if (_slugExists(slug)) {
      debugPrint('[CategoryController] duplicate slug rejected: $slug');
      return (
        success: false,
        error:
            'A category with the slug "$slug" already exists. '
            'Please choose a different name.',
      );
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.createCategory(
        name: name,
        slug: slug,
        description: description,
        imageUrl: imageUrl,
        isActive: isActive,
        sortOrder: sortOrder,
        image: image,
      );
      debugPrint('[CategoryController] createCategory success slug=$slug');
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[CategoryController] createCategory error: $e');
      errorMessage.value = 'Failed to create category. Please try again.';
      return (
        success: false,
        error: 'Failed to create category. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates an existing category identified by [id].
  ///
  /// Only non-null parameters are forwarded to the repository.
  /// If [name] or [customSlug] is supplied, a new slug is computed and
  /// validated for uniqueness (excluding the current document).
  ///
  /// Returns a record with `success` and optional `error`.
  Future<({bool success, String? error})> updateCategory({
    required String id,
    String? name,
    String? customSlug,
    String? description,
    String? imageUrl,
    bool? isActive,
    int? sortOrder,
    PickedCategoryImage? image,
    bool deleteImage = false,
  }) async {
    // Re-derive slug if the name or customSlug is changing.
    String? slug;
    if (customSlug != null || name != null) {
      final rawSlug = customSlug ?? name!;
      slug = SlugUtils.toSlug(rawSlug);

      if (slug.isEmpty) {
        return (
          success: false,
          error:
              'Category name must contain at least one alphanumeric character.',
        );
      }

      if (_slugExists(slug, excludeId: id)) {
        debugPrint(
          '[CategoryController] updateCategory duplicate slug rejected: $slug',
        );
        return (
          success: false,
          error: 'A category with the slug "$slug" already exists.',
        );
      }
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.updateCategory(
        id: id,
        name: name,
        slug: slug,
        description: description,
        imageUrl: imageUrl,
        isActive: isActive,
        sortOrder: sortOrder,
        image: image,
        deleteImage: deleteImage,
      );
      debugPrint('[CategoryController] updateCategory success id=$id');
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[CategoryController] updateCategory error: $e');
      errorMessage.value = 'Failed to update category. Please try again.';
      return (
        success: false,
        error: 'Failed to update category. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Permanently deletes the category identified by [id].
  ///
  /// Returns a record with `success` and optional `error`.
  ///
  /// Note: Future phases must add a product-dependency check before deletion
  /// is permitted. See [CategoryRepository.deleteCategory] for the TODO.
  Future<({bool success, String? error})> deleteCategory(String id) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.deleteCategory(id);
      debugPrint('[CategoryController] deleteCategory success id=$id');
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[CategoryController] deleteCategory error: $e');
      errorMessage.value = 'Failed to delete category. Please try again.';
      return (
        success: false,
        error: 'Failed to delete category. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggles the [isActive] flag on [category] to its opposite value.
  ///
  /// Delegates to [CategoryRepository.setCategoryActive] with the flipped
  /// boolean. The realtime stream automatically reflects the change in [categories].
  ///
  /// Returns a record with `success` and optional `error`.
  Future<({bool success, String? error})> toggleCategoryActive(
    CategoryModel category,
  ) async {
    final newValue = !category.isActive;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.setCategoryActive(category.id, isActive: newValue);
      debugPrint(
        '[CategoryController] toggleCategoryActive id=${category.id} → $newValue',
      );
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[CategoryController] toggleCategoryActive error: $e');
      errorMessage.value =
          'Failed to update category status. Please try again.';
      return (
        success: false,
        error: 'Failed to update category status. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
