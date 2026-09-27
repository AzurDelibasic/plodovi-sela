import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/cart_item.dart';
import '../entities/category.dart';
import '../entities/city.dart';
import '../entities/listing.dart';

abstract interface class ListingsRepository {
  /// Active listings, newest first.
  Future<Either<Failure, List<Listing>>> getActiveListings();

  Future<Either<Failure, List<Category>>> getCategories();

  Future<Either<Failure, List<City>>> getCities();

  Future<Either<Failure, Unit>> addToCart(String listingId);

  Future<Either<Failure, int>> getCartItemCount();

  Future<Either<Failure, List<CartItem>>> getCartItems();

  Future<Either<Failure, Unit>> updateCartItemQuantity(
    String listingId,
    double quantity,
  );

  Future<Either<Failure, Unit>> removeFromCart(String listingId);

  /// Converts the cart into one order per seller. Returns the created order
  /// ids.
  Future<Either<Failure, List<String>>> checkout({
    required String fulfillmentType,
    String? deliveryAddress,
  });
}
