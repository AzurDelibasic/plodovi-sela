import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../../../listings/data/models/listing_model.dart';
import '../models/farm_image_model.dart';
import '../models/farm_model.dart';
import '../models/seller_review_model.dart';

class FarmsRemoteDataSource {
  FarmsRemoteDataSource(this._client);

  final supabase.SupabaseClient _client;

  String _resolveFarmImageUrl(String path) =>
      _client.storage.from('farm-images').getPublicUrl(path);

  /// One query for every seller's gallery, grouped client-side — avoids an
  /// N+1 round-trip per farm on the directory screen.
  Future<Map<String, List<String>>> _imagesBySeller(
    List<String> sellerIds,
  ) async {
    if (sellerIds.isEmpty) return {};
    final rows = await _client
        .from('farm_images')
        .select('seller_id, storage_path, position')
        .inFilter('seller_id', sellerIds)
        .order('position');

    final bySeller = <String, List<String>>{};
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      final sellerId = row['seller_id'] as String;
      (bySeller[sellerId] ??= []).add(
        _resolveFarmImageUrl(row['storage_path'] as String),
      );
    }
    return bySeller;
  }

  Future<List<FarmModel>> getFarms() async {
    try {
      final rows = await _client
          .from('seller_public_profiles')
          .select()
          .order('avg_rating', ascending: false);
      final list = (rows as List).cast<Map<String, dynamic>>();

      final imagesBySeller = await _imagesBySeller([
        for (final row in list) row['id'] as String,
      ]);

      return [
        for (final row in list)
          FarmModel.fromJson(
            row,
            imageUrls: imagesBySeller[row['id']] ?? const [],
          ),
      ];
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<FarmModel> getFarm(String sellerId) async {
    try {
      final row = await _client
          .from('seller_public_profiles')
          .select()
          .eq('id', sellerId)
          .single();
      final imagesBySeller = await _imagesBySeller([sellerId]);
      return FarmModel.fromJson(
        row,
        imageUrls: imagesBySeller[sellerId] ?? const [],
      );
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<FarmImageModel>> getMyFarmImages() async {
    try {
      final sellerId = _client.auth.currentUser?.id;
      if (sellerId == null) {
        throw const ServerException('Niste prijavljeni.');
      }
      final rows = await _client
          .from('farm_images')
          .select('id, storage_path')
          .eq('seller_id', sellerId)
          .order('position');

      return [
        for (final row in (rows as List).cast<Map<String, dynamic>>())
          FarmImageModel(
            id: row['id'] as String,
            url: _resolveFarmImageUrl(row['storage_path'] as String),
          ),
      ];
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<FarmImageModel> addFarmImage(Uint8List bytes) async {
    try {
      final sellerId = _client.auth.currentUser?.id;
      if (sellerId == null) {
        throw const ServerException('Niste prijavljeni.');
      }

      final existing = await _client
          .from('farm_images')
          .select('id')
          .eq('seller_id', sellerId);
      final position = (existing as List).length;

      final path = '$sellerId/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await _client.storage
          .from('farm-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const supabase.FileOptions(
              contentType: 'image/jpeg',
            ),
          );

      final inserted = await _client
          .from('farm_images')
          .insert({
            'seller_id': sellerId,
            'storage_path': path,
            'position': position,
          })
          .select('id')
          .single();

      return FarmImageModel(
        id: inserted['id'] as String,
        url: _resolveFarmImageUrl(path),
      );
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on supabase.StorageException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> removeFarmImage(String imageId) async {
    try {
      final row = await _client
          .from('farm_images')
          .select('storage_path')
          .eq('id', imageId)
          .single();
      await _client.from('farm_images').delete().eq('id', imageId);
      await _client.storage.from('farm-images').remove([
        row['storage_path'] as String,
      ]);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on supabase.StorageException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<ListingModel>> getFarmListings(String sellerId) async {
    try {
      final rows = await _client
          .from('listings')
          .select(
            'id, seller_id, title, description, price, unit, category_id, '
            'is_organic, pickup_available, delivery_available, '
            'categories(name), cities(name), profiles(full_name), '
            'listing_images(storage_path, position)',
          )
          .eq('status', 'active')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(
            (row) => ListingModel.fromJson(
              row,
              resolveImageUrl: (path) =>
                  _client.storage.from('listing-images').getPublicUrl(path),
            ),
          )
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<SellerReviewModel>> getFarmReviews(String sellerId) async {
    try {
      final rows = await _client
          .from('seller_reviews')
          .select('rating, comment, created_at')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(SellerReviewModel.fromJson)
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
