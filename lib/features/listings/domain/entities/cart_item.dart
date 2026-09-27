import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.listingId,
    required this.title,
    required this.sellerName,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.pickupAvailable,
    required this.deliveryAvailable,
  });

  final String listingId;
  final String title;
  final String sellerName;
  final double price;
  final String unit;
  final double quantity;
  final bool pickupAvailable;
  final bool deliveryAvailable;

  double get subtotal => price * quantity;

  @override
  List<Object?> get props => [
    listingId,
    title,
    sellerName,
    price,
    unit,
    quantity,
    pickupAvailable,
    deliveryAvailable,
  ];
}
