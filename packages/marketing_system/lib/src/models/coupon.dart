import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon.freezed.dart';
part 'coupon.g.dart';

enum DiscountType {
  percentage,
  fixedAmount
}

@freezed
abstract class Coupon with _$Coupon {
  const factory Coupon({
    required String id,
    required DiscountType type,
    required double value,
    @Default(true) bool isActive,
    double? minOrderValue,
    int? maxUses,
    @Default(0) int timesUsed,
    required DateTime expiryDate,
  }) = _Coupon;

  factory Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);
}
