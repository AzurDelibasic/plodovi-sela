import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../../../listings/data/models/listing_model.dart';
import '../models/farm_model.dart';
import '../models/seller_review_model.dart';

class FarmsRemoteDataSource {
  FarmsRemoteDataSource(this._client);

  final supabase.SupabaseClient _client;

  Future<List<FarmModel>> getFarms() async {
    try {
      final rows = await _client
          .from('seller_public_profiles')
          .select()
          .order('avg_rating', ascending: false);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(FarmModel.fromJson)
          .toList();
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
      return FarmModel.fromJson(row);
    } on supabase.PostgrestException catch (e) {
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
            'categories(name), cities(name), profiles(full_name)',
          )
          .eq('status', 'active')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(ListingModel.fromJson)
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
