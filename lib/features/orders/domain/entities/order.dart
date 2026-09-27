import 'package:equatable/equatable.dart';

import 'order_item.dart';
import 'order_status.dart';

class Order extends Equatable {
  const Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.counterpartName,
    required this.fulfillmentType,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
    this.deliveryAddress,
  });

  final String id;
  final String buyerId;
  final String sellerId;

  /// The other participant's name, from the current user's point of view
  /// (seller name if you're the buyer, buyer name if you're the seller).
  final String counterpartName;
  final String fulfillmentType;
  final String? deliveryAddress;
  final OrderStatus status;
  final double totalAmount;
  final DateTime createdAt;
  final List<OrderItem> items;

  @override
  List<Object?> get props => [
    id,
    buyerId,
    sellerId,
    counterpartName,
    fulfillmentType,
    deliveryAddress,
    status,
    totalAmount,
    createdAt,
    items,
  ];
}
