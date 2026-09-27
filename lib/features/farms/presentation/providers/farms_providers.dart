import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../data/datasources/farms_remote_datasource.dart';
import '../../data/repositories/farms_repository_impl.dart';
import '../../domain/entities/farm.dart';
import '../../domain/entities/seller_review.dart';
import '../../domain/repositories/farms_repository.dart';

final farmsRemoteDataSourceProvider = Provider<FarmsRemoteDataSource>((ref) {
  return FarmsRemoteDataSource(ref.watch(supabaseClientProvider));
});

final farmsRepositoryProvider = Provider<FarmsRepository>((ref) {
  return FarmsRepositoryImpl(ref.watch(farmsRemoteDataSourceProvider));
});

final farmsListProvider = FutureProvider.autoDispose<List<Farm>>((ref) async {
  final result = await ref.watch(farmsRepositoryProvider).getFarms();
  return result.fold((failure) => throw failure, (farms) => farms);
});

final farmProvider = FutureProvider.autoDispose.family<Farm, String>((
  ref,
  sellerId,
) async {
  final result = await ref.watch(farmsRepositoryProvider).getFarm(sellerId);
  return result.fold((failure) => throw failure, (farm) => farm);
});

final farmListingsProvider = FutureProvider.autoDispose
    .family<List<Listing>, String>((ref, sellerId) async {
      final result = await ref
          .watch(farmsRepositoryProvider)
          .getFarmListings(sellerId);
      return result.fold((failure) => throw failure, (listings) => listings);
    });

final farmReviewsProvider = FutureProvider.autoDispose
    .family<List<SellerReview>, String>((ref, sellerId) async {
      final result = await ref
          .watch(farmsRepositoryProvider)
          .getFarmReviews(sellerId);
      return result.fold((failure) => throw failure, (reviews) => reviews);
    });
