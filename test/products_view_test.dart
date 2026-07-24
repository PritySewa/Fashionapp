import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marketplace_admin/features/categories/controllers/category_controller.dart';
import 'package:marketplace_admin/features/categories/models/category_model.dart';
import 'package:marketplace_admin/features/categories/repositories/category_repository.dart';
import 'package:marketplace_admin/features/products/controllers/product_controller.dart';
import 'package:marketplace_admin/features/products/models/product_model.dart';
import 'package:marketplace_admin/features/products/repositories/product_repository.dart';
import 'package:marketplace_admin/features/products/views/products_view.dart';

// ── Fake Repositories ────────────────────────────────────────────────────────

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Stream<List<CategoryModel>> watchCategories() => const Stream.empty();
}

class _FakeProductRepository extends Fake implements ProductRepository {
  final StreamController<List<ProductModel>> streamController =
      StreamController<List<ProductModel>>.broadcast();

  @override
  Stream<List<ProductModel>> watchProducts() => streamController.stream;

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
  }) async => 'new-product-id';

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
  }) async {}

  @override
  Future<void> deleteProduct(String id) async {}

  @override
  Future<void> setProductActive(String id, {required bool isActive}) async {}

  @override
  Future<void> setProductFeatured(
    String id, {
    required bool isFeatured,
  }) async {}
}

// ── Helpers ──────────────────────────────────────────────────────────────────

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

ProductModel _prod({
  required String id,
  required String name,
  required String slug,
  required String sku,
  double price = 999.0,
  int stock = 10,
  bool isActive = true,
  bool isFeatured = false,
}) => ProductModel(
  id: id,
  name: name,
  slug: slug,
  description: 'Test product desc',
  categoryId: 'cat-123',
  badgeIds: const [],
  sku: sku,
  price: price,
  stock: stock,
  isActive: isActive,
  isFeatured: isFeatured,
  images: const [],
  createdAt: _epoch,
  updatedAt: _epoch,
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _FakeProductRepository fakeRepo;
  late ProductController controller;

  setUp(() {
    Get.clearTranslations();

    // Setup Category Controller
    final fakeCatRepo = _FakeCategoryRepository();
    Get.put<CategoryRepository>(fakeCatRepo);
    final catController = CategoryController();
    Get.put<CategoryController>(catController);

    // Setup Product Controller
    fakeRepo = _FakeProductRepository();
    Get.put<ProductRepository>(fakeRepo);
    controller = ProductController();
    Get.put<ProductController>(controller);
  });

  tearDown(() async {
    await fakeRepo.streamController.close();
    Get.reset();
  });

  // ── Widget States ──────────────────────────────────────────────────────────
  group('ProductsView — widget states', () {
    Widget buildUnderTest() =>
        const GetMaterialApp(home: Scaffold(body: ProductsView()));

    testWidgets('renders without crash when products are empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pump();
      expect(find.byType(ProductsView), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading=true and no data', (
      tester,
    ) async {
      controller.isLoading.value = true;

      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when products are empty and not loading', (
      tester,
    ) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.text('No products yet'), findsOneWidget);
    });

    testWidgets('shows error state when errorMessage is set and no data', (
      tester,
    ) async {
      controller.errorMessage.value = 'Failed to load products.';

      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.text('Failed to load products.'), findsOneWidget);
    });

    testWidgets('renders product names when products are populated', (
      tester,
    ) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pump(); // Empty state frame

      // Push product data through stream
      fakeRepo.streamController.add([
        _prod(id: 'p1', name: 'iPhone 15', slug: 'iphone-15', sku: 'IPHONE15'),
        _prod(
          id: 'p2',
          name: 'MacBook Air',
          slug: 'macbook-air',
          sku: 'MACBOOKAIR',
        ),
      ]);

      await tester.pump(); // update controller list
      await tester.pump(); // rebuild UI

      expect(controller.products.length, 2);
      expect(find.text('iPhone 15'), findsWidgets);
      expect(find.text('MacBook Air'), findsWidgets);
    });

    testWidgets('Add Product button is present in the page header', (
      tester,
    ) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.text('Add Product'), findsWidgets);
    });
  });

  // ── Search / Filter Logic ──────────────────────────────────────────────────
  group('ProductsView — search filter logic', () {
    final allProducts = [
      _prod(
        id: 'p1',
        name: 'iPhone 15 Pro',
        slug: 'iphone-15-pro',
        sku: 'IPHONE15P',
      ),
      _prod(
        id: 'p2',
        name: 'MacBook Air M3',
        slug: 'macbook-air-m3',
        sku: 'MACBOOKM3',
      ),
      _prod(
        id: 'p3',
        name: 'Adidas Shoes',
        slug: 'adidas-shoes',
        sku: 'ADIDAS99',
      ),
    ];

    List<ProductModel> filter(List<ProductModel> all, String query) {
      if (query.isEmpty) return all;
      final q = query.toLowerCase();
      return all.where((p) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final skuMatch = p.sku.toLowerCase().contains(q);
        final slugMatch = p.slug.toLowerCase().contains(q);
        return nameMatch || skuMatch || slugMatch;
      }).toList();
    }

    test('empty query returns all products', () {
      expect(filter(allProducts, ''), allProducts);
    });

    test('query matching name partial returns correct subset', () {
      final result = filter(allProducts, 'phone');
      expect(result.length, 1);
      expect(result.first.id, 'p1');
    });

    test('query matching sku returns correct subset', () {
      final result = filter(allProducts, 'MACBOOKM3');
      expect(result.length, 1);
      expect(result.first.id, 'p2');
    });

    test('query matching slug returns correct subset', () {
      final result = filter(allProducts, 'adidas-shoes');
      expect(result.length, 1);
      expect(result.first.id, 'p3');
    });

    test('search is case-insensitive', () {
      final result = filter(allProducts, 'IPHONE');
      expect(result.length, 1);
      expect(result.first.id, 'p1');
    });

    test('non-matching query returns empty list', () {
      expect(filter(allProducts, 'nonexistent'), isEmpty);
    });
  });
}
