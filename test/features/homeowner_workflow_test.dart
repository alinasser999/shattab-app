import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/briefs/presentation/providers/briefs_providers.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/home/presentation/homeowner_home_screen.dart';
import 'package:batsh/features/home/presentation/widgets/home_live_states.dart';
import 'package:batsh/features/home/presentation/widgets/home_reference_sections.dart';
import 'package:batsh/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:batsh/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:batsh/features/saved/presentation/providers/saved_providers.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mounted homeowner home stays honest at narrow large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeownerProfileProvider.overrideWith(
            (ref) async =>
                const HomeownerProfile(profileId: 'homeowner-1', city: 'Cairo'),
          ),
          myBriefsProvider.overrideWith((ref) async => []),
          notificationsProvider.overrideWith((ref) => Stream.value([])),
          nearbyProfessionalsProvider(
            'Cairo',
          ).overrideWith(_EmptyNearbyProfessionals.new),
          savedContractorIdsProvider.overrideWith((ref) async => <String>{}),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: BatshTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(1.6),
            ),
            child: const HomeownerHomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeownerHomeScreen), findsOneWidget);
    expect(find.byType(ReferenceHomeHero), findsOneWidget);
    expect(find.byType(HomeLiveStateSection), findsOneWidget);
    expect(find.text('Need a full apartment paint'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _EmptyNearbyProfessionals extends NearbyProfessionals {
  @override
  Future<List<ContractorListing>> build(String city) async => const [];
}
