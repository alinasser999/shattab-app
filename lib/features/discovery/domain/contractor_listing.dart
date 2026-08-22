import 'package:flutter/material.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';

/// Joined view of a contractor — `profiles` row + `contractor_profiles` row.
class ContractorListing {
  const ContractorListing({
    required this.id,
    required this.fullName,
    required this.businessName,
    this.phone = '',
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
    this.planExpiresAt,
    this.isSponsored = false,
    this.memberSince,
    this.providerKind = ProviderKind.contractor,
  });

  final String id;
  final String fullName;
  final String businessName;

  /// Loaded only for an explicit profile/contact surface, never for catalogue
  /// cards. Keeping this optional prevents a list query from becoming a phone
  /// directory and reduces the payload for the most frequently used request.
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

  /// When the Pro subscription lapses. Mirrored from contractor_profiles by
  /// the catalogue RPCs; null for free plans and for rows cached before the
  /// field shipped.
  final DateTime? planExpiresAt;

  /// Paid catalogue placement. This is deliberately separate from earned
  /// verification/tier signals and must always be rendered with disclosure.
  final bool isSponsored;

  /// When the contractor profile was created — powers "member since".
  final DateTime? memberSince;

  /// What this professional calls themselves.
  ///
  /// The account role is one thing technically; this is only the label. An
  /// engineering office and a tradesman have identical capabilities in the app
  /// — but calling both of them "مقاول" reads as a demotion to the former, and
  /// the better-credentialled supply is exactly the supply worth keeping.
  final ProviderKind providerKind;

  /// Active Pro = plan 'pro' and not expired, same rule as
  /// ContractorProfile.isPro and BillingState.isProActive. Before the
  /// expiry field shipped through the catalogue RPCs this checked the plan
  /// flag alone, so an expired-but-unflipped row rendered paid badges.
  bool get isPro =>
      plan == 'pro' &&
      planExpiresAt != null &&
      planExpiresAt!.isAfter(DateTime.now());

  ContractorListing copyWith({String? phone}) => ContractorListing(
    id: id,
    fullName: fullName,
    businessName: businessName,
    phone: phone ?? this.phone,
    specialties: specialties,
    serviceAreas: serviceAreas,
    projectsCompleted: projectsCompleted,
    bio: bio,
    logoUrl: logoUrl,
    coverPhotoUrl: coverPhotoUrl,
    headline: headline,
    yearsExperience: yearsExperience,
    reviewCount: reviewCount,
    reviewAvg: reviewAvg,
    verified: verified,
    plan: plan,
    planExpiresAt: planExpiresAt,
    isSponsored: isSponsored,
    memberSince: memberSince,
    providerKind: providerKind,
  );

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
      serviceAreas: ((cp?['service_areas'] as List?) ?? const [])
          .cast<String>(),
      yearsExperience: cp?['years_experience'] as int?,
      projectsCompleted: (cp?['projects_completed'] as int?) ?? 0,
      reviewCount: reviewCount,
      reviewAvg: reviewAvg,
      verified: (cp?['verified'] as bool?) ?? false,
      plan: (cp?['plan'] as String?) ?? 'free',
      planExpiresAt: switch (cp?['plan_expires_at']) {
        final String s => DateTime.tryParse(s),
        _ => null,
      },
      isSponsored: (json['is_sponsored'] as bool?) ?? false,
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

  String label(BuildContext context) => switch (this) {
    ContractorTier.gold => context.l10n.tierGold,
    ContractorTier.silver => context.l10n.tierSilver,
    ContractorTier.bronze => context.l10n.tierBronze,
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
  String label(BuildContext context) => switch (this) {
    ProviderKind.contractor => context.l10n.providerKindContractor,
    ProviderKind.engineer => context.l10n.providerKindEngineer,
    ProviderKind.engineeringOffice =>
      context.l10n.providerKindEngineeringOffice,
    ProviderKind.finishingCompany => context.l10n.providerKindFinishingCompany,
    ProviderKind.interiorDesigner => context.l10n.providerKindInteriorDesigner,
    ProviderKind.tradesman => context.l10n.providerKindTradesman,
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
