import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';

/// Joined view of a contractor — `profiles` row + `contractor_profiles` row.
class ContractorListing {
  const ContractorListing({
    required this.id,
    required this.fullName,
    required this.businessName,
    required this.phone,
    required this.specialties,
    required this.serviceAreas,
    required this.projectsCompleted,
    this.bio,
    this.logoUrl,
    this.coverPhotoUrl,
    this.headline,
    this.yearsExperience,
    this.reviewCount = 0,
    this.reviewAvg = 0,
    this.verified = false,
    this.plan = 'free',
    this.memberSince,
    this.providerKind = ProviderKind.contractor,
  });

  final String id;
  final String fullName;
  final String businessName;
  final String phone;
  final List<String> specialties;
  final List<String> serviceAreas;
  final int projectsCompleted;

  // `response_rate` is intentionally not read. The column exists with a default
  // of 100, so it is a constant dressed as a measurement. Add it back when a
  // real brief-to-first-quote latency is tracked.

  final String? bio;
  final String? logoUrl;
  final String? coverPhotoUrl;
  final String? headline;
  final int? yearsExperience;
  final int reviewCount;
  final double reviewAvg;

  /// Verified badge — flipped by founder doc review (0015). Free, earned.
  final bool verified;

  /// Subscription plan: 'free' | 'pro'.
  final String plan;

  /// When the contractor profile was created — powers "member since".
  final DateTime? memberSince;

  /// What this professional calls themselves.
  ///
  /// The account role is one thing technically; this is only the label. An
  /// engineering office and a tradesman have identical capabilities in the app
  /// — but calling both of them "مقاول" reads as a demotion to the former, and
  /// the better-credentialled supply is exactly the supply worth keeping.
  final ProviderKind providerKind;

  bool get isPro => plan == 'pro';

  /// Trust tier derived from real signals. Gold = verified + a track record;
  /// silver = some jobs done; else bronze. No paid shortcut to gold.
  ContractorTier get tier {
    if (verified && (projectsCompleted >= 10 || reviewCount >= 5)) {
      return ContractorTier.gold;
    }
    if (projectsCompleted >= 3 || verified) return ContractorTier.silver;
    return ContractorTier.bronze;
  }

  /// True once at least one real review exists.
  bool get hasReviews => reviewCount > 0;

  /// Average rating, or null when nobody has reviewed this contractor yet.
  ///
  /// Deliberately has no fallback. The previous `displayRating` fell back to a
  /// `computedRating` heuristic seeded from `responseRate` (which defaulted to
  /// 100 for every row) and project count, clamped to 3.8-5.0. Every call site
  /// guarded the *display* of that number, but the discover shelf still sorted
  /// by it, so "الأعلى تقييماً" ranked unreviewed contractors by fiction.
  /// Nullable makes the absence a compile-time concern instead of a silent 4.4.
  double? get rating => hasReviews ? reviewAvg : null;

  factory ContractorListing.fromJoined(Map<String, dynamic> json) {
    // PostgREST embeds a to-one relation as an object, a to-many as a list.
    // contractor_profiles.id is PK+FK to profiles.id (one-to-one) → object,
    // but tolerate either shape so a relation re-detection can't crash us.
    final raw = json['contractor_profiles'];
    final cp = (raw is List ? raw.firstOrNull : raw) as Map<String, dynamic>?;
    // Rating is denormalized on contractor_profiles by the reviews_rollup
    // trigger — no per-card review embed to average client-side.
    final reviewCount = (cp?['rating_count'] as int?) ?? 0;
    final reviewAvg = ((cp?['rating_avg'] as num?) ?? 0).toDouble();
    return ContractorListing(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      businessName: (cp?['business_name'] as String?) ?? '',
      bio: cp?['bio'] as String?,
      logoUrl: cp?['logo_url'] as String?,
      coverPhotoUrl: cp?['cover_photo_url'] as String?,
      headline: cp?['headline'] as String?,
      specialties: ((cp?['specialties'] as List?) ?? const []).cast<String>(),
      serviceAreas: ((cp?['service_areas'] as List?) ?? const []).cast<String>(),
      yearsExperience: cp?['years_experience'] as int?,
      projectsCompleted: (cp?['projects_completed'] as int?) ?? 0,
      reviewCount: reviewCount,
      reviewAvg: reviewAvg,
      verified: (cp?['verified'] as bool?) ?? false,
      plan: (cp?['plan'] as String?) ?? 'free',
      providerKind: ProviderKind.fromWire(cp?['provider_kind'] as String?),
      memberSince: switch (cp?['created_at']) {
        final String s => DateTime.tryParse(s),
        _ => null,
      },
    );
  }
}

