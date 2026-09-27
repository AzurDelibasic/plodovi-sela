import '../../domain/entities/order_item.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.title,
    required super.unitPrice,
    required super.quantity,
    required super.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      title: json['title_at_order'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}
