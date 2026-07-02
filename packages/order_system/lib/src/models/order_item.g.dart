// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => _OrderItem(
  productId: json['productId'] as String,
  variantId: json['variantId'] as String,
  sku: json['sku'] as String,
  title: json['title'] as String,
  quantity: (json['quantity'] as num).toInt(),
  priceAtPurchase: (json['priceAtPurchase'] as num).toDouble(),
);

Map<String, dynamic> _$OrderItemToJson(_OrderItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'variantId': instance.variantId,
      'sku': instance.sku,
      'title': instance.title,
      'quantity': instance.quantity,
      'priceAtPurchase': instance.priceAtPurchase,
    };
