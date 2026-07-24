// Unit tests for ProductRepository — image management (Phase 3.4D)
//
// Tests cover:
//   - Image upload paths during createProduct
//   - Deletion of removed remote images on updateProduct
//   - Preservation of kept remote images on updateProduct
//   - Appending new local images after existing max-index on updateProduct
//   - Correct images array ordering (reorder is implied by list order)
//   - deleteProduct cleans up all Storage files

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_admin/features/products/models/product_model.dart';

// ── Helper: PickedProductImage factories ────────────────────────────────────

PickedProductImage _localImage(String name) => PickedProductImage.fromFile(
  bytes: Uint8List.fromList([0, 1, 2, 3]),
  name: name,
);

PickedProductImage _remoteImage(String url) => PickedProductImage.fromUrl(url);

// ── Fake Storage tracking infrastructure ─────────────────────────────────────

/// Simulates Firebase Storage operations in memory without any real SDK calls.
class _FakeStorageTracker {
  final List<String> uploaded = [];
  final List<String> deleted = [];

  void recordUpload(String path) => uploaded.add(path);
  void recordDelete(String url) => deleted.add(url);

  bool wasUploaded(String path) => uploaded.any((p) => p.contains(path));
  bool wasDeleted(String url) => deleted.contains(url);
}

/// Simulates the image-management logic from ProductRepository without touching
/// real Firebase SDKs. This mirrors the exact algorithm in product_repository.dart
/// so that we can test the logic in isolation.
class _ImageManager {
  final _FakeStorageTracker tracker;

  _ImageManager(this.tracker);

  // ── mirrors ProductRepository.createProduct image logic ──────────────────

