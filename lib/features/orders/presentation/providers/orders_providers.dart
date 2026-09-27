import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/datasources/orders_remote_datasource.dart';
import '../../data/repositories/orders_repository_impl.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>((ref) {
  return OrdersRemoteDataSource(ref.watch(supabaseClientProvider));
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(ref.watch(ordersRemoteDataSourceProvider));
});

final myPurchasesProvider = FutureProvider.autoDispose<List<Order>>((
  ref,
) async {
  final result = await ref.watch(ordersRepositoryProvider).getMyPurchases();
  return result.fold((failure) => throw failure, (orders) => orders);
});

final mySalesProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final result = await ref.watch(ordersRepositoryProvider).getMySales();
  return result.fold((failure) => throw failure, (orders) => orders);
});
