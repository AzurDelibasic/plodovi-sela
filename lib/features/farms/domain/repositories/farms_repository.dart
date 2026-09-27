import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../listings/domain/entities/listing.dart';
import '../entities/farm.dart';
import '../entities/seller_review.dart';

abstract interface class FarmsRepository {
  Future<Either<Failure, List<Farm>>> getFarms();

  Future<Either<Failure, Farm>> getFarm(String sellerId);

  Future<Either<Failure, List<Listing>>> getFarmListings(String sellerId);

  Future<Either<Failure, List<SellerReview>>> getFarmReviews(String sellerId);
}
