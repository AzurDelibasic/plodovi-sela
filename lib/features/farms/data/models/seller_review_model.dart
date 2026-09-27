import '../../domain/entities/seller_review.dart';

class SellerReviewModel extends SellerReview {
  const SellerReviewModel({
    required super.rating,
    required super.createdAt,
    super.comment,
  });

  factory SellerReviewModel.fromJson(Map<String, dynamic> json) {
    return SellerReviewModel(
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
