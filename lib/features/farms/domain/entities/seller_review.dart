import 'package:equatable/equatable.dart';

/// Reviewer identity is deliberately not included — buyer profiles are
/// private, so reviews are shown anonymously (rating + comment only).
class SellerReview extends Equatable {
  const SellerReview({
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final int rating;
  final String? comment;
  final DateTime createdAt;

  @override
  List<Object?> get props => [rating, comment, createdAt];
}
