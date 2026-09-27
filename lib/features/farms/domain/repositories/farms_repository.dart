import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../listings/domain/entities/listing.dart';
import '../entities/farm.dart';
import '../entities/farm_image.dart';
import '../entities/seller_review.dart';

abstract interface class FarmsRepository {
  Future<Either<Failure, List<Farm>>> getFarms();

  Future<Either<Failure, Farm>> getFarm(String sellerId);

  Future<Either<Failure, List<Listing>>> getFarmListings(String sellerId);

  Future<Either<Failure, List<SellerReview>>> getFarmReviews(String sellerId);

  /// The caller's own farm gallery — used by the profile-edit screen to
  /// manage it (as opposed to [Farm.imageUrls], the read-only display copy).
  Future<Either<Failure, List<FarmImage>>> getMyFarmImages();

  Future<Either<Failure, FarmImage>> addFarmImage(Uint8List bytes);

  Future<Either<Failure, Unit>> removeFarmImage(String imageId);
}
