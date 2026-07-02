import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_variant.freezed.dart';
part 'product_variant.g.dart';

@freezed
abstract class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required String id,
    required String sku,
    String? barcode,
    @Default({}) Map<String, String> attributes, // e.g. {'Color': 'Red', 'Size': 'XL'}
    required double price,
    double? discountPrice,
    @Default(0) int stock,
    @Default([]) List<String> images,
    String? videoUrl,
    @Default(0.0) double weight,
    @Default({}) Map<String, double> dimensions, // length, width, height
    @Default('active') String status,
    @Default(true) bool trackInventory,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantFromJson(json);
}
