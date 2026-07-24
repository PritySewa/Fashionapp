// Unit tests for ProductController — Phase 3.4A

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marketplace_admin/features/products/controllers/product_controller.dart';
import 'package:marketplace_admin/features/products/models/product_model.dart';
import 'package:marketplace_admin/features/products/repositories/product_repository.dart';

// ── Fake ProductRepository ───────────────────────────────────────────────────

class _FakeProductRepository extends Fake implements ProductRepository {
  final StreamController<List<ProductModel>> streamController =
      StreamController<List<ProductModel>>.broadcast();

  bool watchCalled = false;
  bool getProductCalled = false;
  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;
  bool setActiveCalled = false;
  bool setFeaturedCalled = false;

  bool? lastSetActiveValue;
  bool? lastSetFeaturedValue;
  String? lastDeletedId;

  bool throwOnCreate = false;
  bool throwOnUpdate = false;
  bool throwOnDelete = false;
  bool throwOnSetActive = false;
  bool throwOnSetFeatured = false;

  @override
  Stream<List<ProductModel>> watchProducts() {
    watchCalled = true;
    return streamController.stream;
  }

  @override
  Future<ProductModel?> getProduct(String id) async {
    getProductCalled = true;
    return null;
  }

  @override
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
    required List<PickedProductImage> images,
    PickedThumbnail? thumbnail,
  }) async {
    createCalled = true;
    if (throwOnCreate) {
      throw ArgumentError('Referenced category does not exist.');
    }
    return 'new-fake-id';
  }

  @override
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
    updateCalled = true;
    if (throwOnUpdate) {
      throw Exception('Firestore update failed');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    deleteCalled = true;
    lastDeletedId = id;
    if (throwOnDelete) {
      throw Exception('Firestore delete failed');
    }
  }

  @override
  Future<void> setProductActive(String id, {required bool isActive}) async {
    setActiveCalled = true;
    lastSetActiveValue = isActive;
    if (throwOnSetActive) {
      throw Exception('Firestore setActive failed');
    }
  }

  @override
  Future<void> setProductFeatured(String id, {required bool isFeatured}) async {
    setFeaturedCalled = true;
    lastSetFeaturedValue = isFeatured;
    if (throwOnSetFeatured) {
      throw Exception('Firestore setFeatured failed');
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProductModel _mockProduct({
  required String id,
  required String name,
  required String slug,
  double price = 9.99,
  bool isActive = true,
  bool isFeatured = false,
}) => ProductModel(
  id: id,
  name: name,
  slug: slug,
  description: 'Desc',
  categoryId: 'cat-123',
  badgeIds: const [],
  sku: 'SKU-$id',
  price: price,
  stock: 10,
  isActive: isActive,
  isFeatured: isFeatured,
  images: const [],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

void main() {
  late _FakeProductRepository fakeRepo;
  late ProductController controller;

  setUp(() {
    Get.clearTranslations();
    fakeRepo = _FakeProductRepository();
    Get.put<ProductRepository>(fakeRepo);
    controller = ProductController();
    Get.put<ProductController>(controller);
  });

  tearDown(() async {
    await fakeRepo.streamController.close();
    Get.reset();
  });

  group('ProductController', () {
    test('initial state is correct', () {
      expect(controller.products, isEmpty);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNull);
      expect(fakeRepo.watchCalled, isTrue);
    });

    test('stream emissions update reactive products list', () async {
      final list = [
        _mockProduct(id: 'p1', name: 'Product A', slug: 'product-a'),
        _mockProduct(id: 'p2', name: 'Product B', slug: 'product-b'),
      ];

      fakeRepo.streamController.add(list);
      await Future.delayed(Duration.zero);

      expect(controller.products.length, 2);
      expect(controller.products[0].name, 'Product A');
      expect(controller.products[1].name, 'Product B');
      expect(controller.errorMessage.value, isNull);
    });

    test('stream errors populate errorMessage', () async {
      fakeRepo.streamController.addError('Network error');
      await Future.delayed(Duration.zero);

      expect(controller.products, isEmpty);
      expect(
        controller.errorMessage.value,
        contains('Failed to load products'),
      );
    });

    test(
      'createProduct with valid unique slug delegates to repository',
      () async {
        final result = await controller.createProduct(
          name: 'Unique Product',
          description: 'New product description',
          categoryId: 'cat-001',
          badgeIds: const [],
          sku: 'NEW-SKU',
          price: 49.99,
          stock: 5,
          images: const [],
        );

        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(fakeRepo.createCalled, isTrue);
        expect(controller.isLoading.value, isFalse);
      },
    );

    test(
      'createProduct with duplicate slug is rejected without database call',
      () async {
        // Set up in-memory duplicates
        controller.products.assignAll([
          _mockProduct(id: 'p1', name: 'Existing', slug: 'existing'),
        ]);

        final result = await controller.createProduct(
          name: 'Existing',
          description: 'Desc',
          categoryId: 'cat-001',
          badgeIds: const [],
          sku: 'SKU',
          price: 1.0,
          stock: 1,
          images: const [],
        );

        expect(result.success, isFalse);
        expect(result.error, contains('already exists'));
        expect(fakeRepo.createCalled, isFalse);
      },
    );

    test(
      'createProduct with empty-slug name is rejected without database call',
      () async {
        final result = await controller.createProduct(
          name: '  ',
          description: 'Desc',
          categoryId: 'cat-001',
          badgeIds: const [],
          sku: 'SKU',
          price: 1.0,
          stock: 1,
          images: const [],
        );

        expect(result.success, isFalse);
        expect(
          result.error,
          contains('must contain at least one alphanumeric character'),
        );
        expect(fakeRepo.createCalled, isFalse);
      },
    );

    test('createProduct repository exception returns failure record', () async {
      fakeRepo.throwOnCreate = true;

      final result = await controller.createProduct(
        name: 'Throwing Product',
        description: 'Desc',
        categoryId: 'invalid-cat',
        badgeIds: const [],
        sku: 'SKU',
        price: 1.0,
        stock: 1,
        images: const [],
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Referenced category does not exist'));
      expect(
        controller.errorMessage.value,
        contains('Referenced category does not exist'),
      );
    });

    test('updateProduct with valid slug delegates to repository', () async {
      final result = await controller.updateProduct(
        id: 'p1',
        name: 'Updated Product name',
      );

      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(fakeRepo.updateCalled, isTrue);
    });

    test(
      'updateProduct with duplicate slug is rejected without database call',
      () async {
        controller.products.assignAll([
          _mockProduct(id: 'p1', name: 'Apple', slug: 'apple'),
          _mockProduct(id: 'p2', name: 'Banana', slug: 'banana'),
        ]);

        final result = await controller.updateProduct(
          id: 'p2', // Banana
          customSlug: 'apple', // Rename to Apple (which exists at p1)
        );

        expect(result.success, isFalse);
        expect(result.error, contains('already exists'));
        expect(fakeRepo.updateCalled, isFalse);
      },
    );

    test('deleteProduct delegates to repository', () async {
      final result = await controller.deleteProduct('p123');

      expect(result.success, isTrue);
      expect(fakeRepo.deleteCalled, isTrue);
      expect(fakeRepo.lastDeletedId, 'p123');
    });

    test('toggleProductActive calls repository with flipped value', () async {
      final prod = _mockProduct(id: 'p1', name: 'A', slug: 'a', isActive: true);

      final result = await controller.toggleProductActive(prod);

      expect(result.success, isTrue);
      expect(fakeRepo.setActiveCalled, isTrue);
      expect(fakeRepo.lastSetActiveValue, isFalse);
    });

    test('toggleProductFeatured calls repository with flipped value', () async {
      final prod = _mockProduct(
        id: 'p1',
        name: 'A',
        slug: 'a',
        isFeatured: false,
      );

      final result = await controller.toggleProductFeatured(prod);

      expect(result.success, isTrue);
      expect(fakeRepo.setFeaturedCalled, isTrue);
      expect(fakeRepo.lastSetFeaturedValue, isTrue);
    });

    test('refresh resets subscription and error states', () async {
      controller.errorMessage.value = 'Existing error';
      controller.refresh();

      expect(controller.errorMessage.value, isNull);
    });
  });
}
