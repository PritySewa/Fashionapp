import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/review_model.dart';
import '../repositories/review_repository.dart';

/// GetX controller for the Review Moderation feature.
class ReviewController extends GetxController {
  final ReviewRepository _repository = Get.find<ReviewRepository>();

  final RxList<ReviewModel> reviews = <ReviewModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<List<ReviewModel>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscribeToReviews();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _subscription = null;
    super.onClose();
  }

  void _subscribeToReviews() {
    _subscription = _repository.watchReviews().listen(
      (list) {
        reviews.assignAll(list);
        errorMessage.value = null;
        debugPrint('[ReviewController] stream update — ${list.length} reviews');
      },
      onError: (Object error, StackTrace st) {
        debugPrint('[ReviewController] stream error: $error');
        errorMessage.value = 'Failed to load reviews. Please check connection.';
      },
    );
  }

  @override
  void refresh() {
    _subscription?.cancel();
    _subscription = null;
    errorMessage.value = null;
    _subscribeToReviews();
  }

  Future<({bool success, String? error})> updateStatus(
    String id,
    ReviewStatus status,
  ) async {
    isLoading.value = true;
    try {
      await _repository.updateReviewStatus(id, status);
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[ReviewController] updateStatus error: $e');
      return (success: false, error: 'Failed to update review status.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<({bool success, String? error})> deleteReview(String id) async {
    isLoading.value = true;
    try {
      await _repository.deleteReview(id);
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[ReviewController] deleteReview error: $e');
      return (success: false, error: 'Failed to delete review.');
    } finally {
      isLoading.value = false;
    }
  }
}
