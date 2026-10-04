import 'package:batsh/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'dart:async';
import 'package:batsh/features/briefs/domain/brief.dart';
import 'package:batsh/features/briefs/presentation/providers/briefs_providers.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/home/presentation/widgets/reference_home_experience.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:batsh/features/quotes/domain/quote.dart';
import 'package:batsh/features/quotes/presentation/providers/quotes_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/homeowner_reference_harness.dart';

void main() {
  setUpAll(initializeHomeownerTestClient);
  for (final entry in <String, List<Brief>>{
    'empty': [],
    'completed only': [_brief('completed', completed: true)],
    'open': [_brief('open')],
    'hired open': [_brief('hired', hired: true)],
    'awaiting confirmation': [_brief('awaiting', hired: true, requested: true)],
    'source ordering': [
      _brief('completed', completed: true),
      _brief('awaiting', hired: true, requested: true),
      _brief('open'),
    ],
  }.entries) {
    testWidgets('source-backed current project: ${entry.key}', (tester) async {
      await pumpHomeownerReference(
        tester,
        extraOverrides: [
          for (final id in ['featured', 'a', 'b', 'c', 'd', 'e', 'no-cover'])
            portfolioForContractorProvider(id).overrideWith((_) async => []),
          myBriefsProvider.overrideWith((_) async => entry.value),
          for (final brief in entry.value)
            quotesForBriefProvider(brief.id).overrideWith((_) async => []),
        ],
      );
      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      expect(
        experience.project?.id,
        entry.value.where((b) => !b.isCompleted).firstOrNull?.id,
      );
      expect(experience.staticPreview, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
  for (final state in ['success', 'loading', 'error']) {
    testWidgets('quote count guard and withdrawals: $state', (tester) async {
      final brief = _brief('quotes');
      await pumpHomeownerReference(
        tester,
        settle: state != 'loading',
        extraOverrides: [
          for (final id in ['featured', 'a', 'b', 'c', 'd', 'e', 'no-cover'])
            portfolioForContractorProvider(id).overrideWith((_) async => []),
          myBriefsProvider.overrideWith((_) async => [brief]),
          quotesForBriefProvider(brief.id).overrideWith((_) {
            if (state == 'loading') return Completer<List<Quote>>().future;
            if (state == 'error') {
              return Future<List<Quote>>.error(StateError('local quote error'));
            }
            return Future.value([
              for (final status in QuoteStatus.values) _quote(status),
            ]);
          }),
        ],
      );
      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      expect(experience.showOfferCount, state == 'success');
      if (state == 'success') expect(experience.project!.offerCount, 3);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('top rated excludes featured and deduplicates before take five', (
    tester,
  ) async {
    await pumpHomeownerReference(
      tester,
      extraOverrides: [
        for (final id in ['featured', 'a', 'b', 'c', 'd', 'e', 'no-cover'])
          portfolioForContractorProvider(id).overrideWith((_) async => []),
        discoverContractorsProvider.overrideWith(
          () => _Listings([_listing('featured')]),
        ),
        topRatedProfessionalsProvider.overrideWith(
          () => _TopListings([
            _listing('featured'),
            _listing('a'),
            _listing('a'),
            _listing('b'),
            _listing('c'),
            _listing('d'),
            _listing('e'),
            _listing('f'),
          ]),
        ),
      ],
    );
    final experience = tester.widget<ReferenceHomeExperience>(
      find.byType(ReferenceHomeExperience),
    );
    expect(experience.topRatedProfessionals.map((p) => p.id), [
      'a',
      'b',
      'c',
      'd',
      'e',
    ]);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing covers remain empty; exhausted top-rated rail omitted', (
    tester,
  ) async {
    await pumpHomeownerReference(
      tester,
      extraOverrides: [
        for (final id in ['featured', 'a', 'b', 'c', 'd', 'e', 'no-cover'])
          portfolioForContractorProvider(id).overrideWith((_) async => []),
        discoverContractorsProvider.overrideWith(
          () => _Listings([_listing('no-cover')]),
        ),
        topRatedProfessionalsProvider.overrideWith(() => _TopListings([])),
      ],
    );
    final experience = tester.widget<ReferenceHomeExperience>(
      find.byType(ReferenceHomeExperience),
    );
    expect(experience.featuredProfessionals.single.coverPhotoUrl, isNull);
    expect(experience.topRatedProfessionals, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Brief _brief(
  String id, {
  bool hired = false,
  bool requested = false,
  bool completed = false,
}) => Brief(
  id: id,
  homeownerId: 'local',
  apartmentType: ApartmentType.oneBedroom,
  city: 'القاهرة',
  projectTitle: id,
  workDescription: 'عمل محلي',
  photoUrls: [],
  targetSpecialties: [],
  status: BriefStatus.open,
  createdAt: DateTime.utc(2026),
  hiredAt: hired ? DateTime.utc(2026) : null,
  completionRequestedAt: requested ? DateTime.utc(2026) : null,
  completedAt: completed ? DateTime.utc(2026) : null,
);
Quote _quote(QuoteStatus status) => Quote(
  id: status.name,
  briefId: 'quotes',
  contractorId: status.name,
  note: '',
  status: status,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
ContractorListing _listing(String id) => ContractorListing(
  id: id,
  fullName: id,
  businessName: id,
  specialties: ['design'],
  serviceAreas: [],
  projectsCompleted: 0,
  reviewCount: 1,
  reviewAvg: 4.9,
);

class _Listings extends DiscoverContractors {
  _Listings(this.items);
  final List<ContractorListing> items;
  @override
  Future<List<ContractorListing>> build() async => items;
}

class _TopListings extends TopRatedProfessionals {
  _TopListings(this.items);
  final List<ContractorListing> items;
  @override
  Future<List<ContractorListing>> build() async => items;
}
