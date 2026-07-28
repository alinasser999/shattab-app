enum QuoteStatus {
  sent,
  accepted,
  declined,
  withdrawn;

  static QuoteStatus fromString(String value) => QuoteStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => QuoteStatus.sent,
  );
}

/// A contractor's price/timeline proposal on a [Brief].
/// One quote per contractor per brief (enforced by a unique constraint).
class Quote {
  const Quote({
    required this.id,
    required this.briefId,
    required this.contractorId,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.priceMin,
    this.priceMax,
    this.durationText,
  });

  final String id;
  final String briefId;
  final String contractorId;
  final int? priceMin; // EGP
  final int? priceMax; // EGP
  final String? durationText;
  final String note;
  final QuoteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasPrice => priceMin != null || priceMax != null;
  bool get isFixedPrice =>
      priceMin != null && priceMax != null && priceMin == priceMax;

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    id: json['id'] as String,
    briefId: json['brief_id'] as String,
    contractorId: json['contractor_id'] as String,
    priceMin: json['price_min'] as int?,
    priceMax: json['price_max'] as int?,
    durationText: json['duration_text'] as String?,
    note: json['note'] as String,
    status: QuoteStatus.fromString(json['status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Quote copyWith({
    int? priceMin,
    int? priceMax,
    String? durationText,
    String? note,
    QuoteStatus? status,
  }) => Quote(
    id: id,
    briefId: briefId,
    contractorId: contractorId,
    priceMin: priceMin ?? this.priceMin,
    priceMax: priceMax ?? this.priceMax,
    durationText: durationText ?? this.durationText,
    note: note ?? this.note,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
