// Unit tests for CategoryModel — Phase 3.2A
//
// ignore_for_file: subtype_of_sealed_class
//
// Coverage:
//   - Field storage (all fields correctly assigned)
//   - id populated from snapshot.id, never from document body
//   - toMap() excludes id and includes all 7 body fields
//   - toMap() uses Timestamp, not DateTime
//   - copyWith() returns correct updated model and preserves unchanged fields
//   - fromFirestore() handles valid data correctly
//   - fromFirestore() handles missing optional fields with safe defaults
//   - fromFirestore() handles missing timestamp fields with epoch fallback
//   - toString() contains key identifying fields
//
// ## Testing strategy
//
// CategoryModel.fromFirestore() requires a DocumentSnapshot<Map<String, dynamic>>.
// We supply a _FakeDocumentSnapshot that implements just enough of the
// DocumentSnapshot interface to satisfy fromFirestore() — no Firebase SDK
// initialisation or network calls required.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_admin/features/categories/models/category_model.dart';

// ── Fake DocumentSnapshot ─────────────────────────────────────────────────────

/// Minimal fake that satisfies [CategoryModel.fromFirestore]'s
/// [DocumentSnapshot<Map<String, dynamic>>] parameter.
///
/// We only implement the three members that [fromFirestore] actually uses:
///   - [id]     → the Firestore document ID
///   - [data]() → the document field map
///   - [exists] → whether the document exists (unused in fromFirestore but
///                required by the interface)
class _FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot({required this.id, required Map<String, dynamic> data})
    : _data = data;

  @override
  final String id;

  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => true;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final _now = DateTime(2024, 6, 15, 10, 30);
final _later = DateTime(2024, 6, 20, 14, 0);

