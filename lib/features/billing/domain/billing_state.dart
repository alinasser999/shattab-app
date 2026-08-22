/// Server-owned subscription state returned by `get_my_billing_state`.
///
/// A submitted payment request is not proof of an active subscription. The
/// active flag is derived from the approved contractor plan and its expiry;
/// request data is exposed only to explain what is happening next.
class BillingState {
  const BillingState({
    this.plan = 'free',
    this.planExpiresAt,
    this.sponsoredUntil,
    this.latestRequest,
    this.latestPayment,
  });

  factory BillingState.fromJson(Map<String, dynamic> json) {
    return BillingState(
      plan: json['plan'] as String? ?? 'free',
      planExpiresAt: _parseDate(json['plan_expires_at']),
      sponsoredUntil: _parseDate(json['sponsored_until']),
      latestRequest: _mapValue(json['latest_request'], BillingRequest.fromJson),
      latestPayment: _mapValue(json['latest_payment'], BillingPayment.fromJson),
    );
  }

  final String plan;
  final DateTime? planExpiresAt;
  final DateTime? sponsoredUntil;
  final BillingRequest? latestRequest;
  final BillingPayment? latestPayment;

  bool get isProActive =>
      plan == 'pro' &&
      planExpiresAt != null &&
      planExpiresAt!.isAfter(DateTime.now());

  bool get hasPendingProRequest =>
      latestRequest?.purpose == 'pro' && latestRequest?.status == 'pending';

  bool get isSponsoredActive =>
      sponsoredUntil != null && sponsoredUntil!.isAfter(DateTime.now());

  bool get hasPendingSponsoredRequest =>
      latestRequest?.purpose == 'sponsored' &&
      latestRequest?.status == 'pending';

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static T? _mapValue<T>(
    Object? value,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (value is! Map || value.isEmpty) return null;
    final map = Map<String, dynamic>.from(value);
    if ((map['id'] as String?)?.isNotEmpty != true) return null;
    return parse(map);
  }
}

class BillingRequest {
  const BillingRequest({
    required this.id,
    required this.status,
    required this.purpose,
    this.planTerm,
    this.amountEgp,
    this.rejectReason,
    this.createdAt,
    this.reviewedAt,
  });

  factory BillingRequest.fromJson(Map<String, dynamic> json) {
    return BillingRequest(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      purpose: json['purpose'] as String? ?? 'pro',
      planTerm: json['plan_term'] as String?,
      amountEgp: (json['amount_egp'] as num?)?.toInt(),
      rejectReason: json['reject_reason'] as String?,
      createdAt: BillingState._parseDate(json['created_at']),
      reviewedAt: BillingState._parseDate(json['reviewed_at']),
    );
  }

  final String id;
  final String status;
  final String purpose;
  final String? planTerm;
  final int? amountEgp;
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
}

class BillingPayment {
  const BillingPayment({
    required this.id,
    required this.status,
    required this.purpose,
    this.amountPiastres,
    this.periodEnd,
    this.createdAt,
  });

  factory BillingPayment.fromJson(Map<String, dynamic> json) {
    return BillingPayment(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      purpose: json['purpose'] as String? ?? 'pro',
      amountPiastres: (json['amount_piastres'] as num?)?.toInt(),
      periodEnd: BillingState._parseDate(json['period_end']),
      createdAt: BillingState._parseDate(json['created_at']),
    );
  }

  final String id;
  final String status;
  final String purpose;
  final int? amountPiastres;
  final DateTime? periodEnd;
  final DateTime? createdAt;
}
