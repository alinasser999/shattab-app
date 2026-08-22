import 'dart:io';

import 'package:batsh/core/theme/batsh_spacing.dart';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/presentation/widgets/professional_profile_sections.dart';
import 'package:batsh/features/portfolio/domain/portfolio_project.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the professional profile's own sections so the composition can be
/// looked at.
///
/// Narrower than the whole page on purpose: the cover, identity block and
/// contact buttons are private to `public_professional_profile.dart` and
/// reachable only by pumping the screen, which wants live portfolio, review,
/// saved and community providers. What is covered here is everything the
/// reference introduced — the trust tiles, the section navigator, the
/// collapsing about text, the services row, the filterable project grid and
/// the closing panel.
///
/// The pixel comparison runs only under `SHATTAB_GOLDEN`, for the same reason
/// as the home page's: font rasterisation differs between this dev box and a
/// Linux CI runner. The behavioural assertions run everywhere.
const _professional = ContractorListing(
  id: 'c1',
  fullName: 'أحمد المصري',
  businessName: 'البيت المصري للمقاولات',
  phone: '01001234567',
  specialties: ['full_reno', 'design', 'paint', 'electrical', 'plumbing'],
  serviceAreas: ['القاهرة', 'التجمع الخامس'],
  projectsCompleted: 200,
  yearsExperience: 8,
  reviewCount: 52,
  reviewAvg: 4.8,
  verified: true,
);

const _bio =
    'نحن فريق متخصص في تنفيذ التشطيبات والديكورات بجودة عالية واهتمام بأدق '
    'التفاصيل، نحرص على تحويل مساحتك إلى مكان يعكس ذوقك وراحتك. نعمل بخطة '
    'واضحة ومواعيد محددة من أول يوم وحتى التسليم.';

PortfolioProject _project(String id, String title, {String? type, int? year}) =>
    PortfolioProject(
      id: id,
      contractorId: 'c1',
      title: title,
      coverPhotoUrl: 'https://example.invalid/$id.jpg',
      photoUrls: const [],
      position: 0,
      apartmentType: type,
      location: 'القاهرة الجديدة',
      yearCompleted: year,
    );

final _projects = [
  _project('p1', 'شقة - مدينتي B7', type: 'شقق', year: 2025),
  _project('p2', 'فيلا - الرحاب فيلات', type: 'فلل', year: 2025),
  _project('p3', 'شقة - الرحاب 2', type: 'شقق', year: 2024),
  _project('p4', 'فيلا - التجمع الأول', type: 'فلل'),
];

Future<void> _loadFonts() async {
  final text = FontLoader('IBM Plex Sans Arabic');
  for (final weight in const ['400', '500', '600', '700']) {
    text.addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-$weight.ttf'));
  }
  await text.load();

  final icons = FontLoader('MaterialIcons');
  icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required double width,
  double height = 1500,
  double textScale = 1,
  List<PortfolioProject>? projects,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
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
          // Keyed: the section navigator owns a horizontal scroll view of its
          // own, so finding the page by type would match two.
          body: SingleChildScrollView(
            key: const ValueKey('profile-page'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: BatshSpacing.md),
                const ProfileStatTiles(listing: _professional),
                const SizedBox(height: BatshSpacing.lg),
                ProfileSectionTabs(
                  labels: const ['نبذة', 'أعمالنا', 'التقييمات (52)'],
                  currentIndex: 0,
                  onSelect: (_) {},
                ),
                const SizedBox(height: BatshSpacing.lg),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: profileGutter),
                  child: ProfileAboutCard(text: _bio),
                ),
                const SizedBox(height: BatshSpacing.lg),
                const ProfileServicesRow(
                  specialties: [
                    'full_reno',
                    'design',
                    'paint',
                    'electrical',
                    'plumbing',
                  ],
                ),
                const SizedBox(height: BatshSpacing.lg),
                ProfileProjectsGrid(
                  projects: projects ?? _projects,
                  onOpen: (_) {},
                ),
                const SizedBox(height: BatshSpacing.xl),
                ProfileClosingCta(onRequestQuote: () {}),
                const SizedBox(height: BatshSpacing.xl),
              ],
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

  testWidgets('profile sections at the reference 390dp width', (tester) async {
    await _pumpProfile(tester, width: 390);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('profile-page')),
      matchesGoldenFile('goldens/professional_profile_390.png'),
      skip: !compareGoldens,
    );
    // Surfaces after the frame is captured; see the home page golden for why.
    tester.takeException();
  });

  testWidgets('profile sections lay out at 320dp', (tester) async {
    await _pumpProfile(tester, width: 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile sections lay out at 430dp', (tester) async {
    await _pumpProfile(tester, width: 430);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile sections survive a large text scale at 320dp', (
    tester,
  ) async {
    await _pumpProfile(tester, width: 320, height: 2600, textScale: 1.6);
    expect(tester.takeException(), isNull);
  });

  // The filter row is meaningful only when the contractor has actually used
  // more than one property type; a single-type portfolio must not render a row
  // with one real chip and an "all" that filters nothing.
  testWidgets('project filters stay hidden for a single property type', (
    tester,
  ) async {
    await _pumpProfile(
      tester,
      width: 390,
      projects: [
        _project('p1', 'شقة أولى', type: 'شقق', year: 2025),
        _project('p2', 'شقة تانية', type: 'شقق', year: 2024),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('الكل'), findsNothing);
  });

  testWidgets('project filters appear once types differ', (tester) async {
    await _pumpProfile(tester, width: 390);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('شقق'), findsOneWidget);
    expect(find.text('فلل'), findsOneWidget);
  });

  // The completion badge is earned by a recorded year rather than painted on
  // every tile — three of the four fixtures carry one. Scoped to the grid:
  // the trust tiles use the same word for the project count.
  testWidgets('completion badge follows the recorded year', (tester) async {
    await _pumpProfile(tester, width: 390);
    expect(
      find.descendant(
        of: find.byType(ProfileProjectsGrid),
        matching: find.text('مشروع مكتمل'),
      ),
      findsNWidgets(3),
    );
  });
}
