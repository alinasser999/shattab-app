import 'dart:async';

import 'package:batsh/features/discovery/data/discovery_repository.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/discovery/presentation/widgets/public_professional_profile.dart';
import 'package:batsh/features/explore/presentation/providers/explore_providers.dart';
import 'package:batsh/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:batsh/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:batsh/features/saved/presentation/providers/saved_providers.dart';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/widgets/contact_buttons.dart';
import 'package:batsh/core/widgets/batsh_button.dart';
import 'package:batsh/core/widgets/tier_badge.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'old discovery pages cannot append after a filter generation changes',
    () async {
      final repository = _ControlledDiscoveryRepository();
      final container = ProviderContainer(
        overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        discoverContractorsProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      final initialBuild = repository.requests.single;
      initialBuild.complete(_page('initial'));
      await container.read(discoverContractorsProvider.future);

      final loadMore = container
          .read(discoverContractorsProvider.notifier)
          .loadMore();
      final oldPage = repository.requests[1];

      container
          .read(discoveryFiltersControllerProvider.notifier)
          .setCity('Cairo');
      await Future<void>.delayed(Duration.zero);
      final newBuild = repository.requests[2];
      newBuild.complete(_page('cairo'));
      await container.read(discoverContractorsProvider.future);

      oldPage.complete(_page('old-page'));
      await loadMore;

      expect(
        container
            .read(discoverContractorsProvider)
            .value!
            .map((item) => item.id),
        ['cairo-1', 'cairo-2'],
      );
    },
  );

  testWidgets(
    'mounted profile shows kind and one public tier without contact',
    (tester) async {
      const listing = ContractorListing(
        id: 'professional-1',
        fullName: 'A professional',
        businessName: 'A professional studio',
        specialties: ['design'],
        serviceAreas: ['Cairo'],
        projectsCompleted: 3,
        reviewCount: 2,
        reviewAvg: 4.5,
        providerKind: ProviderKind.engineer,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            portfolioForContractorProvider(
              listing.id,
            ).overrideWith((ref) async => []),
            reviewsForContractorProvider(
              listing.id,
            ).overrideWith((ref) async => []),
            savedContractorIdsProvider.overrideWith((ref) async => <String>{}),
            contractorCommunityPostsProvider(
              listing.id,
            ).overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: BatshTheme.light(),
            home: const Scaffold(
              body: PublicProfessionalProfile(listing: listing),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Engineer'), findsOneWidget);
      expect(find.byType(TierBadge), findsOneWidget);
      expect(find.byType(WhatsAppButton), findsNothing);
      expect(find.byType(CallButton), findsNothing);

      await tester.scrollUntilVisible(
        find.byType(BatshButton),
        500,
        scrollable: find.byType(Scrollable).at(0),
      );

      expect(find.byType(BatshButton), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}

class _PendingRequest {
  _PendingRequest(this.filters, this.after);

  final DiscoveryFilters filters;
  final DiscoveryCursor? after;
  final _completer = Completer<DiscoveryPage>();

  Future<DiscoveryPage> get future => _completer.future;

  void complete(DiscoveryPage page) => _completer.complete(page);
}

class _ControlledDiscoveryRepository extends DiscoveryRepository {
  _ControlledDiscoveryRepository()
    : super(SupabaseClient('https://example.supabase.co', 'anon-key'));

  final requests = <_PendingRequest>[];

  @override
  Future<DiscoveryPage> fetchContractorsPage(
    DiscoveryFilters filters, {
    int limit = DiscoveryRepository.pageSize,
    DiscoveryCursor? after,
  }) {
    final request = _PendingRequest(filters, after);
    requests.add(request);
    return request.future;
  }
}

DiscoveryPage _page(String id) => DiscoveryPage(
  items: [
    for (var index = 1; index <= 2; index++)
      ContractorListing(
        id: '$id-$index',
        fullName: '$id-$index',
        businessName: id,
        specialties: const [],
        serviceAreas: const [],
        projectsCompleted: 1,
      ),
  ],
  cursor: DiscoveryCursor(id: '$id-2', fullName: '$id-2'),
  requestedLimit: 2,
);
