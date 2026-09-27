import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import 'order_item_model.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.buyerId,
    required super.sellerId,
    required super.counterpartName,
    required super.fulfillmentType,
    required super.status,
    required super.totalAmount,
    required super.createdAt,
    required super.items,
    super.deliveryAddress,
  });

  /// [isBuyerView] picks which side's name is shown as the "counterpart" —
  /// the seller's name when you're the buyer, and vice versa.
  factory OrderModel.fromJson(
    Map<String, dynamic> json, {
    required bool isBuyerView,
  }) {
    final counterpart = isBuyerView
        ? json['seller'] as Map<String, dynamic>?
        : json['buyer'] as Map<String, dynamic>?;
    final counterpartName = (counterpart?['full_name'] as String?)?.trim();
    final items = (json['order_items'] as List)
        .cast<Map<String, dynamic>>()
        .map(OrderItemModel.fromJson)
        .toList();

    return OrderModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      counterpartName: (counterpartName == null || counterpartName.isEmpty)
          ? (isBuyerView ? 'Prodavac' : 'Kupac')
          : counterpartName,
      fulfillmentType: json['fulfillment_type'] as String,
      deliveryAddress: json['delivery_address'] as String?,
      status: OrderStatus.fromDb(json['status'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      items: items,
    );
  }
}
