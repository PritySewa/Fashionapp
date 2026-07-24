// Unit tests for CategoryController — Phase 3.2A
//
// Coverage:
//   - Initial state: categories empty, isLoading false, errorMessage null
//   - Stream emits a list → categories updated
//   - Stream emits error → errorMessage set
//   - createCategory with unique slug delegates to repository, returns success
//   - createCategory with duplicate slug is rejected, repository NOT called
//   - createCategory with empty-slug input is rejected, repository NOT called
//   - updateCategory delegates to repository, returns success
//   - updateCategory with duplicate slug is rejected
//   - deleteCategory delegates to repository, returns success
//   - toggleCategoryActive calls setCategoryActive with flipped value
//   - repository error on create → returns failure record, errorMessage set
//   - repository error on delete → returns failure record, errorMessage set
//   - onClose cancels the stream (no further updates after disposal)
//
// ## Testing strategy
//
// CategoryController uses Get.find<CategoryRepository>() in onInit().
// We register a _FakeCategoryRepository before creating the controller,
// so the real Firestore/Firebase SDK is never initialised.
//
// A StreamController<List<CategoryModel>> is used to simulate Firestore's
// realtime stream — we push events into it and assert that categories updates.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marketplace_admin/features/categories/controllers/category_controller.dart';
import 'package:marketplace_admin/features/categories/models/category_model.dart';
import 'package:marketplace_admin/features/categories/repositories/category_repository.dart';

// ── Fake CategoryRepository ───────────────────────────────────────────────────

/// Stub repository that drives tests without touching Firebase.
///
/// [_streamController] lets individual tests push list events or errors into
/// the stream that [CategoryController] subscribes to.
///
/// [createCalled], [updateCalled], [deleteCalled], [setActiveCalled] track
/// whether the corresponding method was invoked — enabling delegation tests.
class _FakeCategoryRepository extends Fake implements CategoryRepository {
  /// Tests may replace this to emit events or errors on demand.
  final StreamController<List<CategoryModel>> streamController =
      StreamController<List<CategoryModel>>.broadcast();

  // ── Call tracking ──────────────────────────────────────────────────────────
  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;
  bool setActiveCalled = false;
  bool? lastSetActiveValue;
  String? lastDeletedId;

