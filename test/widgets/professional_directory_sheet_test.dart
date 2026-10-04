import 'dart:ui' as ui;

import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/discovery/data/discovery_repository.dart';
import 'package:batsh/features/discovery/domain/professional_reference_fixture.dart';
import 'package:batsh/features/discovery/presentation/discover_screen.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/saved/presentation/providers/saved_providers.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final family in const [
      (
        'IBM Plex Sans Arabic',
        'IBMPlexSansArabic',
        ['400', '500', '600', '700'],
      ),
      ('Tajawal', 'Tajawal', ['400', '500', '700', '800', '900']),
    ]) {
      final loader = FontLoader(family.$1);
      for (final weight in family.$3) {
        loader.addFont(
          rootBundle.load('assets/fonts/${family.$2}-$weight.ttf'),
        );
      }
      await loader.load();
    }

    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  group(
    'professional directory sheets',
    skip: !professionalReferenceEnabled,
    () {
      testWidgets('sort options select and commit the requested order', (
        tester,
      ) async {
        final semanticsHandle = tester.ensureSemantics();
        await _setViewport(tester);
        final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
        final container = _fixtureContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(_directoryApp(container));
        await tester.pumpAndSettle();
        expect(
          container.read(discoveryFiltersControllerProvider).sort,
          DiscoverySort.name,
        );

        await tester.tap(find.text(l10n.referenceCompatible));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        const ratingOptionLabel = 'الأعلى تقييماً';
        final ratingOption = find.bySemanticsLabel(ratingOptionLabel);
        expect(ratingOption, findsOneWidget);
        var semantics = tester.getSemantics(ratingOption).getSemanticsData();
        expect(semantics.label, ratingOptionLabel);
        expect(semantics.flagsCollection.isChecked, ui.CheckedState.isFalse);
        expect(semantics.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);

        await tester.tap(find.text(ratingOptionLabel));
        await tester.pumpAndSettle();
        semantics = tester.getSemantics(ratingOption).getSemanticsData();
        expect(semantics.flagsCollection.isChecked, ui.CheckedState.isTrue);
        expect(
          container.read(discoveryFiltersControllerProvider).sort,
          DiscoverySort.name,
          reason: 'the sheet choice is staged until confirmation',
        );

        await tester.tap(find.text('تأكيد'));
        await tester.pumpAndSettle();
        expect(
          container.read(discoveryFiltersControllerProvider).sort,
          DiscoverySort.rating,
        );
        expect(find.text(l10n.topRated), findsOneWidget);
        expect(tester.takeException(), isNull);
        semanticsHandle.dispose();
      });

      testWidgets('rating filter choices expose labels and selection state', (
        tester,
      ) async {
        final semanticsHandle = tester.ensureSemantics();
        await _setViewport(tester);
        final container = _fixtureContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(_directoryApp(container));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('الفلاتر'));
        await tester.pumpAndSettle();

        const ratingChoiceLabel = '4.5 نجمة فأعلى';
        final ratingChoice = find.bySemanticsLabel(ratingChoiceLabel);
        expect(ratingChoice, findsOneWidget);
        var semantics = tester.getSemantics(ratingChoice).getSemanticsData();
        expect(semantics.label, ratingChoiceLabel);
        expect(semantics.flagsCollection.isSelected, ui.Tristate.isFalse);
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);

        await tester.tap(find.text(ratingChoiceLabel));
        await tester.pumpAndSettle();
        semantics = tester.getSemantics(ratingChoice).getSemanticsData();
        expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
        expect(
          container.read(discoveryFiltersControllerProvider).minimumRating,
          isNull,
          reason: 'the filter sheet choice is staged until confirmation',
        );

        await tester.tap(find.text('عرض النتائج'));
        await tester.pumpAndSettle();
        expect(
          container.read(discoveryFiltersControllerProvider).minimumRating,
          4.5,
        );
        expect(tester.takeException(), isNull);
        semanticsHandle.dispose();
      });

      testWidgets('location ListTiles select and commit a city', (
        tester,
      ) async {
        await _setViewport(tester);
        final container = _fixtureContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(_directoryApp(container));
        await tester.pumpAndSettle();

        await tester.tap(find.text('القاهرة الجديدة').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('القاهرة'), findsOneWidget);

        await tester.tap(find.text('القاهرة'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تأكيد المنطقة'));
        await tester.pumpAndSettle();

        expect(
          container.read(discoveryFiltersControllerProvider).city,
          'القاهرة',
        );
        expect(tester.takeException(), isNull);
      });
    },
  );
}

Future<void> _setViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(426, 820);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

ProviderContainer _fixtureContainer() => ProviderContainer(
  overrides: [
    discoveryRepositoryProvider.overrideWithValue(
      ProfessionalReferenceDiscoveryRepository(
        SupabaseClient(
          'https://example.invalid',
          'local-test-placeholder',
          authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
        ),
      ),
    ),
    savedContractorIdsProvider.overrideWith((_) async => <String>{}),
  ],
);

Widget _directoryApp(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: BatshTheme.light(),
    home: const DiscoverScreen(),
  ),
);
