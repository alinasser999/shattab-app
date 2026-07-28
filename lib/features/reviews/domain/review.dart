/// A homeowner's rating of a contractor, tied to one brief.
/// One review per brief (enforced by a unique constraint).
class Review {
  const Review({
    required this.id,
    required this.briefId,
    required this.contractorId,
    required this.homeownerId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final String id;
  final String briefId;
  final String contractorId;
  final String homeownerId;
  final int rating; // 1..5
  final String? comment;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    briefId: json['brief_id'] as String,
    contractorId: json['contractor_id'] as String,
    homeownerId: json['homeowner_id'] as String,
    rating: (json['rating'] as num).toInt(),
    comment: json['comment'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
