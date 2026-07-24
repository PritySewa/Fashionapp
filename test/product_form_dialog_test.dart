import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marketplace_admin/features/badges/controllers/badge_controller.dart';
import 'package:marketplace_admin/features/badges/models/badge_model.dart';
import 'package:marketplace_admin/features/badges/repositories/badge_repository.dart';
import 'package:marketplace_admin/features/categories/controllers/category_controller.dart';
import 'package:marketplace_admin/features/categories/models/category_model.dart';
import 'package:marketplace_admin/features/categories/repositories/category_repository.dart';
import 'package:marketplace_admin/features/products/controllers/product_controller.dart';
import 'package:marketplace_admin/features/products/models/product_model.dart';
import 'package:marketplace_admin/features/products/repositories/product_repository.dart';
import 'package:marketplace_admin/features/products/widgets/product_form_dialog.dart';

// ── Fake Repositories ────────────────────────────────────────────────────────

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  final StreamController<List<CategoryModel>> streamController =
      StreamController<List<CategoryModel>>.broadcast();

  @override
  Stream<List<CategoryModel>> watchCategories() => streamController.stream;

  @override
  Future<CategoryModel?> getCategory(String id) async {
    return CategoryModel(
      id: id,
      name: 'Test Category',
      slug: 'test-category',
      description: '',
      imageUrl: '',
      isActive: true,
      sortOrder: 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class _FakeBadgeRepository extends Fake implements BadgeRepository {
  final StreamController<List<BadgeModel>> streamController =
      StreamController<List<BadgeModel>>.broadcast();

  @override
  Stream<List<BadgeModel>> watchBadges() => streamController.stream;

  @override
  Future<BadgeModel?> getBadge(String id) async {
    return BadgeModel(
      id: id,
      name: 'Test Badge',
      slug: 'test-badge',
      color: '#FF0000',
      icon: 'star',
      isActive: true,
      sortOrder: 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
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
}

// ── Helpers ──────────────────────────────────────────────────────────────────

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

CategoryModel _cat({
  required String id,
  required String name,
  required String slug,
  bool isActive = true,
}) => CategoryModel(
  id: id,
  name: name,
  slug: slug,
  description: '',
  imageUrl: '',
  isActive: isActive,
  sortOrder: 0,
  createdAt: _epoch,
  updatedAt: _epoch,
);

ProductModel _prod({
  required String id,
  required String name,
  required String slug,
  required String sku,
  double price = 99.0,
  int stock = 5,
  bool isActive = true,
}) => ProductModel(
  id: id,
  name: name,
  slug: slug,
  description: 'Test product description',
  categoryId: 'cat-123',
  badgeIds: const [],
  sku: sku,
  price: price,
  stock: stock,
  isActive: isActive,
  isFeatured: false,
  images: const [],
  createdAt: _epoch,
  updatedAt: _epoch,
);

void main() {
  late _FakeCategoryRepository fakeCatRepo;
  late _FakeBadgeRepository fakeBadgeRepo;
  late _FakeProductRepository fakeProdRepo;

  late CategoryController catController;
  late BadgeController badgeController;
  late ProductController prodController;

  setUp(() {
    Get.clearTranslations();

    fakeCatRepo = _FakeCategoryRepository();
    Get.put<CategoryRepository>(fakeCatRepo);
    catController = CategoryController();
    Get.put<CategoryController>(catController);

    fakeBadgeRepo = _FakeBadgeRepository();
    Get.put<BadgeRepository>(fakeBadgeRepo);
    badgeController = BadgeController();
    Get.put<BadgeController>(badgeController);

    fakeProdRepo = _FakeProductRepository();
    Get.put<ProductRepository>(fakeProdRepo);
    prodController = ProductController();
    Get.put<ProductController>(prodController);
  });

  tearDown(() async {
    await fakeCatRepo.streamController.close();
    await fakeBadgeRepo.streamController.close();
    await fakeProdRepo.streamController.close();
    Get.reset();
  });

  group('ProductFormDialog — UI and validations', () {
    Widget buildUnderTest({ProductModel? product}) {
      return GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () =>
                    ProductFormDialog.show(context, product: product),
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );
    }

    testWidgets('renders in Add Mode (blank form)', (tester) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Product'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, ''), findsAtLeastNWidgets(6));
    });

    testWidgets('renders in Edit Mode (prefilled values)', (tester) async {
      final product = _prod(
        id: 'p1',
        name: 'iPhone 15 Pro',
        slug: 'iphone-15-pro',
        sku: 'IPH15P',
      );

      await tester.pumpWidget(buildUnderTest(product: product));
      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Product'), findsOneWidget);
      expect(find.text('iPhone 15 Pro'), findsOneWidget);
      expect(find.text('IPH15P'), findsOneWidget);
    });

    testWidgets('shows validation errors for required fields', (tester) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Create button to trigger validation
      await tester.tap(find.text('Create Product'));
      await tester.pump();

      expect(find.text('Product name is required.'), findsOneWidget);
      expect(find.text('Description is required.'), findsOneWidget);
      expect(find.text('Category is required.'), findsOneWidget);
      expect(find.text('Price is required.'), findsOneWidget);
      expect(find.text('SKU is required.'), findsOneWidget);
      expect(find.text('Stock is required.'), findsOneWidget);
    });

    testWidgets('validates price and stock inputs correctly', (tester) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Fill in Name, Desc
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'e.g. Wireless Bluetooth Headphones',
        ),
        'Invalid Price Test',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Provide a detailed description of the product',
        ),
        'Desc goes here',
      );

      // Populate Category list and select one
      fakeCatRepo.streamController.add([
        _cat(id: 'cat1', name: 'Accessories', slug: 'accessories'),
      ]);
      await tester.pump();

      final categoryDropdown = find.text('Select category');
      await tester.ensureVisible(categoryDropdown);
      await tester.tap(categoryDropdown, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accessories').last);
      await tester.pumpAndSettle();

      // Price input invalid (like a dot)
      final priceField = find.widgetWithText(TextFormField, '0.00');
      await tester.ensureVisible(priceField);
      await tester.enterText(priceField, '.');

      // Stock input empty (digitsOnly filters invalid chars)
      final stockField = find.widgetWithText(TextFormField, '0');
      await tester.ensureVisible(stockField);
      await tester.enterText(stockField, '');

      final submitBtn = find.text('Create Product');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(find.text('Must be >= 0.'), findsOneWidget);
      expect(find.text('Stock is required.'), findsOneWidget);
    });

    testWidgets('validates comparePrice >= price', (tester) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Set Price to 100
      final priceField = find.widgetWithText(TextFormField, '0.00');
      await tester.ensureVisible(priceField);
      await tester.enterText(priceField, '100.0');

      // Set Compare Price to 50 (invalid, must be >= price)
      final comparePriceField = find.widgetWithText(
        TextFormField,
        'Optional — e.g. 1299',
      );
      await tester.ensureVisible(comparePriceField);
      await tester.enterText(comparePriceField, '50.0');

      final submitBtn = find.text('Create Product');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(find.text('Must be >= selling price.'), findsOneWidget);
    });

    testWidgets('validates SKU uniqueness', (tester) async {
      // Add existing product to controller
      prodController.products.add(
        _prod(id: 'p1', name: 'Product A', slug: 'product-a', sku: 'DUPLICATE'),
      );

      await tester.pumpWidget(buildUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter duplicate SKU
      final skuField = find.widgetWithText(TextFormField, 'e.g. WH-1000XM4');
      await tester.ensureVisible(skuField);
      await tester.enterText(skuField, 'duplicate'); // case insensitive

      final submitBtn = find.text('Create Product');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(find.text('SKU must be unique.'), findsOneWidget);
    });
  });
}
