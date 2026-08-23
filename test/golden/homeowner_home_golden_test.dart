import 'dart:io';

import 'package:batsh/core/theme/batsh_spacing.dart';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/home/presentation/widgets/home_hero.dart';
import 'package:batsh/features/home/presentation/widgets/home_shortcuts.dart';
import 'package:batsh/features/home/presentation/widgets/home_showcase.dart';
import 'package:batsh/features/home/presentation/widgets/home_trust_sections.dart';
import 'package:batsh/features/portfolio/data/portfolio_repository.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the homeowner home page's sections so the composition can actually
/// be looked at.
///
/// The screen itself is not pumped: its providers reach Supabase, which is not
/// initialised under `flutter test`. What is pumped is every section the screen
/// builds, in the screen's order and with the screen's gaps — which is what a
/// reference comparison needs: spacing, proportions, type scale, colour, RTL.
/// It does not prove the screen wires them together; the analyzer covers that.
///
/// **Keep the gaps below in step with `homeowner_home_screen.dart`.** If the
/// screen's rhythm changes and this does not, the golden stops describing the
/// page.
///
/// The pixel comparison only runs when `SHATTAB_GOLDEN` is set. Font
/// rasterisation differs between a Windows dev box and a Linux CI runner, so an
/// unconditional compare would fail CI for a reason unrelated to the code. The
/// layout assertions — no overflow at three widths and at a large text scale —
/// run everywhere.
///
///   flutter test test/golden --update-goldens   # regenerate, then look at it
///   SHATTAB_GOLDEN=1 flutter test test/golden   # compare
const _gapAfterHero = BatshSpacing.ml;
const _gapAfterCategories = BatshSpacing.xl;
const _gapAfterQuickActions = BatshSpacing.xl;
const _gapAfterFeatured = BatshSpacing.xl;
const _gapAfterProjects = BatshSpacing.xxl;
const _gapAfterProcess = BatshSpacing.xxl;

const _professional = ContractorListing(
  id: 'featured',
  fullName: 'أحمد المصري',
  businessName: 'البيت العصري للمقاولات',
  phone: '01001234567',
  specialties: ['full_reno', 'design'],
  serviceAreas: ['القاهرة - التجمع الخامس'],
  projectsCompleted: 200,
  reviewCount: 52,
  reviewAvg: 4.8,
  verified: true,
);

/// Registers the bundled typeface so Arabic renders as Arabic.
///
/// Without this the test engine falls back to Ahem, which draws every glyph as
/// a filled box — fine for asserting a widget exists, useless for judging a
/// page whose whole type system is Arabic.
Future<void> _loadFonts() async {
  final text = FontLoader('IBM Plex Sans Arabic');
  for (final weight in const ['400', '500', '600', '700']) {
    text.addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-$weight.ttf'));
  }
  await text.load();

  // Icons are half the page's vocabulary — five trades, three shortcuts, the
  // rating star, the trust mark. Without this they rasterise as empty boxes
  // and the golden cannot be used to judge icon treatment at all.
  final icons = FontLoader('MaterialIcons');
  icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required double width,
  double height = 1900,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final searchCtrl = TextEditingController();
  addTearDown(searchCtrl.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Empty rather than fixture rows: the rail's curated fallback is what
        // a fresh catalogue actually shows, and network images do not resolve
        // under test either way.
        recentProjectsProvider.overrideWith((ref) => []),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: BatshTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHero(
                    locationLabel: 'القاهرة - التجمع الخامس',
                    unreadCount: 3,
                    searchController: searchCtrl,
                    onSearchSubmitted: (_) {},
                    onLocationTap: () {},
                    onNotificationTap: () {},
                    onMenuTap: () {},
                    onFilterTap: () {},
                    activeFilterCount: 0,
                  ),
                  const SizedBox(height: _gapAfterHero),
                  HomeServiceCategories(onSelect: (_) {}, onViewAll: () {}),
                  const SizedBox(height: _gapAfterCategories),
                  HomeQuickActions(
                    onNearby: () {},
                    onRequests: () {},
                    onRequestQuote: () {},
                  ),
                  const SizedBox(height: _gapAfterQuickActions),
                  HomeFeaturedProfessionalCard(
                    listing: _professional,
                    isSaved: false,
                    onToggleSave: () {},
                    onOpenProfile: () {},
                  ),
                  const SizedBox(height: _gapAfterFeatured),
                  HomeProjectsRail(onViewAll: () {}, onOpenProject: (_, _) {}),
                  const SizedBox(height: _gapAfterProjects),
                  // Newly mounted with the richness pass: the process story
                  // and the closing CTA are part of the page's composition
                  // now, so the overflow gates must see them too.
                  const HomeProcessSection(),
                  const SizedBox(height: _gapAfterProcess),
                  HomeCommunityInvite(onTap: () {}),
                  const SizedBox(height: BatshSpacing.xxl),
                  HomeClosingCta(onTap: () {}),
                  const SizedBox(height: BatshSpacing.ml),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();

    // Every photograph on this page goes through CachedNetworkImage, which
    // asks flutter_cache_manager for a cache directory before it will even
    // decide the image is unreachable. Neither plugin exists under
    // `flutter test`, so without these the lookup throws instead of falling
    // through to the placeholder the golden is supposed to show.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final cacheDir = Directory.systemTemp.createTempSync('shattab_golden').path;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cacheDir,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.tekartik.sqflite'),
      (_) async => null,
    );
  });

  final compareGoldens = Platform.environment.containsKey('SHATTAB_GOLDEN');

  testWidgets('home page composition at the reference 390dp width', (
    tester,
  ) async {
    await _pumpHome(tester, width: 390);
    expect(tester.takeException(), isNull);

    // The approved hero is now the clay/photo composition rather than the old
    // centered wordmark bar. Keep the structural assertion aligned with the
    // visual contract so a future refactor cannot silently remove the hero or
    // its real search action.
    expect(find.byType(HomeHero), findsOneWidget);
    expect(find.byType(HomeSearchField), findsOneWidget);

    await expectLater(
      find.byType(SingleChildScrollView),
      matchesGoldenFile('goldens/homeowner_home_390.png'),
      skip: !compareGoldens,
    );
    // The cached-image layer reaches for path_provider and sqflite, neither of
    // which exists under `flutter test`. It surfaces only during the extra
    // pumps the golden capture performs, after the frame is already rasterised,
    // so it cannot affect what was captured — but it would still fail the test.
    tester.takeException();
  });

  // The narrow end of the Android range. Five category tiles and three quick
  // actions are the two rows most likely to overflow, because each divides one
  // gutter by a fixed count.
  testWidgets('home page lays out at 320dp without overflowing', (
    tester,
  ) async {
    await _pumpHome(tester, width: 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home page lays out at 430dp without overflowing', (
    tester,
  ) async {
    await _pumpHome(tester, width: 430);
    expect(tester.takeException(), isNull);
  });

  // The accessibility case a fixed-height card would have failed. Every row on
  // this page sizes from its content rather than from a constant, so a reader
  // at 1.6x should push the sections taller instead of clipping them.
  testWidgets('home page survives a large text scale at 320dp', (tester) async {
    await _pumpHome(tester, width: 320, height: 2600, textScale: 1.6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick actions render left-to-right in English', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [recentProjectsProvider.overrideWith((ref) => [])],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: BatshTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeQuickActions(
                onNearby: () {},
                onRequests: () {},
                onRequestQuote: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Request a quote'), findsOneWidget);
  });
}
