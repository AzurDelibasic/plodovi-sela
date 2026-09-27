import '../../domain/entities/cart_item.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.listingId,
    required super.title,
    required super.sellerName,
    required super.price,
    required super.unit,
    required super.quantity,
    required super.pickupAvailable,
    required super.deliveryAvailable,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final listing = json['listings'] as Map<String, dynamic>;
    final seller = listing['profiles'] as Map<String, dynamic>?;
    final sellerName = (seller?['full_name'] as String?)?.trim();

    return CartItemModel(
      listingId: json['listing_id'] as String,
      title: listing['title'] as String,
      sellerName: (sellerName == null || sellerName.isEmpty)
          ? 'Prodavac'
          : sellerName,
      price: (listing['price'] as num).toDouble(),
      unit: listing['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      pickupAvailable: listing['pickup_available'] as bool,
      deliveryAvailable: listing['delivery_available'] as bool,
    );
  }
}
