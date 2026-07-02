// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Coupon _$CouponFromJson(Map<String, dynamic> json) => _Coupon(
  id: json['id'] as String,
  type: $enumDecode(_$DiscountTypeEnumMap, json['type']),
  value: (json['value'] as num).toDouble(),
  isActive: json['isActive'] as bool? ?? true,
  minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
  maxUses: (json['maxUses'] as num?)?.toInt(),
  timesUsed: (json['timesUsed'] as num?)?.toInt() ?? 0,
  expiryDate: DateTime.parse(json['expiryDate'] as String),
);

Map<String, dynamic> _$CouponToJson(_Coupon instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$DiscountTypeEnumMap[instance.type]!,
  'value': instance.value,
  'isActive': instance.isActive,
  'minOrderValue': instance.minOrderValue,
  'maxUses': instance.maxUses,
  'timesUsed': instance.timesUsed,
  'expiryDate': instance.expiryDate.toIso8601String(),
};

const _$DiscountTypeEnumMap = {
  DiscountType.percentage: 'percentage',
  DiscountType.fixedAmount: 'fixedAmount',
};
