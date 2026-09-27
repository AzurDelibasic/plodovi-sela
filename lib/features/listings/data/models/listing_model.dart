import '../../domain/entities/listing.dart';

class ListingModel extends Listing {
  const ListingModel({
    required super.id,
    required super.sellerId,
    required super.sellerName,
    required super.title,
    required super.price,
    required super.unit,
    required super.categoryId,
    required super.categoryName,
    required super.cityName,
    required super.isOrganic,
    required super.pickupAvailable,
    required super.deliveryAvailable,
    super.description,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    final city = json['cities'] as Map<String, dynamic>?;
    final seller = json['profiles'] as Map<String, dynamic>?;
    final sellerName = (seller?['full_name'] as String?)?.trim();

    return ListingModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      sellerName: (sellerName == null || sellerName.isEmpty)
          ? 'Prodavac'
          : sellerName,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      categoryId: json['category_id'] as int,
      categoryName: category?['name'] as String? ?? '',
      cityName: city?['name'] as String? ?? '',
      isOrganic: json['is_organic'] as bool,
      pickupAvailable: json['pickup_available'] as bool,
      deliveryAvailable: json['delivery_available'] as bool,
    );
  }
}
