import 'package:equatable/equatable.dart';

/// A seller's public storefront — backed by `public.seller_public_profiles`.
class Farm extends Equatable {
  const Farm({
    required this.id,
    required this.name,
    required this.avgRating,
    required this.reviewCount,
    this.avatarUrl,
    this.bio,
    this.cityName,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final String? cityName;
  final double avgRating;
  final int reviewCount;

  @override
  List<Object?> get props => [
    id,
    name,
    avatarUrl,
    bio,
    cityName,
    avgRating,
    reviewCount,
  ];
}
