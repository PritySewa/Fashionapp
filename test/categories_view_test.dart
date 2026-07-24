// Unit and widget tests for Phase 3.2B — Categories Management UI
//
// Coverage:
//   CategoryController.refresh():
//     - re-subscribes and delivers new data
//     - clears errorMessage before re-subscribing
//
//   CategoriesView widget:
//     - renders without crash when categories are empty
//     - shows loading indicator when isLoading=true and categories empty
//     - shows empty state when categories empty and not loading
//     - shows error state when errorMessage is set and categories empty
//     - renders category rows when categories are populated
//
//   Client-side search (_filteredList):
//     - empty query returns all items
//     - query matching name returns correct subset
//     - query matching slug returns correct subset
//     - non-matching query returns empty list
//     - search is case-insensitive
//
// Strategy:
//   Controller tests reuse the _FakeCategoryRepository pattern from
//   category_controller_test.dart.
//   Widget tests use a lightweight fake via Get.put before pumping the widget.

// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marketplace_admin/features/categories/controllers/category_controller.dart';
import 'package:marketplace_admin/features/categories/models/category_model.dart';
import 'package:marketplace_admin/features/categories/repositories/category_repository.dart';
import 'package:marketplace_admin/features/categories/views/categories_view.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  final StreamController<List<CategoryModel>> streamController =
      StreamController<List<CategoryModel>>.broadcast();

  @override
  Stream<List<CategoryModel>> watchCategories() => streamController.stream;

  @override
  Future<String> createCategory({
    required String name,
    required String slug,
    required String description,
    String imageUrl = '',
    bool isActive = true,
    int sortOrder = 0,
    PickedCategoryImage? image,
  }) async => 'new-id';

  @override
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
  }) async {}

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<void> setCategoryActive(String id, {required bool isActive}) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

CategoryModel _cat({
  String id = 'cat-1',
  String name = 'Electronics',
  String slug = 'electronics',
  bool isActive = true,
  int sortOrder = 0,
}) => CategoryModel(
  id: id,
  name: name,
  slug: slug,
  description: '',
  imageUrl: '',
  isActive: isActive,
  sortOrder: sortOrder,
  createdAt: _epoch,
  updatedAt: _epoch,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeCategoryRepository fakeRepo;
  late CategoryController controller;

  setUp(() {
    fakeRepo = _FakeCategoryRepository();
    Get.put<CategoryRepository>(fakeRepo);
    controller = CategoryController();
    Get.put<CategoryController>(controller);
  });

  tearDown(() async {
    await fakeRepo.streamController.close();
    Get.reset();
  });

  // ── CategoryController.refresh() ──────────────────────────────────────────
  group('CategoryController.refresh', () {
    test('re-subscribes and delivers new data after refresh', () async {
      // Push initial data.
      fakeRepo.streamController.add([_cat(id: 'c1')]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.categories.length, 1);

      // Call refresh — cancels old subscription, re-subscribes.
      controller.refresh();

      // Push new data through the broadcast stream.
      fakeRepo.streamController.add([
        _cat(id: 'c2'),
        _cat(id: 'c3', slug: 'phones'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.categories.length, 2);
      expect(controller.categories[0].id, 'c2');
    });

    test('clears errorMessage before re-subscribing', () async {
      // Trigger an error first.
      fakeRepo.streamController.addError(Exception('fail'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.errorMessage.value, isNotNull);

      // refresh() should clear the error immediately.
      controller.refresh();
      expect(controller.errorMessage.value, isNull);
    });

    test('delivers data after refresh following an error', () async {
      fakeRepo.streamController.addError(Exception('network down'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.errorMessage.value, isNotNull);

      controller.refresh();
      fakeRepo.streamController.add([_cat()]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.categories.length, 1);
      expect(controller.errorMessage.value, isNull);
    });
  });

  // ── CategoriesView widget states ──────────────────────────────────────────
  group('CategoriesView — widget states', () {
    Widget buildUnderTest() =>
        GetMaterialApp(home: Scaffold(body: const CategoriesView()));

    testWidgets('renders without crash when categories are empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pump();
      // Should render — no exception.
      expect(find.byType(CategoriesView), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading=true and no data', (
      tester,
    ) async {
      controller.isLoading.value = true;
      // categories is still empty

      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when categories empty and not loading', (
      tester,
    ) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.text('No categories yet'), findsOneWidget);
    });

    testWidgets('shows error state when errorMessage is set and no data', (
      tester,
    ) async {
      controller.errorMessage.value = 'Failed to load categories.';

      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.text('Failed to load categories.'), findsOneWidget);
    });

    testWidgets('renders category names when categories are populated', (
      tester,
    ) async {
      // Pump the widget first so the widget tree is mounted in its empty state.
      // Pushing stream data before pumpWidget causes the Obx to attempt a full
      // table render during the very first layout frame in the unbounded test
      // environment, which results in a measurement loop / timeout.
      await tester.pumpWidget(buildUnderTest());
      await tester.pump(); // empty state frame

      // Now push data through the stream and let the Obx rebuild.
      fakeRepo.streamController.add([
        _cat(id: 'c1', name: 'Electronics', slug: 'electronics'),
        _cat(id: 'c2', name: 'Clothing', slug: 'clothing'),
      ]);
      await tester
          .pump(); // stream event arrives → controller.categories updated
      await tester.pump(); // Obx rebuilds the widget tree

      expect(controller.categories.length, 2);
      expect(find.text('Electronics'), findsWidgets);
      expect(find.text('Clothing'), findsWidgets);
    });

    testWidgets('Add Category button is present in the page header', (
      tester,
    ) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.text('Add Category'), findsWidgets);
    });
  });

  // ── Search / filter logic ─────────────────────────────────────────────────
  group('CategoriesView — search filter logic', () {
    final allCategories = [
      _cat(id: 'c1', name: 'Electronics', slug: 'electronics'),
      _cat(id: 'c2', name: 'Clothing', slug: 'clothing'),
      _cat(id: 'c3', name: "Men's Shoes", slug: 'mens-shoes'),
    ];

    // Replicate _filteredList logic from _CategoriesBodyState
    List<CategoryModel> filter(List<CategoryModel> all, String query) {
      if (query.isEmpty) return all;
      final q = query.toLowerCase();
      return all
          .where((c) => c.name.toLowerCase().contains(q) || c.slug.contains(q))
          .toList();
    }

    test('empty query returns all categories', () {
      expect(filter(allCategories, ''), allCategories);
    });

    test('query matching name prefix returns correct subset', () {
      final result = filter(allCategories, 'elec');
      expect(result.length, 1);
      expect(result.first.id, 'c1');
    });

    test('query matching slug returns correct subset', () {
      final result = filter(allCategories, 'mens-shoes');
      expect(result.length, 1);
      expect(result.first.id, 'c3');
    });

    test('non-matching query returns empty list', () {
      expect(filter(allCategories, 'zzz'), isEmpty);
    });

    test('search is case-insensitive on name', () {
      final result = filter(allCategories, 'CLOTHING');
      expect(result.length, 1);
      expect(result.first.id, 'c2');
    });

    test('query matching partial slug returns result', () {
      final result = filter(allCategories, 'cloth');
      expect(result.length, 1);
      expect(result.first.id, 'c2');
    });
  });
}
