import '../../domain/entities/farm.dart';

class FarmModel extends Farm {
  const FarmModel({
    required super.id,
    required super.name,
    required super.avgRating,
    required super.reviewCount,
    super.avatarUrl,
    super.bio,
    super.cityName,
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    final name = (json['full_name'] as String?)?.trim();
    return FarmModel(
      id: json['id'] as String,
      name: (name == null || name.isEmpty) ? 'Farma' : name,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      cityName: json['city_name'] as String?,
      avgRating: (json['avg_rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
    );
  }
}