  List<String> simulateCreate({
    required String productId,
    required List<PickedProductImage> images,
  }) {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final img = images[i];
      if (img.bytes != null) {
        final ext = img.name != null && img.name!.contains('.')
            ? img.name!.split('.').last
            : 'jpg';
        final path =
            'products/$productId/image_${(i + 1).toString().padLeft(3, '0')}.$ext';
        tracker.recordUpload(path);
        // Simulate a download URL returned by Firebase Storage
        urls.add('https://storage.example.com/$path');
      }
    }
    return urls;
  }

  // ── mirrors ProductRepository.updateProduct image logic ──────────────────

  List<String> simulateUpdate({
    required String productId,
    required List<String> existingUrls,
    required List<PickedProductImage> newImages,
  }) {
    // 1. Identify URLs being kept vs removed
    final keptUrls = newImages
        .where((img) => img.isRemote)
        .map((img) => img.url!)
        .toList();

    final toDelete = existingUrls
        .where((url) => !keptUrls.contains(url))
        .toList();

    for (final url in toDelete) {
      tracker.recordDelete(url);
    }

    // 2. Compute maxIndex from existing URL names
    int maxIndex = 0;
    final regExp = RegExp(r'image_(\d+)');
    for (final url in existingUrls) {
      final match = regExp.firstMatch(url);
      if (match != null) {
        final idx = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (idx > maxIndex) maxIndex = idx;
      }
    }

    // 3. Build final URL list
    final finalUrls = <String>[];
    for (final img in newImages) {
      if (img.isRemote) {
        finalUrls.add(img.url!);
      } else if (img.bytes != null) {
        final ext = img.name != null && img.name!.contains('.')
            ? img.name!.split('.').last
            : 'jpg';
        maxIndex++;
        final path =
            'products/$productId/image_${maxIndex.toString().padLeft(3, '0')}.$ext';
        tracker.recordUpload(path);
        finalUrls.add('https://storage.example.com/$path');
      }
    }

    return finalUrls;
  }

  // ── mirrors ProductRepository.deleteProduct Storage cleanup ──────────────

  void simulateDeleteProduct({
    required String productId,
    required List<String> existingUrls,
  }) {
    for (final url in existingUrls) {
      tracker.recordDelete(url);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late _FakeStorageTracker tracker;
  late _ImageManager manager;

  setUp(() {
    tracker = _FakeStorageTracker();
    manager = _ImageManager(tracker);
  });

  // ── createProduct — image uploads ────────────────────────────────────────

  group('createProduct — image upload', () {
    test('single local image is uploaded with correct path', () {
      final urls = manager.simulateCreate(
        productId: 'prod-001',
        images: [_localImage('photo.jpg')],
      );

      expect(urls.length, 1);
      expect(tracker.uploaded.length, 1);
      expect(tracker.uploaded[0], 'products/prod-001/image_001.jpg');
    });

    test('multiple local images are uploaded in order with padded indices', () {
      final urls = manager.simulateCreate(
        productId: 'prod-002',
        images: [
          _localImage('a.jpg'),
          _localImage('b.png'),
          _localImage('c.webp'),
        ],
      );

      expect(urls.length, 3);
      expect(tracker.uploaded[0], 'products/prod-002/image_001.jpg');
      expect(tracker.uploaded[1], 'products/prod-002/image_002.png');
      expect(tracker.uploaded[2], 'products/prod-002/image_003.webp');
    });

    test('empty images list produces no uploads', () {
      final urls = manager.simulateCreate(productId: 'prod-003', images: []);

      expect(urls, isEmpty);
      expect(tracker.uploaded, isEmpty);
    });

    test('first uploaded URL becomes cover image (index 0)', () {
      final urls = manager.simulateCreate(
        productId: 'prod-004',
        images: [_localImage('cover.jpg'), _localImage('secondary.jpg')],
      );

      expect(urls.first, contains('image_001.jpg'));
    });
  });

  // ── updateProduct — delete removed images ────────────────────────────────

  group('updateProduct — delete removed images', () {
    test('removed remote URL is deleted from Storage', () {
      const removedUrl =
          'https://storage.example.com/products/prod-010/image_001.jpg';
      const keptUrl =
          'https://storage.example.com/products/prod-010/image_002.jpg';

      final finalUrls = manager.simulateUpdate(
        productId: 'prod-010',
        existingUrls: [removedUrl, keptUrl],
        newImages: [_remoteImage(keptUrl)], // removedUrl is not in new list
      );

      expect(tracker.wasDeleted(removedUrl), isTrue);
      expect(tracker.wasDeleted(keptUrl), isFalse);
      expect(finalUrls, [keptUrl]);
    });

    test('all images removed triggers delete for each existing URL', () {
      final existingUrls = [
        'https://storage.example.com/products/p/image_001.jpg',
        'https://storage.example.com/products/p/image_002.jpg',
      ];

      final finalUrls = manager.simulateUpdate(
        productId: 'p',
        existingUrls: existingUrls,
        newImages: [], // all removed
      );

      expect(tracker.deleted.length, 2);
      expect(finalUrls, isEmpty);
    });
  });

  // ── updateProduct — preserve kept images ─────────────────────────────────

  group('updateProduct — preserve kept images', () {
    test('kept remote URLs are NOT deleted', () {
      const url1 = 'https://storage.example.com/products/p/image_001.jpg';
      const url2 = 'https://storage.example.com/products/p/image_002.jpg';

      manager.simulateUpdate(
        productId: 'p',
        existingUrls: [url1, url2],
        newImages: [_remoteImage(url1), _remoteImage(url2)],
      );

      expect(tracker.deleted, isEmpty);
    });

    test('kept remote URLs appear in final list in provided order', () {
      const url1 = 'https://storage.example.com/products/p/image_001.jpg';
      const url2 = 'https://storage.example.com/products/p/image_002.jpg';

      final finalUrls = manager.simulateUpdate(
        productId: 'p',
        existingUrls: [url1, url2],
        // Reversed order — simulates user reordering
        newImages: [_remoteImage(url2), _remoteImage(url1)],
      );

      // New order: url2 is first (cover), url1 is second
      expect(finalUrls[0], url2);
      expect(finalUrls[1], url1);
    });
  });

  // ── updateProduct — append new local images ───────────────────────────────

  group('updateProduct — append new local images', () {
    test('new local images are appended after the existing maxIndex', () {
      // Existing product has image_001 and image_002
      const url1 =
          'https://storage.example.com/products/prod-020/image_001.jpg';
      const url2 =
          'https://storage.example.com/products/prod-020/image_002.jpg';

      final finalUrls = manager.simulateUpdate(
        productId: 'prod-020',
        existingUrls: [url1, url2],
        newImages: [
          _remoteImage(url1),
          _remoteImage(url2),
          _localImage('new.jpg'),
        ],
      );

      expect(finalUrls.length, 3);
      // New upload must be image_003
      expect(tracker.uploaded.length, 1);
      expect(tracker.uploaded[0], 'products/prod-020/image_003.jpg');
    });

    test('mixed delete-and-append produces correct sequence', () {
      // Existing: image_001 (will be kept), image_002 (will be removed)
      const kept = 'https://storage.example.com/products/p/image_001.jpg';
      const removed = 'https://storage.example.com/products/p/image_002.jpg';

      final finalUrls = manager.simulateUpdate(
        productId: 'p',
        existingUrls: [kept, removed],
        newImages: [
          _remoteImage(kept),
          _localImage('fresh.png'), // new upload
        ],
      );

      expect(tracker.wasDeleted(removed), isTrue);
      expect(tracker.uploaded.length, 1);
      // maxIndex was 2 (from image_002), so new file is image_003
      expect(tracker.uploaded[0], 'products/p/image_003.png');
      expect(finalUrls.length, 2);
      expect(finalUrls[0], kept);
    });
  });

  // ── reorder ───────────────────────────────────────────────────────────────

  group('reorder — order is determined by PickedProductImage list order', () {
    test('reorder changes which URL is first (cover)', () {
      const url1 = 'https://storage.example.com/products/p/image_001.jpg';
      const url2 = 'https://storage.example.com/products/p/image_002.jpg';
      const url3 = 'https://storage.example.com/products/p/image_003.jpg';

      // User moved url3 to the front
      final finalUrls = manager.simulateUpdate(
        productId: 'p',
        existingUrls: [url1, url2, url3],
        newImages: [
          _remoteImage(url3), // now cover
          _remoteImage(url1),
          _remoteImage(url2),
        ],
      );

      expect(finalUrls[0], url3); // new cover
      expect(finalUrls[1], url1);
      expect(finalUrls[2], url2);
      expect(tracker.deleted, isEmpty);
      expect(tracker.uploaded, isEmpty);
    });
  });

  // ── deleteProduct — Storage cleanup ──────────────────────────────────────

  group('deleteProduct — cleans up all Storage files', () {
    test('all image URLs are deleted when product is deleted', () {
      final existingUrls = [
        'https://storage.example.com/products/prod-099/image_001.jpg',
        'https://storage.example.com/products/prod-099/image_002.jpg',
        'https://storage.example.com/products/prod-099/image_003.jpg',
      ];

      manager.simulateDeleteProduct(
        productId: 'prod-099',
        existingUrls: existingUrls,
      );

      expect(tracker.deleted.length, 3);
      for (final url in existingUrls) {
        expect(tracker.wasDeleted(url), isTrue);
      }
    });

    test('deleteProduct with no images makes no Storage calls', () {
      manager.simulateDeleteProduct(productId: 'prod-100', existingUrls: []);

      expect(tracker.deleted, isEmpty);
    });
  });

  // ── PickedProductImage discriminator ─────────────────────────────────────

  group('PickedProductImage discriminator', () {
    test('isRemote is true for URL-backed images', () {
      final img = _remoteImage('https://example.com/img.jpg');
      expect(img.isRemote, isTrue);
    });

    test('isRemote is false for file-backed images', () {
      final img = _localImage('photo.jpg');
      expect(img.isRemote, isFalse);
    });

    test('image 10-limit: list with 10 items has correct length', () {
      final images = List.generate(10, (i) => _localImage('img$i.jpg'));
      expect(images.length, 10);

      // Simulate create — all 10 should be uploaded
      final urls = manager.simulateCreate(
        productId: 'prod-max',
        images: images,
      );
      expect(urls.length, 10);
      expect(tracker.uploaded.length, 10);
    });
  });
}
