import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/banner_model.dart';
import '../repositories/banner_repository.dart';

/// GetX controller for the Banner Management feature.
class BannerController extends GetxController {
  final BannerRepository _repository = Get.find<BannerRepository>();

  final RxList<BannerModel> banners = <BannerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<List<BannerModel>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscribeToBanners();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _subscription = null;
    super.onClose();
  }

  void _subscribeToBanners() {
    _subscription = _repository.watchBanners().listen(
      (list) {
        banners.assignAll(list);
        errorMessage.value = null;
        debugPrint('[BannerController] stream update — ${list.length} banners');
      },
      onError: (Object error, StackTrace st) {
        debugPrint('[BannerController] stream error: $error');
        errorMessage.value = 'Failed to load banners. Please check connection.';
      },
    );
  }

  @override
  void refresh() {
    _subscription?.cancel();
    _subscription = null;
    errorMessage.value = null;
    _subscribeToBanners();
  }

  Future<({bool success, String? error})> createBanner({
    required String title,
    required String subtitle,
    required PickedBannerImage image,
    required BannerTargetType targetType,
    String? targetId,
    String? externalUrl,
    required int displayOrder,
    bool isActive = true,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.createBanner(
        title: title,
        subtitle: subtitle,
        image: image,
        targetType: targetType,
        targetId: targetId,
        externalUrl: externalUrl,
        displayOrder: displayOrder,
        isActive: isActive,
      );
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[BannerController] createBanner error: $e');
      final msg = 'Failed to create banner. Please try again.';
      errorMessage.value = msg;
      return (success: false, error: msg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<({bool success, String? error})> updateBanner({
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
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.updateBanner(
        id: id,
        title: title,
        subtitle: subtitle,
        image: image,
        targetType: targetType,
        targetId: targetId,
        clearTargetId: clearTargetId,
        externalUrl: externalUrl,
        clearExternalUrl: clearExternalUrl,
        displayOrder: displayOrder,
        isActive: isActive,
      );
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[BannerController] updateBanner error: $e');
      final msg = 'Failed to update banner. Please try again.';
      errorMessage.value = msg;
      return (success: false, error: msg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<({bool success, String? error})> toggleActive(BannerModel banner) async {
    final newValue = !banner.isActive;
    isLoading.value = true;

    try {
      await _repository.toggleBannerActive(banner.id, isActive: newValue);
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[BannerController] toggleActive error: $e');
      return (success: false, error: 'Failed to update banner status.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<({bool success, String? error})> deleteBanner(String id) async {
    isLoading.value = true;

    try {
      await _repository.deleteBanner(id);
      return (success: true, error: null);
    } catch (e) {
      debugPrint('[BannerController] deleteBanner error: $e');
      return (success: false, error: 'Failed to delete banner.');
    } finally {
      isLoading.value = false;
    }
  }
}