  // ── Configurable error injection ──────────────────────────────────────────
  bool throwOnCreate = false;
  bool throwOnUpdate = false;
  bool throwOnDelete = false;
  bool throwOnSetActive = false;

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
  }) async {
    createCalled = true;
    if (throwOnCreate) throw Exception('Firestore create failed');
    return 'new-fake-id';
  }

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
  }) async {
    updateCalled = true;
    if (throwOnUpdate) throw Exception('Firestore update failed');
  }

  @override
  Future<void> deleteCategory(String id) async {
    deleteCalled = true;
    lastDeletedId = id;
    if (throwOnDelete) throw Exception('Firestore delete failed');
  }

  @override
  Future<void> setCategoryActive(String id, {required bool isActive}) async {
    setActiveCalled = true;
    lastSetActiveValue = isActive;
    if (throwOnSetActive) throw Exception('Firestore setActive failed');
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _now = DateTime(2024, 6, 15);
final _later = DateTime(2024, 6, 20);

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
  createdAt: _now,
  updatedAt: _later,
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

  // ── Initial state ─────────────────────────────────────────────────────────
  group('CategoryController — initial state', () {
    test('categories is empty on init', () {
      expect(controller.categories, isEmpty);
    });

    test('isLoading is false on init', () {
      expect(controller.isLoading.value, isFalse);
    });

    test('errorMessage is null on init', () {
      expect(controller.errorMessage.value, isNull);
    });
  });

  // ── Stream updates ────────────────────────────────────────────────────────
  group('CategoryController — stream updates', () {
    test('stream emitting a list updates categories', () async {
      final list = [_cat(id: 'c1'), _cat(id: 'c2', slug: 'phones')];
      fakeRepo.streamController.add(list);
      await Future<void>.delayed(Duration.zero);

      expect(controller.categories.length, 2);
      expect(controller.categories[0].id, 'c1');
      expect(controller.categories[1].id, 'c2');
    });

    test('stream emitting an empty list clears categories', () async {
      // First populate
      fakeRepo.streamController.add([_cat()]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.categories.length, 1);

      // Then clear
      fakeRepo.streamController.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.categories, isEmpty);
    });

    test('stream error sets errorMessage', () async {
      fakeRepo.streamController.addError(Exception('connection lost'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.errorMessage.value, isNotNull);
      expect(controller.errorMessage.value, isNotEmpty);
    });

    test('successful stream event clears errorMessage', () async {
      // Trigger error first
      fakeRepo.streamController.addError(Exception('fail'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.errorMessage.value, isNotNull);

      // Then a good event
      fakeRepo.streamController.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.errorMessage.value, isNull);
    });
  });

  // ── createCategory ────────────────────────────────────────────────────────
  group('CategoryController — createCategory', () {
    test('unique slug delegates to repository and returns success', () async {
      final result = await controller.createCategory(name: 'Electronics');

      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(fakeRepo.createCalled, isTrue);
    });

    test('isLoading is reset to false after successful create', () async {
      await controller.createCategory(name: 'Electronics');
      expect(controller.isLoading.value, isFalse);
    });

    test('duplicate slug is rejected — repository NOT called', () async {
      // Load an existing category via the stream
      fakeRepo.streamController.add([_cat(slug: 'electronics')]);
      await Future<void>.delayed(Duration.zero);

      final result = await controller.createCategory(
        name: 'Electronics', // generates slug 'electronics' — already exists
      );

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
      expect(result.error, contains('electronics'));
      expect(fakeRepo.createCalled, isFalse); // repository must NOT be called
    });

    test('empty slug input is rejected — repository NOT called', () async {
      // A name that produces an empty slug after normalisation
      final result = await controller.createCategory(name: '---');

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
      expect(fakeRepo.createCalled, isFalse);
    });

    test('customSlug overrides name-derived slug', () async {
      final result = await controller.createCategory(
        name: 'My Category',
        customSlug: 'custom-override',
      );

      expect(result.success, isTrue);
      expect(fakeRepo.createCalled, isTrue);
    });

    test(
      'repository error returns failure record and sets errorMessage',
      () async {
        fakeRepo.throwOnCreate = true;
        final result = await controller.createCategory(name: 'Gadgets');

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(controller.errorMessage.value, isNotNull);
      },
    );

    test('isLoading is reset to false even after repository error', () async {
      fakeRepo.throwOnCreate = true;
      await controller.createCategory(name: 'Gadgets');
      expect(controller.isLoading.value, isFalse);
    });
  });

  // ── updateCategory ────────────────────────────────────────────────────────
  group('CategoryController — updateCategory', () {
    test('delegates to repository and returns success', () async {
      final result = await controller.updateCategory(
        id: 'cat-1',
        name: 'Updated Electronics',
      );

      expect(result.success, isTrue);
      expect(fakeRepo.updateCalled, isTrue);
    });

    test('isLoading is reset after successful update', () async {
      await controller.updateCategory(id: 'cat-1', description: 'New desc');
      expect(controller.isLoading.value, isFalse);
    });

    test(
      'duplicate slug on update is rejected — repository NOT called',
      () async {
        // Load two existing categories
        fakeRepo.streamController.add([
          _cat(id: 'cat-1', slug: 'electronics'),
          _cat(id: 'cat-2', slug: 'phones'),
        ]);
        await Future<void>.delayed(Duration.zero);

        // Try to rename cat-1 to use cat-2's slug
        final result = await controller.updateCategory(
          id: 'cat-1',
          name:
              'Phones', // would produce slug 'phones' — already taken by cat-2
        );

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(fakeRepo.updateCalled, isFalse);
      },
    );

    test('updating its own slug is allowed (excludeId logic)', () async {
      // cat-1 already has slug 'electronics'
      fakeRepo.streamController.add([_cat(id: 'cat-1', slug: 'electronics')]);
      await Future<void>.delayed(Duration.zero);

      // Update cat-1 keeping the same slug — should not be a duplicate
      final result = await controller.updateCategory(
        id: 'cat-1',
        name: 'Electronics', // slug 'electronics' — same doc, should pass
      );

      expect(result.success, isTrue);
      expect(fakeRepo.updateCalled, isTrue);
    });

    test('repository error returns failure and sets errorMessage', () async {
      fakeRepo.throwOnUpdate = true;
      final result = await controller.updateCategory(id: 'cat-1');

      expect(result.success, isFalse);
      expect(controller.errorMessage.value, isNotNull);
    });
  });

  // ── deleteCategory ────────────────────────────────────────────────────────
  group('CategoryController — deleteCategory', () {
    test('delegates to repository with correct id', () async {
      final result = await controller.deleteCategory('cat-to-delete');

      expect(result.success, isTrue);
      expect(fakeRepo.deleteCalled, isTrue);
      expect(fakeRepo.lastDeletedId, 'cat-to-delete');
    });

    test('isLoading is reset after successful delete', () async {
      await controller.deleteCategory('cat-x');
      expect(controller.isLoading.value, isFalse);
    });

    test('repository error returns failure and sets errorMessage', () async {
      fakeRepo.throwOnDelete = true;
      final result = await controller.deleteCategory('bad-id');

      expect(result.success, isFalse);
      expect(controller.errorMessage.value, isNotNull);
    });

    test('isLoading is reset even after repository error', () async {
      fakeRepo.throwOnDelete = true;
      await controller.deleteCategory('bad-id');
      expect(controller.isLoading.value, isFalse);
    });
  });

  // ── toggleCategoryActive ──────────────────────────────────────────────────
  group('CategoryController — toggleCategoryActive', () {
    test('active category is toggled to inactive', () async {
      final active = _cat(isActive: true);
      final result = await controller.toggleCategoryActive(active);

      expect(result.success, isTrue);
      expect(fakeRepo.setActiveCalled, isTrue);
      expect(fakeRepo.lastSetActiveValue, isFalse); // flipped
    });

    test('inactive category is toggled to active', () async {
      final inactive = _cat(isActive: false);
      final result = await controller.toggleCategoryActive(inactive);

      expect(result.success, isTrue);
      expect(fakeRepo.setActiveCalled, isTrue);
      expect(fakeRepo.lastSetActiveValue, isTrue); // flipped
    });

    test('isLoading is reset after toggle', () async {
      await controller.toggleCategoryActive(_cat());
      expect(controller.isLoading.value, isFalse);
    });

    test('repository error returns failure and sets errorMessage', () async {
      fakeRepo.throwOnSetActive = true;
      final result = await controller.toggleCategoryActive(_cat());

      expect(result.success, isFalse);
      expect(controller.errorMessage.value, isNotNull);
    });
  });

  // ── Stream disposal ───────────────────────────────────────────────────────
  group('CategoryController — stream disposal on onClose', () {
    test('no updates are applied after controller is closed', () async {
      // Populate before close
      fakeRepo.streamController.add([_cat(id: 'pre-close')]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.categories.length, 1);

      // Close the controller (cancels subscription)
      controller.onClose();

      // Emit after close — should not affect categories
      if (!fakeRepo.streamController.isClosed) {
        fakeRepo.streamController.add([
          _cat(id: 'post-close-1'),
          _cat(id: 'post-close-2', slug: 'other'),
        ]);
        await Future<void>.delayed(Duration.zero);
      }

      // categories should still be at the pre-close state
      expect(controller.categories.length, 1);
      expect(controller.categories[0].id, 'pre-close');
    });
  });
}
