import '../../onboarding/domain/onboarding_models.dart';
import '../../portfolio/domain/portfolio_project.dart';
import 'brief.dart';

enum OpportunityFocus { all, nearby, fresh, thisWeek, notApplied }

enum OpportunityRecency { any, today, thisWeek, thisMonth }

enum OpportunitySort { recommended, newest }

enum OpportunityRecommendationReason {
  specialtyMatch,
  serviceAreaMatch,
  similarPortfolio,
  fresh,
  projectPhotos,
}

enum CompetitionLevel { unknown, low, medium, high }

/// The backend does not currently expose offer counts. Callers must keep the
/// competition state unknown until a real count is available.
CompetitionLevel classifyCompetitionLevel(int? activeOffers) {
  if (activeOffers == null) return CompetitionLevel.unknown;
  if (activeOffers <= 4) return CompetitionLevel.low;
  if (activeOffers <= 9) return CompetitionLevel.medium;
  return CompetitionLevel.high;
}

class OpportunityFilters {
  const OpportunityFilters({
    this.focus = OpportunityFocus.all,
    this.specialties = const {},
    this.city,
    this.recency = OpportunityRecency.any,
    this.hideApplied = false,
    this.sort = OpportunitySort.recommended,
  });

  final OpportunityFocus focus;
  final Set<String> specialties;
  final String? city;
  final OpportunityRecency recency;
  final bool hideApplied;
  final OpportunitySort sort;

  bool get hasAdvancedFilters =>
      specialties.isNotEmpty ||
      city != null ||
      recency != OpportunityRecency.any ||
      hideApplied;

  int get advancedFilterCount =>
      specialties.length +
      (city == null ? 0 : 1) +
      (recency == OpportunityRecency.any ? 0 : 1) +
      (hideApplied ? 1 : 0);

  OpportunityFilters copyWith({
    OpportunityFocus? focus,
    Set<String>? specialties,
    OpportunityRecency? recency,
    bool? hideApplied,
    OpportunitySort? sort,
  }) => OpportunityFilters(
    focus: focus ?? this.focus,
    specialties: specialties ?? this.specialties,
    city: city,
    recency: recency ?? this.recency,
    hideApplied: hideApplied ?? this.hideApplied,
    sort: sort ?? this.sort,
  );

  OpportunityFilters withCity(String? value) => OpportunityFilters(
    focus: focus,
    specialties: specialties,
    city: value,
    recency: recency,
    hideApplied: hideApplied,
    sort: sort,
  );
}

class OpportunityFeedMetrics {
  const OpportunityFeedMetrics({
    required this.matchingCount,
    required this.freshCount,
    required this.areaCount,
  });

  final int matchingCount;
  final int freshCount;
  final int areaCount;
}

/// A truthful visual summary of the opportunities currently visible in the
/// feed. Each axis is a ratio of real, visible records rather than a claim
/// about a contractor's performance or an opaque recommendation percentage.
class OpportunityRadarMetrics {
  const OpportunityRadarMetrics({
    required this.matchingCount,
    required this.areaCount,
    required this.freshCount,
    required this.weekCount,
    required this.photoCount,
  });

  final int matchingCount;
  final int areaCount;
  final int freshCount;
  final int weekCount;
  final int photoCount;

  double get areaRatio => _ratio(areaCount, matchingCount);
  double get freshRatio => _ratio(freshCount, matchingCount);
  double get weekRatio => _ratio(weekCount, matchingCount);
  double get photoRatio => _ratio(photoCount, matchingCount);
}

class OpportunityMatch {
  const OpportunityMatch({required this.rank, required this.reasons});

  /// Internal deterministic rank used only to order recommendations. It is not
  /// shown as an AI percentage because the current schema is too sparse for a
  /// defensible precision claim.
  final int rank;
  final List<OpportunityRecommendationReason> reasons;

  bool get isStrong => rank >= 70;
}

OpportunityMatch calculateOpportunityMatch({
  required Brief brief,
  ContractorProfile? contractor,
  List<PortfolioProject> portfolio = const [],
  DateTime? now,
}) {
  final reasons = <OpportunityRecommendationReason>[];
  var rank = 0;

  if (contractor != null &&
      _hasIntersection(brief.targetSpecialties, contractor.specialties)) {
    rank += 50;
    reasons.add(OpportunityRecommendationReason.specialtyMatch);
  }

  if (contractor != null && contractor.serviceAreas.contains(brief.city)) {
    rank += 30;
    reasons.add(OpportunityRecommendationReason.serviceAreaMatch);
  }

  final portfolioCategories = portfolio
      .map((project) => project.category)
      .whereType<String>()
      .toList();
  if (_hasIntersection(brief.targetSpecialties, portfolioCategories)) {
    rank += 15;
    reasons.add(OpportunityRecommendationReason.similarPortfolio);
  }

  final age = (now ?? DateTime.now()).difference(brief.createdAt);
  if (!age.isNegative && age <= const Duration(hours: 24)) {
    rank += 5;
    reasons.add(OpportunityRecommendationReason.fresh);
  }

  if (brief.photoUrls.isNotEmpty) {
    reasons.add(OpportunityRecommendationReason.projectPhotos);
  }

  return OpportunityMatch(rank: rank, reasons: reasons);
}

