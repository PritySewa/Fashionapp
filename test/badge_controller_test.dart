// Unit tests for BadgeController — Phase 3.3A
//
// Coverage:
//   - Initial state: badges empty, isLoading false, errorMessage null
//   - Stream emits a list → badges updated
//   - Stream emits error → errorMessage set
//   - createBadge with unique slug delegates to repository, returns success
//   - createBadge with duplicate slug is rejected, repository NOT called
//   - createBadge with empty-slug input is rejected, repository NOT called
//   - updateBadge delegates to repository, returns success
//   - updateBadge with duplicate slug is rejected
//   - deleteBadge delegates to repository, returns success
//   - toggleBadgeActive calls setBadgeActive with flipped value
//   - repository error on create → returns failure record, errorMessage set
//   - repository error on delete → returns failure record, errorMessage set
//   - onClose cancels the stream (no further updates after disposal)
//   - refresh() re-subscribes and delivers new data
//   - refresh() clears errorMessage before re-subscribing
//
// ## Testing strategy
//
// BadgeController uses Get.find<BadgeRepository>() in onInit().
// We register a _FakeBadgeRepository before creating the controller,
// so the real Firestore/Firebase SDK is never initialised.
//
// A StreamController<List<BadgeModel>> is used to simulate Firestore's
// realtime stream — we push events into it and assert that badges updates.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marketplace_admin/features/badges/controllers/badge_controller.dart';
import 'package:marketplace_admin/features/badges/models/badge_model.dart';
import 'package:marketplace_admin/features/badges/repositories/badge_repository.dart';

// ── Fake BadgeRepository ──────────────────────────────────────────────────────

/// Stub repository that drives tests without touching Firebase.
///
/// [streamController] lets individual tests push list events or errors into
/// the stream that [BadgeController] subscribes to.
///
/// Call-tracking flags enable delegation assertions.
class _FakeBadgeRepository extends Fake implements BadgeRepository {
  final StreamController<List<BadgeModel>> streamController =
      StreamController<List<BadgeModel>>.broadcast();

  // ── Call tracking ──────────────────────────────────────────────────────────
  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;
  bool setActiveCalled = false;
  bool? lastSetActiveValue;
  String? lastDeletedId;

  // ── Configurable error injection ───────────────────────────────────────────
  bool throwOnCreate = false;
  bool throwOnUpdate = false;
  bool throwOnDelete = false;
  bool throwOnSetActive = false;

  @override
  Stream<List<BadgeModel>> watchBadges() => streamController.stream;