/// Trust tiers derived from completed work, reviews and verification.
///
/// Earned only — there is no purchase path to any tier, which is why the badge
/// that renders them (`TierBadge`) deliberately shares no visual language with
/// the paid Pro badge.
enum ContractorTier {
  bronze,
  silver,
  gold;

  String get label => switch (this) {
        ContractorTier.gold => S.tierGold,
        ContractorTier.silver => S.tierSilver,
        ContractorTier.bronze => S.tierBronze,
      };

  /// Whether the tier is worth showing to a homeowner.
  ///
  /// Bronze is the starting state of every account, so publishing it says
  /// nothing except "lowest of three" — the same cold-start mistake the rating
  /// pill already avoids with its neutral "جديد" state.
  bool get isPublic => this != ContractorTier.bronze;
}

/// A professional's self-declared identity.
///
/// Wire values match the `provider_kind` CHECK constraint in 0026 exactly — the
/// enum name *is* the stored string, so renaming a value here without a
/// migration would start writing rows the database rejects.
enum ProviderKind {
  contractor,
  engineer,
  engineeringOffice,
  finishingCompany,
  interiorDesigner,
  tradesman;

  /// snake_case value as stored in Postgres.
  String get wire => switch (this) {
        ProviderKind.contractor => 'contractor',
        ProviderKind.engineer => 'engineer',
        ProviderKind.engineeringOffice => 'engineering_office',
        ProviderKind.finishingCompany => 'finishing_company',
        ProviderKind.interiorDesigner => 'interior_designer',
        ProviderKind.tradesman => 'tradesman',
      };

  /// Unknown values fall back to `contractor` rather than throwing: a value
  /// added to the CHECK by a newer migration must not crash an older client.
  static ProviderKind fromWire(String? value) => switch (value) {
        'engineer' => ProviderKind.engineer,
        'engineering_office' => ProviderKind.engineeringOffice,
        'finishing_company' => ProviderKind.finishingCompany,
        'interior_designer' => ProviderKind.interiorDesigner,
        'tradesman' => ProviderKind.tradesman,
        _ => ProviderKind.contractor,
      };

  /// Localised label. Kept here so every surface that shows a kind reads the
  /// same words.
  String get label => switch (this) {
        ProviderKind.contractor => S.providerKindContractor,
        ProviderKind.engineer => S.providerKindEngineer,
        ProviderKind.engineeringOffice => S.providerKindEngineeringOffice,
        ProviderKind.finishingCompany => S.providerKindFinishingCompany,
        ProviderKind.interiorDesigner => S.providerKindInteriorDesigner,
        ProviderKind.tradesman => S.providerKindTradesman,
      };

  /// Icon paired with the label. Never rely on the icon alone — the pairing is
  /// what keeps the badge readable in greyscale and to screen readers.
  IconData get icon => switch (this) {
        ProviderKind.contractor => Icons.construction_outlined,
        ProviderKind.engineer => Icons.architecture_outlined,
        ProviderKind.engineeringOffice => Icons.domain_outlined,
        ProviderKind.finishingCompany => Icons.business_outlined,
        ProviderKind.interiorDesigner => Icons.chair_outlined,
        ProviderKind.tradesman => Icons.handyman_outlined,
      };
}
