import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String title,
    @Default('') String description,
    required double basePrice,
    @Default([]) List<String> categoryIds,
    String? brandId,
    @Default([]) List<String> tags,
    @Default([]) List<String> badges,
    @Default({}) Map<String, dynamic> seoMetadata,
    @Default('draft') String status, // draft, active, archived
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
