import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/cart_item_model.dart';
import '../models/category_model.dart';
import '../models/city_model.dart';
import '../models/listing_model.dart';

class ListingsRemoteDataSource {
  ListingsRemoteDataSource(this._client);

  final supabase.SupabaseClient _client;

  Future<List<ListingModel>> getActiveListings() async {
    try {
      final rows = await _client
          .from('listings')
          .select(
            'id, seller_id, title, description, price, unit, category_id, '
            'is_organic, pickup_available, delivery_available, '
            'categories(name), cities(name), profiles(full_name)',
          )
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(ListingModel.fromJson)
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final rows = await _client
          .from('categories')
          .select('id, name')
          .order('sort_order');

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<CityModel>> getCities() async {
    try {
      final rows = await _client
          .from('cities')
          .select('id, name')
          .order('name');

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(CityModel.fromJson)
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> addToCart(String listingId) async {
    try {
      await _client.rpc(
        'add_to_cart',
        params: {'p_listing_id': listingId, 'p_quantity': 1},
      );
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<int> getCartItemCount() async {
    try {
      final rows = await _client.from('cart_items').select('listing_id');
      return (rows as List).length;
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<CartItemModel>> getCartItems() async {
    try {
      final rows = await _client
          .from('cart_items')
          .select(
            'listing_id, quantity, '
            'listings(title, price, unit, pickup_available, delivery_available, profiles(full_name))',
          )
          .order('added_at');

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(CartItemModel.fromJson)
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> updateCartItemQuantity(String listingId, double quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(listingId);
        return;
      }
      await _client
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('listing_id', listingId);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> removeFromCart(String listingId) async {
    try {
      await _client.from('cart_items').delete().eq('listing_id', listingId);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<String>> checkout({
    required String fulfillmentType,
    String? deliveryAddress,
  }) async {
    try {
      final result = await _client.rpc(
        'checkout',
        params: {
          'p_fulfillment_type': fulfillmentType,
          'p_delivery_address': deliveryAddress,
        },
      );
      return (result as List).cast<String>();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
