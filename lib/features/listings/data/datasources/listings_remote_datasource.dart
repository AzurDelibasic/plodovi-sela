import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/cart_item_model.dart';
import '../models/category_model.dart';
import '../models/city_model.dart';
import '../models/listing_model.dart';

const _listingSelect =
    'id, seller_id, title, description, price, unit, category_id, '
    'is_organic, pickup_available, delivery_available, '
    'categories(name), cities(name), profiles(full_name), '
    'listing_images(storage_path, position)';

class ListingsRemoteDataSource {
  ListingsRemoteDataSource(this._client);

  final supabase.SupabaseClient _client;

  String _resolveImageUrl(String path) =>
      _client.storage.from('listing-images').getPublicUrl(path);

  Future<List<ListingModel>> getActiveListings() async {
    try {
      final rows = await _client
          .from('listings')
          .select(_listingSelect)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(
            (row) => ListingModel.fromJson(
              row,
              resolveImageUrl: _resolveImageUrl,
            ),
          )
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Inserts a new listing owned by the caller, uploads its photos (if any)
  /// to the `listing-images` bucket under `<sellerId>/<listingId>/`, then
  /// links them via `listing_images` rows. Returns the listing exactly as
  /// [getActiveListings] would return it, images included.
  Future<ListingModel> createListing({
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
      final sellerId = _client.auth.currentUser?.id;
      if (sellerId == null) {
        throw const ServerException('Niste prijavljeni.');
      }

      final inserted = await _client
          .from('listings')
          .insert({
            'seller_id': sellerId,
            'title': title,
            'description': description,
            'price': price,
            'unit': unit,
            'category_id': categoryId,
            'city_id': cityId,
            'is_organic': isOrganic,
            'pickup_available': pickupAvailable,
            'delivery_available': deliveryAvailable,
          })
          .select('id')
          .single();
      final listingId = inserted['id'] as String;

      for (var i = 0; i < images.length; i++) {
        final path = '$sellerId/$listingId/$i.jpg';
        await _client.storage
            .from('listing-images')
            .uploadBinary(
              path,
              images[i],
              fileOptions: const supabase.FileOptions(
                contentType: 'image/jpeg',
              ),
            );
        await _client.from('listing_images').insert({
          'listing_id': listingId,
          'storage_path': path,
          'position': i,
        });
      }

      final row = await _client
          .from('listings')
          .select(_listingSelect)
          .eq('id', listingId)
          .single();
      return ListingModel.fromJson(row, resolveImageUrl: _resolveImageUrl);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on supabase.StorageException catch (e) {
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
