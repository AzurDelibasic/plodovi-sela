import 'package:fpdart/fpdart.dart' hide Order;

import '../../../../core/error/failures.dart';
import '../entities/order.dart';

abstract interface class OrdersRepository {
  /// Orders where the current user is the buyer.
  Future<Either<Failure, List<Order>>> getMyPurchases();

  /// Orders where the current user is the seller.
  Future<Either<Failure, List<Order>>> getMySales();

  Future<Either<Failure, Unit>> updateOrderStatus(
    String orderId,
    String newStatus,
  );
}
