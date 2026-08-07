import 'contractor_listing.dart';

/// Curates discovery shelves from real profile signals only.
///
/// The score is not shown to homeowners. It only prevents the featured slot
/// from changing with API order while favouring photography, verification,
/// reviews, and a completed-work record.
ContractorListing? pickFeaturedProfessional(
  Iterable<ContractorListing> professionals,
) {
  final candidates =
      professionals
          .where((professional) => professional.coverPhotoUrl != null)
          .toList()
        ..sort((a, b) {
          final byScore = _featuredScore(b).compareTo(_featuredScore(a));
          return byScore != 0 ? byScore : a.id.compareTo(b.id);
        });
  return candidates.firstOrNull;
}

List<ContractorListing> rankTopRated(
  Iterable<ContractorListing> professionals, {
  int limit = 6,
}) {
  final ranked = professionals.where((item) => item.hasReviews).toList()
    ..sort((a, b) {
      final byAverage = b.reviewAvg.compareTo(a.reviewAvg);
      if (byAverage != 0) return byAverage;
      final byCount = b.reviewCount.compareTo(a.reviewCount);
      return byCount != 0 ? byCount : a.id.compareTo(b.id);
    });
  return ranked.take(limit).toList();
}

List<ContractorListing> rankNearbyProfessionals(
  Iterable<ContractorListing> professionals,
  String city, {
  int limit = 8,
}) {
  final ranked =
      professionals.where((item) => item.serviceAreas.contains(city)).toList()
        ..sort((a, b) {
          if (a.verified != b.verified) return a.verified ? -1 : 1;
          if (a.hasReviews != b.hasReviews) return a.hasReviews ? -1 : 1;
          final byAverage = b.reviewAvg.compareTo(a.reviewAvg);
          if (byAverage != 0) return byAverage;
          final byProjects = b.projectsCompleted.compareTo(a.projectsCompleted);
          return byProjects != 0 ? byProjects : a.id.compareTo(b.id);
        });
  return ranked.take(limit).toList();
}

int _featuredScore(ContractorListing item) {
  return 2000 +
      (item.verified ? 500 : 0) +
      (item.hasReviews ? 350 : 0) +
      (item.reviewAvg * 40).round() +
      item.reviewCount.clamp(0, 50) * 4 +
      item.projectsCompleted.clamp(0, 50) * 2 +
      (item.logoUrl != null ? 25 : 0) +
      ((item.bio?.isNotEmpty ?? false) ? 25 : 0);
}
