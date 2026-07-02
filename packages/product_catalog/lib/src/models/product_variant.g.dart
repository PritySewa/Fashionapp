// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_variant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductVariant _$ProductVariantFromJson(Map<String, dynamic> json) =>
    _ProductVariant(
      id: json['id'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      attributes:
          (json['attributes'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      price: (json['price'] as num).toDouble(),
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      videoUrl: json['videoUrl'] as String?,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      dimensions:
          (json['dimensions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      status: json['status'] as String? ?? 'active',
      trackInventory: json['trackInventory'] as bool? ?? true,
    );

Map<String, dynamic> _$ProductVariantToJson(_ProductVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sku': instance.sku,
      'barcode': instance.barcode,
      'attributes': instance.attributes,
      'price': instance.price,
      'discountPrice': instance.discountPrice,
      'stock': instance.stock,
      'images': instance.images,
      'videoUrl': instance.videoUrl,
      'weight': instance.weight,
      'dimensions': instance.dimensions,
      'status': instance.status,
      'trackInventory': instance.trackInventory,
    };
