import 'package:freezed_annotation/freezed_annotation.dart';
import 'order_item.dart';
import 'address.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled
}

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required String customerId,
    @Default(OrderStatus.pending) OrderStatus status,
    required List<OrderItem> items,
    required Address shippingAddress,
    required double totalAmount,
    String? trackingNumber,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
