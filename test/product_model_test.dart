// Unit tests for ProductModel — Phase 3.4A
//
// ignore_for_file: subtype_of_sealed_class

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_admin/features/products/models/product_model.dart';

// ── Fake DocumentSnapshot ─────────────────────────────────────────────────────

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

Map<String, dynamic> _validData({
  String name = 'iPhone 15',
  String slug = 'iphone-15',
  String description = 'Latest iPhone model',
  String categoryId = 'cat-123',
  List<String>? badgeIds,
  String sku = 'IPHONE15-128',
  double price = 999.99,
  double? comparePrice = 1099.99,
  double? costPrice = 700.00,
  int stock = 50,
  bool isActive = true,
  bool isFeatured = true,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => {
  'name': name,
  'slug': slug,
  'description': description,
  'categoryId': categoryId,
  'badgeIds': badgeIds ?? ['badge-001', 'badge-002'],
  'sku': sku,
  'price': price,
  'comparePrice': comparePrice,
  'costPrice': costPrice,
  'stock': stock,
  'isActive': isActive,
  'isFeatured': isFeatured,
  'createdAt': Timestamp.fromDate(createdAt ?? _now),
  'updatedAt': Timestamp.fromDate(updatedAt ?? _later),
};

ProductModel _model({
  String id = 'prod-999',
  String name = 'iPhone 15',
  String slug = 'iphone-15',
  String description = 'Latest iPhone model',
  String categoryId = 'cat-123',
  List<String>? badgeIds,
  String sku = 'IPHONE15-128',
  double price = 999.99,
  double? comparePrice,
  double? costPrice,
  int stock = 50,
  bool isActive = true,
  bool isFeatured = false,
  List<String>? images,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => ProductModel(
  id: id,
  name: name,
  slug: slug,
  description: description,
  categoryId: categoryId,
  badgeIds: badgeIds ?? ['badge-001'],
  sku: sku,
  price: price,
  comparePrice: comparePrice,
  costPrice: costPrice,
  stock: stock,
  isActive: isActive,
  isFeatured: isFeatured,
  images: images ?? const ['image-url-1'],
  createdAt: createdAt ?? _now,
  updatedAt: updatedAt ?? _later,
);

void main() {
  group('ProductModel', () {
    test('Field storage assigns parameters correctly', () {
      final m = _model(
        id: 'prod-001',
        name: 'Shoes',
        slug: 'shoes',
        description: 'Sport shoes',
        categoryId: 'cat-456',
        badgeIds: ['badge-1'],
        sku: 'SHOES-12',
        price: 89.90,
        comparePrice: 120.0,
        costPrice: 40.0,
        stock: 100,
        isActive: false,
        isFeatured: true,
      );

      expect(m.id, 'prod-001');
      expect(m.name, 'Shoes');
      expect(m.slug, 'shoes');
      expect(m.description, 'Sport shoes');
      expect(m.categoryId, 'cat-456');
      expect(m.badgeIds, ['badge-1']);
      expect(m.sku, 'SHOES-12');
      expect(m.price, 89.90);
      expect(m.comparePrice, 120.0);
      expect(m.costPrice, 40.0);
      expect(m.stock, 100);
      expect(m.isActive, false);
      expect(m.isFeatured, true);
    });

    test('toMap() serialization excludes id and formats fields correctly', () {
      final m = _model(
        id: 'prod-001',
        name: 'Shoes',
        slug: 'shoes',
        description: 'Sport shoes',
        categoryId: 'cat-456',
        badgeIds: ['badge-1'],
        sku: 'SHOES-12',
        price: 89.90,
        comparePrice: 120.0,
        costPrice: 40.0,
        stock: 100,
        isActive: false,
        isFeatured: true,
      );

      final map = m.toMap();

      expect(map.containsKey('id'), isFalse);
      expect(map['name'], 'Shoes');
      expect(map['slug'], 'shoes');
      expect(map['description'], 'Sport shoes');
      expect(map['categoryId'], 'cat-456');
      expect(map['badgeIds'], ['badge-1']);
      expect(map['sku'], 'SHOES-12');
      expect(map['price'], 89.90);
      expect(map['comparePrice'], 120.0);
      expect(map['costPrice'], 40.0);
      expect(map['stock'], 100);
      expect(map['isActive'], isFalse);
      expect(map['isFeatured'], isTrue);
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), _now);
    });

    test('fromFirestore() deserializes full valid map', () {
      final snap = _FakeDocumentSnapshot(
        id: 'db-prod-id',
        data: _validData(name: 'Watch', slug: 'watch-slug', price: 299.00),
      );

      final m = ProductModel.fromFirestore(snap);

      expect(m.id, 'db-prod-id');
      expect(m.name, 'Watch');
      expect(m.slug, 'watch-slug');
      expect(m.price, 299.00);
      expect(m.badgeIds, ['badge-001', 'badge-002']);
    });

    test(
      'fromFirestore() falls back safely on missing optional/null values',
      () {
        final snap = _FakeDocumentSnapshot(
          id: 'db-prod-empty',
          data: {'name': null, 'slug': null, 'price': null, 'badgeIds': null},
        );

        final m = ProductModel.fromFirestore(snap);

        expect(m.name, '');
        expect(m.slug, '');
        expect(m.price, 0.0);
        expect(m.badgeIds, isEmpty);
        expect(m.comparePrice, isNull);
        expect(m.costPrice, isNull);
        expect(m.isActive, isTrue); // default true
        expect(m.isFeatured, isFalse); // default false
      },
    );

    test(
      'fromFirestore() falls back on missing timestamps and logs warning',
      () {
        final snap = _FakeDocumentSnapshot(
          id: 'db-prod-no-time',
          data: _validData(),
        );
        // Remove timestamps from map
        snap.data()?.remove('createdAt');
        snap.data()?.remove('updatedAt');

        final m = ProductModel.fromFirestore(snap);

        expect(m.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
        expect(m.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
      },
    );

    test('copyWith() returns clone with updated fields', () {
      final m = _model(name: 'Original', price: 10.0);
      final updated = m.copyWith(name: 'New Name', comparePrice: 15.0);

      expect(updated.id, m.id);
      expect(updated.name, 'New Name');
      expect(updated.price, 10.0);
      expect(updated.comparePrice, 15.0);
    });

    test('toString() output format matches expectations', () {
      final m = _model(id: 'xyz', name: 'My Prod', sku: 'SKU1');
      expect(m.toString(), contains('xyz'));
      expect(m.toString(), contains('My Prod'));
      expect(m.toString(), contains('SKU1'));
    });

    // ── Images field ────────────────────────────────────────────────────────

    test('images field is stored correctly', () {
      final urls = [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
      ];
      final m = _model(images: urls);
      expect(m.images, urls);
      expect(m.images.length, 2);
    });

    test('first image is the cover image (index 0)', () {
      final urls = [
        'https://example.com/cover.jpg',
        'https://example.com/second.jpg',
      ];
      final m = _model(images: urls);
      expect(m.images.first, 'https://example.com/cover.jpg');
    });

    test('empty images list is stored and serialized correctly', () {
      final m = _model(images: []);
      expect(m.images, isEmpty);

      final map = m.toMap();
      expect(map['images'], isEmpty);
    });

    test('toMap() includes images list', () {
      final urls = ['https://example.com/img1.jpg'];
      final m = _model(images: urls);
      final map = m.toMap();
      expect(map['images'], urls);
    });

    test('fromFirestore() deserializes images list', () {
      final data = _validData();
      data['images'] = [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
      ];
      final snap = _FakeDocumentSnapshot(id: 'img-prod', data: data);
      final m = ProductModel.fromFirestore(snap);
      expect(m.images.length, 2);
      expect(m.images[0], 'https://example.com/img1.jpg');
    });

    test('fromFirestore() falls back to empty list when images is null', () {
      final data = _validData();
      data.remove('images');
      final snap = _FakeDocumentSnapshot(id: 'no-images', data: data);
      final m = ProductModel.fromFirestore(snap);
      expect(m.images, isEmpty);
    });

    test('copyWith(images: [...]) replaces the images list', () {
      final original = _model(images: ['https://example.com/old.jpg']);
      final updated = original.copyWith(
        images: [
          'https://example.com/new1.jpg',
          'https://example.com/new2.jpg',
        ],
      );
      expect(updated.images.length, 2);
      expect(updated.images.first, 'https://example.com/new1.jpg');
      // original is unchanged
      expect(original.images.length, 1);
    });

    test('copyWith() without images preserves existing images', () {
      final urls = ['https://example.com/img.jpg'];
      final m = _model(images: urls);
      final copy = m.copyWith(name: 'New Name');
      expect(copy.images, urls);
    });
  });

  // ── PickedProductImage ─────────────────────────────────────────────────────

  group('PickedProductImage', () {
    test('fromUrl sets isRemote=true and url correctly', () {
      final img = PickedProductImage.fromUrl('https://example.com/photo.jpg');
      expect(img.isRemote, isTrue);
      expect(img.url, 'https://example.com/photo.jpg');
      expect(img.bytes, isNull);
      expect(img.name, isNull);
    });

    test('fromFile sets isRemote=false and bytes/name correctly', () {
      final bytes = Uint8List.fromList([0, 1, 2, 3]);
      final img = PickedProductImage.fromFile(
        bytes: bytes,
        name: 'photo.jpg',
        localPath: '/tmp/photo.jpg',
      );
      expect(img.isRemote, isFalse);
      expect(img.url, isNull);
      expect(img.bytes, bytes);
      expect(img.name, 'photo.jpg');
      expect(img.localPath, '/tmp/photo.jpg');
    });

    test('fromFile without localPath has null localPath', () {
      final bytes = Uint8List.fromList([255, 216]);
      final img = PickedProductImage.fromFile(bytes: bytes, name: 'img.png');
      expect(img.localPath, isNull);
    });
  });
}
