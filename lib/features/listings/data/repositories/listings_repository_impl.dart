import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listings_repository.dart';
import '../datasources/listings_remote_datasource.dart';

class ListingsRepositoryImpl implements ListingsRepository {
  ListingsRepositoryImpl(this._remote);

  final ListingsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Listing>>> getActiveListings() async {
    try {
      final listings = await _remote.getActiveListings();
      return Right(listings);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Listing>> createListing({
    required String title,
    String? description,
    required double price,
    required String unit,
    required int categoryId,
    required int cityId,
    required bool isOrganic,
    required bool pickupAvailable,
    required bool deliveryAvailable,
    required List<Uint8List> images,
  }) async {
    try {
      final listing = await _remote.createListing(
        title: title,
        description: description,
        price: price,
        unit: unit,
        categoryId: categoryId,
        cityId: cityId,
        isOrganic: isOrganic,
        pickupAvailable: pickupAvailable,
        deliveryAvailable: deliveryAvailable,
        images: images,
      );
      return Right(listing);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final categories = await _remote.getCategories();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<City>>> getCities() async {
    try {
      final cities = await _remote.getCities();
      return Right(cities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> addToCart(String listingId) async {
    try {
      await _remote.addToCart(listingId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, int>> getCartItemCount() async {
    try {
      final count = await _remote.getCartItemCount();
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<CartItem>>> getCartItems() async {
    try {
      final items = await _remote.getCartItems();
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updateCartItemQuantity(
    String listingId,
    double quantity,
  ) async {
    try {
      await _remote.updateCartItemQuantity(listingId, quantity);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> removeFromCart(String listingId) async {
    try {
      await _remote.removeFromCart(listingId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<String>>> checkout({
    required String fulfillmentType,
    String? deliveryAddress,
  }) async {
    try {
      final orderIds = await _remote.checkout(
        fulfillmentType: fulfillmentType,
        deliveryAddress: deliveryAddress,
      );
      return Right(orderIds);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
