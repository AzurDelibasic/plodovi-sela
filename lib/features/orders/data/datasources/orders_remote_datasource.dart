import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/order_model.dart';

class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._client);

  final supabase.SupabaseClient _client;

  static const _selectColumns =
      'id, buyer_id, seller_id, fulfillment_type, delivery_address, status, '
      'total_amount, created_at, '
      'order_items(title_at_order, unit_price, quantity, subtotal), '
      'seller:profiles!orders_seller_profile_fkey(full_name), '
      'buyer:profiles!orders_buyer_profile_fkey(full_name)';

  Future<List<OrderModel>> getMyPurchases() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final rows = await _client
          .from('orders')
          .select(_selectColumns)
          .eq('buyer_id', userId)
          .order('created_at', ascending: false);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map((json) => OrderModel.fromJson(json, isBuyerView: true))
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<OrderModel>> getMySales() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final rows = await _client
          .from('orders')
          .select(_selectColumns)
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map((json) => OrderModel.fromJson(json, isBuyerView: false))
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _client.rpc(
        'update_order_status',
        params: {'p_order_id': orderId, 'p_new_status': newStatus},
      );
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