int opportunityPreferenceCompletion(ContractorProfile? contractor) {
  if (contractor == null) return 0;
  var completion = 0;
  if (contractor.specialties.isNotEmpty) completion += 50;
  if (contractor.serviceAreas.isNotEmpty) completion += 50;
  return completion;
}

List<Brief> sortOpportunities({
  required Iterable<Brief> opportunities,
  required OpportunitySort sort,
  required ContractorProfile? contractor,
  List<PortfolioProject> portfolio = const [],
  DateTime? now,
}) {
  final sorted = [...opportunities];
  sorted.sort((a, b) {
    final primary = switch (sort) {
      OpportunitySort.recommended =>
        calculateOpportunityMatch(
          brief: b,
          contractor: contractor,
          portfolio: portfolio,
          now: now,
        ).rank.compareTo(
          calculateOpportunityMatch(
            brief: a,
            contractor: contractor,
            portfolio: portfolio,
            now: now,
          ).rank,
        ),
      OpportunitySort.newest => b.createdAt.compareTo(a.createdAt),
    };
    if (primary != 0) return primary;

    final created = b.createdAt.compareTo(a.createdAt);
    if (created != 0) return created;
    return b.id.compareTo(a.id);
  });
  return sorted;
}

List<Brief> mergeUniqueOpportunityPages(
  Iterable<Brief> current,
  Iterable<Brief> next,
) {
  final merged = [...current];
  final ids = merged.map((brief) => brief.id).toSet();
  for (final brief in next) {
    if (ids.add(brief.id)) merged.add(brief);
  }
  return merged;
}

OpportunityFeedMetrics calculateOpportunityFeedMetrics({
  required Iterable<Brief> opportunities,
  required ContractorProfile? contractor,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final items = opportunities.toList(growable: false);
  return OpportunityFeedMetrics(
    matchingCount: items.length,
    freshCount: items.where((brief) {
      final age = current.difference(brief.createdAt);
      return !age.isNegative && age <= const Duration(hours: 24);
    }).length,
    areaCount: items
        .where(
          (brief) => contractor?.serviceAreas.contains(brief.city) ?? false,
        )
        .length,
  );
}

OpportunityRadarMetrics calculateOpportunityRadarMetrics({
  required Iterable<Brief> opportunities,
  required ContractorProfile? contractor,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final items = opportunities.toList(growable: false);
  final areas = contractor?.serviceAreas ?? const <String>[];

  return OpportunityRadarMetrics(
    matchingCount: items.length,
    areaCount: items.where((brief) => areas.contains(brief.city)).length,
    freshCount: items.where((brief) {
      final age = current.difference(brief.createdAt);
      return !age.isNegative && age <= const Duration(hours: 24);
    }).length,
    weekCount: items.where((brief) {
      final age = current.difference(brief.createdAt);
      return !age.isNegative && age <= const Duration(days: 7);
    }).length,
    photoCount: items.where((brief) => brief.photoUrls.isNotEmpty).length,
  );
}

bool opportunityMatchesFilters({
  required Brief brief,
  required OpportunityFilters filters,
  ContractorProfile? contractor,
  Set<String> appliedBriefIds = const {},
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final age = current.difference(brief.createdAt);
  final applied = appliedBriefIds.contains(brief.id);

  if (filters.focus == OpportunityFocus.nearby &&
      !(contractor?.serviceAreas.contains(brief.city) ?? false)) {
    return false;
  }
  if (filters.focus == OpportunityFocus.fresh &&
      (age.isNegative || age > const Duration(hours: 24))) {
    return false;
  }
  if (filters.focus == OpportunityFocus.thisWeek &&
      (age.isNegative || age > const Duration(days: 7))) {
    return false;
  }
  if (filters.focus == OpportunityFocus.notApplied && applied) return false;
  if (filters.hideApplied && applied) return false;
  if (filters.city != null && brief.city != filters.city) return false;
  if (filters.specialties.isNotEmpty &&
      !_hasIntersection(brief.targetSpecialties, filters.specialties)) {
    return false;
  }

  final maxAge = switch (filters.recency) {
    OpportunityRecency.any => null,
    OpportunityRecency.today => const Duration(hours: 24),
    OpportunityRecency.thisWeek => const Duration(days: 7),
    OpportunityRecency.thisMonth => const Duration(days: 30),
  };
  if (maxAge != null && (age.isNegative || age > maxAge)) return false;
  return true;
}

String opportunityHeadline(String description, {int maxLength = 64}) {
  final normalized = description.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return '';
  final stop = normalized.indexOf(RegExp(r'[.!؟\n]'));
  final candidate = stop > 8 ? normalized.substring(0, stop) : normalized;
  if (candidate.length <= maxLength) return candidate;
  return '${candidate.substring(0, maxLength - 1).trimRight()}…';
}

double _ratio(int numerator, int denominator) {
  if (denominator <= 0) return 0;
  return (numerator / denominator).clamp(0, 1).toDouble();
}

bool _hasIntersection(Iterable<String> left, Iterable<String> right) {
  final normalizedRight = right.map(_normalizeTaxonomyValue).toSet();
  return left.map(_normalizeTaxonomyValue).any(normalizedRight.contains);
}

String _normalizeTaxonomyValue(String value) => value.trim().toLowerCase();
