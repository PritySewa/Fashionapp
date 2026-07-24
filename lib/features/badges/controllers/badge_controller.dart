import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/utils/slug_utils.dart';
import '../models/badge_model.dart';
import '../repositories/badge_repository.dart';

/// GetX controller for the Badges feature.
///
/// ## Responsibilities
///
/// - Subscribe to [BadgeRepository.watchBadges] and expose the realtime list
///   as [badges].
/// - Expose [isLoading] and [errorMessage] reactive state for the UI.
/// - Provide create, update, delete, and toggle-active actions.
/// - Enforce slug uniqueness in-memory (no extra Firestore reads).
/// - Cancel the Firestore stream subscription when disposed.
///
/// ## What this controller does NOT do
///
/// - Access [FirebaseFirestore] directly — all Firestore calls go through
///   [BadgeRepository].
/// - Contain widget code, dialog code, or snackbar UI code.
///   UI feedback is the responsibility of views.
/// - Perform duplicate slug checks via an extra Firestore query.
///   The in-memory [badges] list is used for instant, cheap validation.
///
/// ## Lifecycle
///
/// Registered via [DashboardBinding.lazyPut]. When GetX disposes this
/// controller (e.g. on route pop), [onClose] cancels [_badgeSubscription]
/// so the Firestore stream does not leak.
class BadgeController extends GetxController {
  // ── Dependencies ────────────────────────────────────────────────────────────

  final BadgeRepository _repository = Get.find<BadgeRepository>();

  // ── Reactive state ──────────────────────────────────────────────────────────

  /// The live list of badges, updated automatically by the Firestore stream.
  final RxList<BadgeModel> badges = <BadgeModel>[].obs;

  /// True while an async create / update / delete operation is in flight.
  final RxBool isLoading = false.obs;

  /// Non-null when the most recent action or stream event produced an error.
  final RxnString errorMessage = RxnString();

  // ── Stream subscription ─────────────────────────────────────────────────────

  StreamSubscription<List<BadgeModel>>? _badgeSubscription;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _subscribeToBadges();
  }

  @override
  void onClose() {
    _badgeSubscription?.cancel();
    _badgeSubscription = null;
    super.onClose();
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  void _subscribeToBadges() {
    _badgeSubscription = _repository.watchBadges().listen(
      (list) {
        badges.assignAll(list);
        errorMessage.value = null;
        debugPrint('[BadgeController] stream update — ${list.length} badges');
      },
      onError: (Object error, StackTrace st) {
        debugPrint('[BadgeController] stream error: $error');
        debugPrint('[BadgeController] StackTrace: $st');
        errorMessage.value =
            'Failed to load badges. Please check your connection.';
      },
    );
  }

  /// Cancels and re-subscribes the Firestore stream.
  ///
  /// Called by [BadgesView] when the user taps "Retry" in the error state.
  @override
  void refresh() {
    _badgeSubscription?.cancel();
    _badgeSubscription = null;
    errorMessage.value = null;
    _subscribeToBadges();
  }

  /// Returns true if a badge with [slug] already exists in the in-memory
  /// [badges] list, optionally excluding [excludeId] (used when updating).
  bool _slugExists(String slug, {String? excludeId}) {
    return badges.any((b) => b.slug == slug && b.id != excludeId);
  }

  // ── Public actions ──────────────────────────────────────────────────────────

  /// Creates a new badge after validating slug uniqueness.
  ///
  /// Returns a record:
  /// - `success: true` and `error: null` on success.
  /// - `success: false` and a non-null human-readable `error` on failure.
  ///
  /// The slug is auto-generated from [name] via [SlugUtils.toSlug].
  /// If [customSlug] is supplied it is used instead (after normalisation).
  Future<({bool success, String? error})> createBadge({
    required String name,
    String? customSlug,
    String color = '',
    String icon = '',
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    final slug = SlugUtils.toSlug(customSlug ?? name);

    if (slug.isEmpty) {
      return (
        success: false,
        error: 'Badge name must contain at least one alphanumeric character.',
      );
    }

    if (_slugExists(slug)) {
      debugPrint('[BadgeController] duplicate slug rejected: $slug');
      return (
        success: false,
        error:
            'A badge with the slug "$slug" already exists. '
            'Please choose a different name.',
      );
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.createBadge(
        name: name,
        slug: slug,
        color: color,
        icon: icon,
        isActive: isActive,
        sortOrder: sortOrder,
      );
      debugPrint('[BadgeController] createBadge success slug=$slug');
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[BadgeController] createBadge error: $e');
      errorMessage.value = 'Failed to create badge. Please try again.';
      return (
        success: false,
        error: 'Failed to create badge. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates an existing badge identified by [id].
  ///
  /// Only non-null parameters are forwarded to the repository.
  /// If [name] or [customSlug] is supplied, a new slug is computed and
  /// validated for uniqueness (excluding the current document).
  ///
  /// Returns a record with `success` and optional `error`.
  Future<({bool success, String? error})> updateBadge({
    required String id,
    String? name,
    String? customSlug,
    String? color,
    String? icon,
    bool? isActive,
    int? sortOrder,
  }) async {
    String? slug;
    if (customSlug != null || name != null) {
      final rawSlug = customSlug ?? name!;
      slug = SlugUtils.toSlug(rawSlug);

      if (slug.isEmpty) {
        return (
          success: false,
          error: 'Badge name must contain at least one alphanumeric character.',
        );
      }

      if (_slugExists(slug, excludeId: id)) {
        debugPrint(
          '[BadgeController] updateBadge duplicate slug rejected: $slug',
        );
        return (
          success: false,
          error: 'A badge with the slug "$slug" already exists.',
        );
      }
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.updateBadge(
        id: id,
        name: name,
        slug: slug,
        color: color,
        icon: icon,
        isActive: isActive,
        sortOrder: sortOrder,
      );
      debugPrint('[BadgeController] updateBadge success id=$id');
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[BadgeController] updateBadge error: $e');
      errorMessage.value = 'Failed to update badge. Please try again.';
      return (
        success: false,
        error: 'Failed to update badge. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Permanently deletes the badge identified by [id].
  ///
  /// Returns a record with `success` and optional `error`.
  Future<({bool success, String? error})> deleteBadge(String id) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.deleteBadge(id);
      debugPrint('[BadgeController] deleteBadge success id=$id');
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[BadgeController] deleteBadge error: $e');
      errorMessage.value = 'Failed to delete badge. Please try again.';
      return (
        success: false,
        error: 'Failed to delete badge. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggles the [isActive] flag on [badge] to its opposite value.
  ///
  /// Delegates to [BadgeRepository.setBadgeActive] with the flipped boolean.
  /// The realtime stream automatically reflects the change in [badges].
  ///
  /// Returns a record with `success` and optional `error`.
  Future<({bool success, String? error})> toggleBadgeActive(
    BadgeModel badge,
  ) async {
    final newValue = !badge.isActive;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.setBadgeActive(badge.id, isActive: newValue);
      debugPrint(
        '[BadgeController] toggleBadgeActive id=${badge.id} → $newValue',
      );
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[BadgeController] toggleBadgeActive error: $e');
      errorMessage.value = 'Failed to update badge status. Please try again.';
      return (
        success: false,
        error: 'Failed to update badge status. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
