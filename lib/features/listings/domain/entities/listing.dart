import 'package:equatable/equatable.dart';

class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.price,
    required this.unit,
    required this.categoryId,
    required this.categoryName,
    required this.cityName,
    required this.isOrganic,
    required this.pickupAvailable,
    required this.deliveryAvailable,
    this.description,
    this.imageUrls = const [],
  });

  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String? description;
  final double price;
  final String unit;
  final int categoryId;
  final String categoryName;
  final String cityName;
  final bool isOrganic;
  final bool pickupAvailable;
  final bool deliveryAvailable;

  /// Public URLs, ordered — empty when the seller hasn't attached photos.
  final List<String> imageUrls;

  @override
  List<Object?> get props => [
    id,
    sellerId,
    sellerName,
    title,
    description,
    price,
    unit,
    categoryId,
    categoryName,
    cityName,
    isOrganic,
    pickupAvailable,
    deliveryAvailable,
    imageUrls,
  ];
}