  @override
  Future<String> createBadge({
    required String name,
    required String slug,
    String color = '',
    String icon = '',
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    createCalled = true;
    if (throwOnCreate) throw Exception('Firestore create failed');
    return 'new-fake-badge-id';
  }

  @override
  Future<void> updateBadge({
    required String id,
    String? name,
    String? slug,
    String? color,
    String? icon,
    bool? isActive,
    int? sortOrder,
  }) async {
    updateCalled = true;
    if (throwOnUpdate) throw Exception('Firestore update failed');
  }

  @override
  Future<void> deleteBadge(String id) async {
    deleteCalled = true;
    lastDeletedId = id;
    if (throwOnDelete) throw Exception('Firestore delete failed');
  }

  @override
  Future<void> setBadgeActive(String id, {required bool isActive}) async {
    setActiveCalled = true;
    lastSetActiveValue = isActive;
    if (throwOnSetActive) throw Exception('Firestore setActive failed');
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _now = DateTime(2024, 6, 15);
final _later = DateTime(2024, 6, 20);

BadgeModel _badge({
  String id = 'badge-1',
  String name = 'New Arrival',
  String slug = 'new-arrival',
  String color = '#22C55E',
  String icon = 'new_releases',
  bool isActive = true,
  int sortOrder = 0,
}) => BadgeModel(
  id: id,
  name: name,
  slug: slug,
  color: color,
  icon: icon,
  isActive: isActive,
  sortOrder: sortOrder,
  createdAt: _now,
  updatedAt: _later,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeBadgeRepository fakeRepo;
  late BadgeController controller;

  setUp(() {
    fakeRepo = _FakeBadgeRepository();
    Get.put<BadgeRepository>(fakeRepo);
    controller = BadgeController();
    Get.put<BadgeController>(controller);
  });

  tearDown(() async {
    await fakeRepo.streamController.close();
    Get.reset();
  });

  // ── Initial state ─────────────────────────────────────────────────────────

  group('BadgeController — initial state', () {
    test('badges is empty on init', () {
      expect(controller.badges, isEmpty);
    });

    test('isLoading is false on init', () {
      expect(controller.isLoading.value, isFalse);
    });

    test('errorMessage is null on init', () {
      expect(controller.errorMessage.value, isNull);
    });
  });

  // ── Stream subscription ───────────────────────────────────────────────────

  group('BadgeController — stream', () {
    test('updates badges when stream emits a list', () async {
      fakeRepo.streamController.add([_badge(), _badge(id: 'b2', slug: 'sale')]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.badges.length, 2);
    });

    test('clears errorMessage when stream emits successfully', () async {
      controller.errorMessage.value = 'some error';
      fakeRepo.streamController.add([_badge()]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.errorMessage.value, isNull);
    });

    test('sets errorMessage when stream emits an error', () async {
      fakeRepo.streamController.addError(Exception('network fail'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.errorMessage.value, isNotNull);
    });

    test('does not update badges list on stream error', () async {
      fakeRepo.streamController.add([_badge()]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.badges.length, 1);

      fakeRepo.streamController.addError(Exception('blip'));
      await Future<void>.delayed(Duration.zero);
      // badges still has the last good data
      expect(controller.badges.length, 1);
    });
  });

  // ── createBadge ───────────────────────────────────────────────────────────

  group('BadgeController — createBadge', () {
    test('unique slug delegates to repository and returns success', () async {
      final result = await controller.createBadge(name: 'Hot Deal');
      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(fakeRepo.createCalled, isTrue);
    });

    test('isLoading returns to false after successful create', () async {
      await controller.createBadge(name: 'Flash Sale');
      expect(controller.isLoading.value, isFalse);
    });

    test('duplicate slug is rejected without calling repository', () async {
      fakeRepo.streamController.add([_badge(slug: 'new-arrival')]);
      await Future<void>.delayed(Duration.zero);

      final result = await controller.createBadge(name: 'New Arrival');
      expect(result.success, isFalse);
      expect(result.error, contains('new-arrival'));
      expect(fakeRepo.createCalled, isFalse);
    });

    test(
      'name producing empty slug is rejected without calling repository',
      () async {
        final result = await controller.createBadge(name: '---');
        expect(result.success, isFalse);
        expect(fakeRepo.createCalled, isFalse);
      },
    );

    test(
      'repository error returns failure record and sets errorMessage',
      () async {
        fakeRepo.throwOnCreate = true;
        final result = await controller.createBadge(name: 'Trending');
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(controller.errorMessage.value, isNotNull);
      },
    );

    test('isLoading returns to false even after repository error', () async {
      fakeRepo.throwOnCreate = true;
      await controller.createBadge(name: 'Trending');
      expect(controller.isLoading.value, isFalse);
    });
  });

  // ── updateBadge ───────────────────────────────────────────────────────────

  group('BadgeController — updateBadge', () {
    test('delegates to repository and returns success', () async {
      fakeRepo.streamController.add([_badge()]);
      await Future<void>.delayed(Duration.zero);

      final result = await controller.updateBadge(
        id: 'badge-1',
        name: 'New Arrivals',
      );
      expect(result.success, isTrue);
      expect(fakeRepo.updateCalled, isTrue);
    });

    test('duplicate slug (excluding self) is rejected', () async {
      fakeRepo.streamController.add([
        _badge(id: 'b1', slug: 'new-arrival'),
        _badge(id: 'b2', slug: 'sale'),
      ]);
      await Future<void>.delayed(Duration.zero);

      // Try to rename b1 to a slug that clashes with b2.
      final result = await controller.updateBadge(id: 'b1', name: 'Sale');
      expect(result.success, isFalse);
      expect(result.error, contains('sale'));
      expect(fakeRepo.updateCalled, isFalse);
    });

    test('same slug on same badge is allowed (excludeId)', () async {
      fakeRepo.streamController.add([_badge(id: 'b1', slug: 'new-arrival')]);
      await Future<void>.delayed(Duration.zero);

      // Updating name to the same value should not clash with itself.
      final result = await controller.updateBadge(
        id: 'b1',
        name: 'New Arrival',
      );
      expect(result.success, isTrue);
    });

    test('repository error returns failure record', () async {
      fakeRepo.throwOnUpdate = true;
      final result = await controller.updateBadge(id: 'b1', name: 'Trending');
      expect(result.success, isFalse);
      expect(controller.errorMessage.value, isNotNull);
    });
  });

  // ── deleteBadge ───────────────────────────────────────────────────────────

  group('BadgeController — deleteBadge', () {
    test(
      'delegates to repository with correct id and returns success',
      () async {
        final result = await controller.deleteBadge('badge-42');
        expect(result.success, isTrue);
        expect(fakeRepo.deleteCalled, isTrue);
        expect(fakeRepo.lastDeletedId, 'badge-42');
      },
    );

    test(
      'repository error returns failure record and sets errorMessage',
      () async {
        fakeRepo.throwOnDelete = true;
        final result = await controller.deleteBadge('badge-x');
        expect(result.success, isFalse);
        expect(controller.errorMessage.value, isNotNull);
      },
    );

    test('isLoading returns to false after repository error', () async {
      fakeRepo.throwOnDelete = true;
      await controller.deleteBadge('badge-x');
      expect(controller.isLoading.value, isFalse);
    });
  });

  // ── toggleBadgeActive ─────────────────────────────────────────────────────

  group('BadgeController — toggleBadgeActive', () {
    test('calls setBadgeActive with flipped value (true → false)', () async {
      final badge = _badge(isActive: true);
      final result = await controller.toggleBadgeActive(badge);
      expect(result.success, isTrue);
      expect(fakeRepo.setActiveCalled, isTrue);
      expect(fakeRepo.lastSetActiveValue, isFalse);
    });

    test('calls setBadgeActive with flipped value (false → true)', () async {
      final badge = _badge(isActive: false);
      await controller.toggleBadgeActive(badge);
      expect(fakeRepo.lastSetActiveValue, isTrue);
    });

    test('repository error returns failure record', () async {
      fakeRepo.throwOnSetActive = true;
      final result = await controller.toggleBadgeActive(_badge());
      expect(result.success, isFalse);
      expect(controller.errorMessage.value, isNotNull);
    });
  });

  // ── refresh() ─────────────────────────────────────────────────────────────

  group('BadgeController.refresh', () {
    test('re-subscribes and delivers new data after refresh', () async {
      fakeRepo.streamController.add([_badge(id: 'b1')]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.badges.length, 1);

      controller.refresh();

      fakeRepo.streamController.add([
        _badge(id: 'b2'),
        _badge(id: 'b3', slug: 'sale'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.badges.length, 2);
      expect(controller.badges[0].id, 'b2');
    });

    test('clears errorMessage before re-subscribing', () async {
      fakeRepo.streamController.addError(Exception('fail'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.errorMessage.value, isNotNull);

      controller.refresh();
      expect(controller.errorMessage.value, isNull);
    });

    test('delivers data after refresh following an error', () async {
      fakeRepo.streamController.addError(Exception('network down'));
      await Future<void>.delayed(Duration.zero);

      controller.refresh();
      fakeRepo.streamController.add([_badge()]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.badges.length, 1);
      expect(controller.errorMessage.value, isNull);
    });
  });

  // ── onClose / stream disposal ─────────────────────────────────────────────

  group('BadgeController — onClose', () {
    test('does not update badges after controller is closed', () async {
      fakeRepo.streamController.add([_badge()]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.badges.length, 1);

      controller.onClose();

      fakeRepo.streamController.add([_badge(), _badge(id: 'b2', slug: 'sale')]);
      await Future<void>.delayed(Duration.zero);

      // subscription was cancelled — badges should still be 1
      expect(controller.badges.length, 1);
    });
  });
}
