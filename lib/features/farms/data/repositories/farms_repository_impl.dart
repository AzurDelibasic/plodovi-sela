import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/farm.dart';
import '../../domain/entities/seller_review.dart';
import '../../domain/repositories/farms_repository.dart';
import '../datasources/farms_remote_datasource.dart';

class FarmsRepositoryImpl implements FarmsRepository {
  FarmsRepositoryImpl(this._remote);

  final FarmsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Farm>>> getFarms() async {
    try {
      return Right(await _remote.getFarms());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Farm>> getFarm(String sellerId) async {
    try {
      return Right(await _remote.getFarm(sellerId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Listing>>> getFarmListings(
    String sellerId,
  ) async {
    try {
      return Right(await _remote.getFarmListings(sellerId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<SellerReview>>> getFarmReviews(
    String sellerId,
  ) async {
    try {
      return Right(await _remote.getFarmReviews(sellerId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
