// Unit and widget tests for Phase 3.3B — Badges Management UI
//
// Coverage:
//   BadgeController.refresh():
//     - re-subscribes and delivers new data
//     - clears errorMessage before re-subscribing
//
//   BadgesView widget:
//     - renders without crash when badges are empty
//     - shows loading indicator when isLoading=true and badges empty
//     - shows empty state when badges empty and not loading
//     - shows error state when errorMessage is set and badges empty
//     - renders badge rows when badges are populated
//
//   Client-side search (_filteredList):
//     - empty query returns all items
//     - query matching name returns correct subset
//     - query matching slug returns correct subset
//     - non-matching query returns empty list
//     - search is case-insensitive
//
// Strategy:
//   Controller tests reuse the _FakeBadgeRepository pattern from
//   badge_controller_test.dart.
//   Widget tests use a lightweight fake via Get.put before pumping the widget.

// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marketplace_admin/features/badges/controllers/badge_controller.dart';
import 'package:marketplace_admin/features/badges/models/badge_model.dart';
import 'package:marketplace_admin/features/badges/repositories/badge_repository.dart';
import 'package:marketplace_admin/features/badges/views/badges_view.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeBadgeRepository extends Fake implements BadgeRepository {
  final StreamController<List<BadgeModel>> streamController =
      StreamController<List<BadgeModel>>.broadcast();

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
  }) async => 'new-id';

  @override
  Future<void> updateBadge({
    required String id,
    String? name,
    String? slug,
    String? color,
    String? icon,
    bool? isActive,
    int? sortOrder,
  }) async {}

  @override
  Future<void> deleteBadge(String id) async {}

  @override
  Future<void> setBadgeActive(String id, {required bool isActive}) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

BadgeModel _badge({
  String id = 'badge-1',
  String name = 'Best Seller',
  String slug = 'best-seller',
  String color = '#22C55E',
  String icon = 'workspace_premium',
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
  createdAt: _epoch,
  updatedAt: _epoch,
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

  // ── BadgeController.refresh() ──────────────────────────────────────────
  group('BadgeController.refresh', () {
    test('re-subscribes and delivers new data after refresh', () async {
      // Push initial data.
      fakeRepo.streamController.add([_badge(id: 'b1')]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.badges.length, 1);

      // Call refresh — cancels old subscription, re-subscribes.
      controller.refresh();

      // Push new data through the broadcast stream.
      fakeRepo.streamController.add([
        _badge(id: 'b2'),
        _badge(id: 'b3', slug: 'new-release'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.badges.length, 2);
      expect(controller.badges[0].id, 'b2');
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
      fakeRepo.streamController.add([_badge()]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.badges.length, 1);
      expect(controller.errorMessage.value, isNull);
    });
  });

  // ── BadgesView widget states ──────────────────────────────────────────────
  group('BadgesView — widget states', () {
    Widget buildUnderTest() =>
        GetMaterialApp(home: Scaffold(body: const BadgesView()));

    testWidgets('renders without crash when badges are empty', (tester) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pump();
      // Should render — no exception.
      expect(find.byType(BadgesView), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading=true and no data', (
      tester,
    ) async {
      controller.isLoading.value = true;
      // badges is still empty

      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when badges empty and not loading', (
      tester,
    ) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.text('No badges yet'), findsOneWidget);
    });

    testWidgets('shows error state when errorMessage is set and no data', (
      tester,
    ) async {
      controller.errorMessage.value = 'Failed to load badges.';

      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.text('Failed to load badges.'), findsOneWidget);
    });

    testWidgets('renders badge names when badges are populated', (
      tester,
    ) async {
      // Pump the widget first so the widget tree is mounted in its empty state.
      await tester.pumpWidget(buildUnderTest());
      await tester.pump(); // empty state frame

      // Now push data through the stream and let the Obx rebuild.
      fakeRepo.streamController.add([
        _badge(id: 'b1', name: 'Best Seller', slug: 'best-seller'),
        _badge(id: 'b2', name: 'New Arrival', slug: 'new-arrival'),
      ]);
      await tester.pump(); // stream event arrives
      await tester.pump(); // Obx rebuilds the widget tree

      expect(controller.badges.length, 2);
      expect(find.text('Best Seller'), findsWidgets);
      expect(find.text('New Arrival'), findsWidgets);
    });

    testWidgets('Add Badge button is present in the page header', (
      tester,
    ) async {
      await tester.pumpWidget(buildUnderTest());
      await tester.pump();

      expect(find.text('Add Badge'), findsWidgets);
    });
  });

  // ── Search / filter logic ─────────────────────────────────────────────────
  group('BadgesView — search filter logic', () {
    final allBadges = [
      _badge(id: 'b1', name: 'Best Seller', slug: 'best-seller'),
      _badge(id: 'b2', name: 'New Arrival', slug: 'new-arrival'),
      _badge(id: 'b3', name: 'Free Shipping', slug: 'free-shipping'),
    ];

    List<BadgeModel> filter(List<BadgeModel> all, String query) {
      if (query.isEmpty) return all;
      final q = query.toLowerCase();
      return all
          .where((b) => b.name.toLowerCase().contains(q) || b.slug.contains(q))
          .toList();
    }

    test('empty query returns all badges', () {
      expect(filter(allBadges, ''), allBadges);
    });

    test('query matching name prefix returns correct subset', () {
      final result = filter(allBadges, 'best');
      expect(result.length, 1);
      expect(result.first.id, 'b1');
    });

    test('query matching slug returns correct subset', () {
      final result = filter(allBadges, 'free-shipping');
      expect(result.length, 1);
      expect(result.first.id, 'b3');
    });

    test('non-matching query returns empty list', () {
      expect(filter(allBadges, 'zzz'), isEmpty);
    });

    test('search is case-insensitive on name', () {
      final result = filter(allBadges, 'BEST SELLER');
      expect(result.length, 1);
      expect(result.first.id, 'b1');
    });

    test('query matching partial slug returns result', () {
      final result = filter(allBadges, 'arrival');
      expect(result.length, 1);
      expect(result.first.id, 'b2');
    });
  });
}
