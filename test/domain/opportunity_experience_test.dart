import 'package:batsh/features/briefs/domain/brief.dart';
import 'package:batsh/features/briefs/domain/opportunity_experience.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:batsh/features/portfolio/domain/portfolio_project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 1, 8);

  Brief brief({
    String id = 'brief-1',
    String city = 'القاهرة',
    List<String> specialties = const ['full_reno'],
    List<String>? photoUrls,
    DateTime? createdAt,
  }) => Brief(
    id: id,
    homeownerId: 'owner-1',
    apartmentType: ApartmentType.studio,
    city: city,
    workDescription: 'تشطيب عيادة أسنان كاملة في المعادي.',
    photoUrls: photoUrls ?? const ['https://example.com/project.jpg'],
    targetSpecialties: specialties,
    status: BriefStatus.open,
    createdAt: createdAt ?? now.subtract(const Duration(hours: 2)),
  );

  const contractor = ContractorProfile(
    profileId: 'contractor-1',
    specialties: ['full_reno', 'paint'],
    serviceAreas: ['القاهرة', 'الجيزة'],
  );

  test('preference completion reflects real profile fields', () {
    expect(opportunityPreferenceCompletion(null), 0);
    expect(
      opportunityPreferenceCompletion(
        const ContractorProfile(
          profileId: 'contractor-1',
          specialties: ['paint'],
        ),
      ),
      50,
    );
    expect(opportunityPreferenceCompletion(contractor), 100);
  });

  test('match rank and reasons are deterministic', () {
    final match = calculateOpportunityMatch(
      brief: brief(),
      contractor: contractor,
      portfolio: const [
        PortfolioProject(
          id: 'project-1',
          contractorId: 'contractor-1',
          title: 'عيادة المعادي',
          coverPhotoUrl: 'https://example.com/cover.jpg',
          photoUrls: [],
          position: 0,
          category: 'full_reno',
        ),
      ],
      now: now,
    );

    expect(match.rank, 100);
    expect(
      match.reasons,
      containsAll([
        OpportunityRecommendationReason.specialtyMatch,
        OpportunityRecommendationReason.serviceAreaMatch,
        OpportunityRecommendationReason.similarPortfolio,
        OpportunityRecommendationReason.fresh,
        OpportunityRecommendationReason.projectPhotos,
      ]),
    );
  });

  test(
    'filters combine focus, specialty, city, recency, and applied state',
    () {
      final item = brief();
      const filters = OpportunityFilters(
        focus: OpportunityFocus.nearby,
        specialties: {'full_reno'},
        city: 'القاهرة',
        recency: OpportunityRecency.today,
        hideApplied: true,
      );

      expect(
        opportunityMatchesFilters(
          brief: item,
          filters: filters,
          contractor: contractor,
          now: now,
        ),
        isTrue,
      );
      expect(
        opportunityMatchesFilters(
          brief: item,
          filters: filters,
          contractor: contractor,
          appliedBriefIds: {item.id},
          now: now,
        ),
        isFalse,
      );
    },
  );

  test('competition remains unknown without real offer counts', () {
    expect(classifyCompetitionLevel(null), CompetitionLevel.unknown);
    expect(classifyCompetitionLevel(4), CompetitionLevel.low);
    expect(classifyCompetitionLevel(9), CompetitionLevel.medium);
    expect(classifyCompetitionLevel(10), CompetitionLevel.high);
  });

  test('recommended sorting ranks stronger matches before weaker matches', () {
    final items = [
      brief(
        id: 'weak',
        city: 'الإسكندرية',
        specialties: const ['carpentry'],
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      brief(id: 'strong', createdAt: now.subtract(const Duration(hours: 3))),
    ];

    final sorted = sortOpportunities(
      opportunities: items,
      sort: OpportunitySort.recommended,
      contractor: contractor,
      now: now,
    );

    expect(sorted.map((item) => item.id), ['strong', 'weak']);
  });

  test('newest sorting uses created date and stable id tie-breaking', () {
    final items = [
      brief(id: 'older', createdAt: now.subtract(const Duration(days: 2))),
      brief(id: 'same-a', createdAt: now.subtract(const Duration(hours: 4))),
      brief(id: 'same-b', createdAt: now.subtract(const Duration(hours: 4))),
      brief(id: 'newest', createdAt: now.subtract(const Duration(hours: 1))),
    ];

    final sorted = sortOpportunities(
      opportunities: items,
      sort: OpportunitySort.newest,
      contractor: contractor,
      now: now,
    );

    expect(sorted.map((item) => item.id), [
      'newest',
      'same-b',
      'same-a',
      'older',
    ]);
  });

  test('feed metrics describe the currently visible result set', () {
    final visible = [
      brief(id: 'fresh-area'),
      brief(id: 'old-area', createdAt: now.subtract(const Duration(days: 3))),
      brief(
        id: 'fresh-other-area',
        city: 'الإسكندرية',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];

    final metrics = calculateOpportunityFeedMetrics(
      opportunities: visible,
      contractor: contractor,
      now: now,
    );

    expect(metrics.matchingCount, 3);
    expect(metrics.freshCount, 2);
    expect(metrics.areaCount, 2);
  });

  test('radar metrics stay grounded in the visible opportunities', () {
    final visible = [
      brief(id: 'fresh-area'),
      brief(
        id: 'week-other-area',
        city: 'ط§ظ„ط¥ط³ظƒظ†ط¯ط±ظٹط©',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      brief(
        id: 'old-area-no-photo',
        photoUrls: const [],
        createdAt: now.subtract(const Duration(days: 14)),
      ),
    ];

    final metrics = calculateOpportunityRadarMetrics(
      opportunities: visible,
      contractor: contractor,
      now: now,
    );

    expect(metrics.matchingCount, 3);
    expect(metrics.freshCount, 1);
    expect(metrics.weekCount, 2);
    expect(metrics.areaCount, 2);
    expect(metrics.photoCount, 2);
    expect(metrics.areaRatio, closeTo(2 / 3, 0.001));
  });

  test('pagination merge removes duplicate opportunity ids', () {
    final current = [brief(id: 'one'), brief(id: 'two')];
    final next = [brief(id: 'two'), brief(id: 'three'), brief(id: 'three')];

    final merged = mergeUniqueOpportunityPages(current, next);

    expect(merged.map((item) => item.id), ['one', 'two', 'three']);
  });

  test('headline uses the first meaningful sentence', () {
    expect(
      opportunityHeadline('تشطيب عيادة أسنان. تفاصيل إضافية للمشروع.'),
      'تشطيب عيادة أسنان',
    );
  });
}
