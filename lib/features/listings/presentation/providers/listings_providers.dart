import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/datasources/listings_remote_datasource.dart';
import '../../data/repositories/listings_repository_impl.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listings_repository.dart';

final listingsRemoteDataSourceProvider = Provider<ListingsRemoteDataSource>((
  ref,
) {
  return ListingsRemoteDataSource(ref.watch(supabaseClientProvider));
});

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepositoryImpl(ref.watch(listingsRemoteDataSourceProvider));
});

final activeListingsProvider = FutureProvider.autoDispose<List<Listing>>((
  ref,
) async {
  final result = await ref
      .watch(listingsRepositoryProvider)
      .getActiveListings();
  return result.fold((failure) => throw failure, (listings) => listings);
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((
  ref,
) async {
  final result = await ref.watch(listingsRepositoryProvider).getCategories();
  return result.fold((failure) => throw failure, (categories) => categories);
});

final citiesProvider = FutureProvider.autoDispose<List<City>>((ref) async {
  final result = await ref.watch(listingsRepositoryProvider).getCities();
  return result.fold((failure) => throw failure, (cities) => cities);
});

final cartItemCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final result = await ref.watch(listingsRepositoryProvider).getCartItemCount();
  return result.fold((failure) => throw failure, (count) => count);
});

final cartItemsProvider = FutureProvider.autoDispose<List<CartItem>>((
  ref,
) async {
  final result = await ref.watch(listingsRepositoryProvider).getCartItems();
  return result.fold((failure) => throw failure, (items) => items);
});
