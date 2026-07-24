import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
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

// Fake implementations for routing/navigation and dependency injection
class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Stream<List<CategoryModel>> watchCategories() => const Stream.empty();
  @override
  Future<CategoryModel?> getCategory(String id) async => null;
}

class _FakeBadgeRepository extends Fake implements BadgeRepository {
  @override
  Stream<List<BadgeModel>> watchBadges() => const Stream.empty();
  @override
  Future<BadgeModel?> getBadge(String id) async => null;
}

class _FakeProductRepository extends Fake implements ProductRepository {
  @override
  Stream<List<ProductModel>> watchProducts() => const Stream.empty();
}

// Fake FilePicker implementation that simulates picking files
class FakeFilePicker extends FilePicker {
  final List<PlatformFile> filesToReturn;

  FakeFilePicker(this.filesToReturn);

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return FilePickerResult(filesToReturn);
  }
}

void main() {
  setUp(() {
    Get.clearTranslations();

    Get.put<CategoryRepository>(_FakeCategoryRepository());
    Get.put<CategoryController>(CategoryController());

    Get.put<BadgeRepository>(_FakeBadgeRepository());
    Get.put<BadgeController>(BadgeController());

    Get.put<ProductRepository>(_FakeProductRepository());
    Get.put<ProductController>(ProductController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Trace image picking in ProductFormDialog', (tester) async {
    // Setup FilePicker stub
    final testFile = PlatformFile(
      name: 'test_photo.jpg',
      size: 1024,
      bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
      path: '/mock/path/test_photo.jpg',
    );
    FilePicker.platform = FakeFilePicker([testFile]);

    // Build the dialog launcher
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => ProductFormDialog.show(context, product: null),
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Find the image upload area and tap it
    final uploadArea = find.text('Upload Images');
    expect(uploadArea, findsOneWidget);
    await tester.ensureVisible(uploadArea);
    await tester.pumpAndSettle();
    await tester.tap(uploadArea);
    await tester.pump(); // Allow picking logic to run
    await tester.pump(); // Trigger setState rebuild
  });
}