/// Builds a valid full data map for use in _FakeDocumentSnapshot.
Map<String, dynamic> _validData({
  String name = 'Electronics',
  String slug = 'electronics',
  String description = 'Electronic products',
  String imageUrl = 'https://example.com/img.jpg',
  bool isActive = true,
  int sortOrder = 1,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => {
  'name': name,
  'slug': slug,
  'description': description,
  'imageUrl': imageUrl,
  'isActive': isActive,
  'sortOrder': sortOrder,
  'createdAt': Timestamp.fromDate(createdAt ?? _now),
  'updatedAt': Timestamp.fromDate(updatedAt ?? _later),
};

/// Creates a CategoryModel directly (no Firestore) for serialisation tests.
CategoryModel _model({
  String id = 'cat-001',
  String name = 'Electronics',
  String slug = 'electronics',
  String description = 'Electronic products',
  String imageUrl = '',
  bool isActive = true,
  int sortOrder = 0,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => CategoryModel(
  id: id,
  name: name,
  slug: slug,
  description: description,
  imageUrl: imageUrl,
  isActive: isActive,
  sortOrder: sortOrder,
  createdAt: createdAt ?? _now,
  updatedAt: updatedAt ?? _later,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── Direct construction ───────────────────────────────────────────────────
  group('CategoryModel — direct construction', () {
    test('stores all fields correctly', () {
      final model = _model(
        id: 'abc',
        name: 'Shoes',
        slug: 'shoes',
        description: 'All kinds of shoes',
        imageUrl: 'https://example.com/shoes.jpg',
        isActive: false,
        sortOrder: 3,
        createdAt: _now,
        updatedAt: _later,
      );

      expect(model.id, 'abc');
      expect(model.name, 'Shoes');
      expect(model.slug, 'shoes');
      expect(model.description, 'All kinds of shoes');
      expect(model.imageUrl, 'https://example.com/shoes.jpg');
      expect(model.isActive, isFalse);
      expect(model.sortOrder, 3);
      expect(model.createdAt, _now);
      expect(model.updatedAt, _later);
    });

    test(
      'two models with identical values are structurally equal in fields',
      () {
        final a = _model(id: 'x', name: 'Tech');
        final b = _model(id: 'x', name: 'Tech');
        expect(a.id, b.id);
        expect(a.name, b.name);
        expect(a.slug, b.slug);
      },
    );
  });

  // ── toMap ─────────────────────────────────────────────────────────────────
  group('CategoryModel.toMap', () {
    test('contains exactly 8 keys (7 fields + no id)', () {
      final map = _model().toMap();
      expect(map.keys.toSet(), {
        'name',
        'slug',
        'description',
        'imageUrl',
        'isActive',
        'sortOrder',
        'createdAt',
        'updatedAt',
      });
    });

    test('does NOT contain "id" key — id is the document ID, not a field', () {
      final map = _model().toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('name is serialised correctly', () {
      expect(_model(name: 'Footwear').toMap()['name'], 'Footwear');
    });

    test('slug is serialised correctly', () {
      expect(_model(slug: 'footwear').toMap()['slug'], 'footwear');
    });

    test('isActive: true serialises correctly', () {
      expect(_model(isActive: true).toMap()['isActive'], isTrue);
    });

    test('isActive: false serialises correctly', () {
      expect(_model(isActive: false).toMap()['isActive'], isFalse);
    });

    test('sortOrder serialises correctly', () {
      expect(_model(sortOrder: 7).toMap()['sortOrder'], 7);
    });

    test('createdAt is stored as Timestamp, not DateTime', () {
      final map = _model(createdAt: _now).toMap();
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('updatedAt is stored as Timestamp, not DateTime', () {
      final map = _model(updatedAt: _later).toMap();
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('createdAt Timestamp round-trips to same DateTime', () {
      final map = _model(createdAt: _now).toMap();
      final ts = map['createdAt'] as Timestamp;
      expect(ts.toDate(), _now);
    });

    test('updatedAt Timestamp round-trips to same DateTime', () {
      final map = _model(updatedAt: _later).toMap();
      final ts = map['updatedAt'] as Timestamp;
      expect(ts.toDate(), _later);
    });
  });

  // ── fromFirestore ─────────────────────────────────────────────────────────
  group('CategoryModel.fromFirestore', () {
    test('id is populated from snapshot.id, not from document data', () {
      final snapshot = _FakeDocumentSnapshot(
        id: 'firestore-generated-id',
        data: _validData(),
      );
      final model = CategoryModel.fromFirestore(snapshot);
      expect(model.id, 'firestore-generated-id');
    });

    test('all fields are parsed from valid data', () {
      final snapshot = _FakeDocumentSnapshot(
        id: 'cat-1',
        data: _validData(
          name: 'Electronics',
          slug: 'electronics',
          description: 'Electronic products and accessories',
          imageUrl: 'https://example.com/electronics.jpg',
          isActive: true,
          sortOrder: 2,
          createdAt: _now,
          updatedAt: _later,
        ),
      );
      final model = CategoryModel.fromFirestore(snapshot);

      expect(model.id, 'cat-1');
      expect(model.name, 'Electronics');
      expect(model.slug, 'electronics');
      expect(model.description, 'Electronic products and accessories');
      expect(model.imageUrl, 'https://example.com/electronics.jpg');
      expect(model.isActive, isTrue);
      expect(model.sortOrder, 2);
      expect(model.createdAt, _now);
      expect(model.updatedAt, _later);
    });

    test('missing name field defaults to empty string', () {
      final data = _validData()..remove('name');
      final model = CategoryModel.fromFirestore(
        _FakeDocumentSnapshot(id: 'x', data: data),
      );
      expect(model.name, '');
    });

    test('missing slug field defaults to empty string', () {
      final data = _validData()..remove('slug');
      final model = CategoryModel.fromFirestore(
        _FakeDocumentSnapshot(id: 'x', data: data),
      );
      expect(model.slug, '');
    });

    test('missing isActive defaults to true', () {
      final data = _validData()..remove('isActive');
      final model = CategoryModel.fromFirestore(
        _FakeDocumentSnapshot(id: 'x', data: data),
      );
      expect(model.isActive, isTrue);
    });

    test('missing sortOrder defaults to 0', () {
      final data = _validData()..remove('sortOrder');
      final model = CategoryModel.fromFirestore(
        _FakeDocumentSnapshot(id: 'x', data: data),
      );
      expect(model.sortOrder, 0);
    });

    test('missing imageUrl defaults to empty string', () {
      final data = _validData()..remove('imageUrl');
      final model = CategoryModel.fromFirestore(
        _FakeDocumentSnapshot(id: 'x', data: data),
      );
      expect(model.imageUrl, '');
    });

    test('missing createdAt falls back to epoch (not a crash)', () {
      final data = _validData()..remove('createdAt');
      final model = CategoryModel.fromFirestore(
        _FakeDocumentSnapshot(id: 'x', data: data),
      );
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('missing updatedAt falls back to epoch (not a crash)', () {
      final data = _validData()..remove('updatedAt');
      final model = CategoryModel.fromFirestore(
        _FakeDocumentSnapshot(id: 'x', data: data),
      );
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('wrong type for createdAt falls back to epoch (not a crash)', () {
      final data = _validData();
      data['createdAt'] = 'not-a-timestamp'; // malformed
      final model = CategoryModel.fromFirestore(
        _FakeDocumentSnapshot(id: 'x', data: data),
      );
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('completely empty data map produces safe defaults (no crash)', () {
      final model = CategoryModel.fromFirestore(
        _FakeDocumentSnapshot(id: 'empty', data: {}),
      );
      expect(model.id, 'empty');
      expect(model.name, '');
      expect(model.slug, '');
      expect(model.isActive, isTrue);
      expect(model.sortOrder, 0);
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────
  group('CategoryModel.copyWith', () {
    test('returns same values when no arguments supplied', () {
      final original = _model(id: 'orig', name: 'Tech', sortOrder: 5);
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.slug, original.slug);
      expect(copy.sortOrder, original.sortOrder);
    });

    test('updates only the specified field — name', () {
      final original = _model(name: 'Tech', slug: 'tech');
      final copy = original.copyWith(name: 'Technology');

      expect(copy.name, 'Technology');
      expect(copy.slug, 'tech'); // unchanged
      expect(copy.id, original.id); // unchanged
    });

    test('updates only the specified field — isActive', () {
      final original = _model(isActive: true);
      final copy = original.copyWith(isActive: false);

      expect(copy.isActive, isFalse);
      expect(copy.name, original.name); // unchanged
    });

    test('updates only the specified field — sortOrder', () {
      final original = _model(sortOrder: 1);
      final copy = original.copyWith(sortOrder: 99);

      expect(copy.sortOrder, 99);
      expect(copy.name, original.name); // unchanged
    });

    test('updates id', () {
      final original = _model(id: 'old-id');
      final copy = original.copyWith(id: 'new-id');
      expect(copy.id, 'new-id');
    });

    test('updates updatedAt while preserving createdAt', () {
      final newUpdated = DateTime(2025, 1, 1);
      final original = _model(createdAt: _now, updatedAt: _later);
      final copy = original.copyWith(updatedAt: newUpdated);

      expect(copy.updatedAt, newUpdated);
      expect(copy.createdAt, _now); // unchanged
    });
  });

  // ── toString ─────────────────────────────────────────────────────────────
  group('CategoryModel.toString', () {
    test('contains id', () {
      expect(_model(id: 'abc-123').toString(), contains('abc-123'));
    });

    test('contains name', () {
      expect(_model(name: 'Gadgets').toString(), contains('Gadgets'));
    });

    test('contains slug', () {
      expect(_model(slug: 'gadgets').toString(), contains('gadgets'));
    });

    test('contains isActive value', () {
      expect(_model(isActive: true).toString(), contains('true'));
      expect(_model(isActive: false).toString(), contains('false'));
    });

    test('contains sortOrder value', () {
      expect(_model(sortOrder: 42).toString(), contains('42'));
    });
  });
}
