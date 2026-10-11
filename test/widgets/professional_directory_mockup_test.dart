import 'dart:io';
import 'dart:ui' as ui;

import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/discovery/data/discovery_repository.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/domain/professional_reference_fixture.dart';
import 'package:batsh/features/discovery/presentation/professional_directory_screen.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/discovery/presentation/widgets/professional_reference_components.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:batsh/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/homeowner_reference_harness.dart';

const _folder = 'artifacts/agent-team/directory-mockup-20261006/screenshots';

ContractorListing _listing({
  bool long = false,
  bool rated = false,
  bool trusted = false,
  bool unknown = false,
  bool english = false,
}) => ContractorListing(
  id: 'qa-directory-local',
  fullName: long
      ? (english
            ? 'A very long professional identity for accessibility testing'
            : 'محترف باسم طويل للغاية لاختبار الوصول إلى البيانات بالكامل')
      : 'أحمد حسن',
  businessName: '',
  specialties: const ['paint', 'carpentry', 'design'],
  serviceAreas: [
    long
        ? (english
              ? 'New Cairo and the extended urban development region'
              : 'مدينة القاهرة الجديدة والمنطقة العمرانية الممتدة')
        : 'القاهرة الجديدة',
  ],
  projectsCompleted: rated ? 1234 : 0,
  yearsExperience: unknown ? null : 25,
  reviewCount: rated ? 123 : 0,
  reviewAvg: rated ? 4.8 : 0,
  verified: trusted,
  isSponsored: trusted,
  logoUrl: ProfessionalReferenceFixture.avatarImage,
  coverPhotoUrl: ProfessionalReferenceFixture.livingRoomImage,
);

Future<void> _capture(WidgetTester tester, String name, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(_folder).create(recursive: true);
    await File('$_folder/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<ProviderContainer> _directory(
  WidgetTester tester,
  double width,
  double scale,
) async {
  final container = await pumpHomeownerReference(
    tester,
    size: Size(width, 844),
    query: 'scenario=noactive&textScale=$scale',
    nativeSafeAreas: true,
    capture: true,
    extraOverrides: [
      discoveryRepositoryProvider.overrideWithValue(_LocalDirectory()),
      portfolioForContractorProvider(
        'qa-directory-local',
      ).overrideWith((_) async => []),
      portfolioForContractorProvider(
        'qa-directory-second',
      ).overrideWith((_) async => []),
    ],
  );
  await tester.tap(find.bySemanticsLabel('المحترفين').last);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(ProfessionalDirectoryScreen));
    for (final path in [
      ProfessionalReferenceFixture.livingRoomImage,
      ProfessionalReferenceFixture.bedroomImage,
      ProfessionalReferenceFixture.avatarImage,
    ]) {
      await precacheImage(AssetImage(path), context);
    }
  });
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(initializeHomeownerTestClient);

  testWidgets('390 native directory reference geometry and interactive filters', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final container = await _directory(tester, 390, 1);
    await _capture(
      tester,
      'directory-390',
      const ValueKey('homeowner-qa-capture'),
    );
    expect(tester.takeException(), isNull);
    final directoryL10n = AppLocalizations.of(
      tester.element(find.byType(ProfessionalDirectoryScreen)),
    )!;
    final hasMore = container
        .read(discoverContractorsProvider.notifier)
        .hasMore;
    final count = professionalReferenceEnabled ? 124 : 2;
    final countLabel = !professionalReferenceEnabled && hasMore
        ? directoryL10n.referenceDisplayedProfessionalsCount(count)
        : directoryL10n.referenceProfessionalsCount(count);
    final countRect = tester.getRect(find.text(countLabel));
    final sort = tester.getRect(find.text('الأكثر توافقاً'));
    final gallery = find.byType(ReferenceGallery).first;
    final rect = tester.getRect(gallery);
    expect(countRect.width, greaterThan(0));
    expect(rect.left, 16);
    expect(rect.width, 358);
    expect(rect.height, closeTo(358 / 1.86, .1));
    expect(tester.getRect(find.text('عرض الملف').first).bottom, lessThan(736));
    expect(find.text('بدون تقييم'), findsWidgets);
    final star = find.byIcon(Icons.star_border_rounded).first;
    expect(
      tester.getRect(star).left,
      lessThan(tester.getRect(find.text('بدون تقييم').first).left),
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('الكل'))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
    await tester.enterText(find.byType(TextField).first, 'حسن');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      container.read(discoveryFiltersControllerProvider).searchQuery,
      'حسن',
    );
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(
      container.read(discoveryFiltersControllerProvider).searchQuery,
      isNull,
    );
    await tester.tap(find.bySemanticsLabel('تصميم داخلي').first);
    await tester.pumpAndSettle();
    expect(
      container.read(discoveryFiltersControllerProvider).specialty,
      'design',
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('تصميم داخلي').first)
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
    expect(
      countRect.center.dy,
      closeTo(sort.center.dy, 2),
      reason:
          'Approved reference shows count and sort on one row at390 normal scale',
    );
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('directory width $width scale2 scroll has no overflow', (
      tester,
    ) async {
      await _directory(tester, width, 2);
      expect(tester.takeException(), isNull);
      await _capture(
        tester,
        'directory-${width.toInt()}-scale2',
        const ValueKey('homeowner-qa-capture'),
      );
      for (var i = 0; i < 3; i++) {
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
    for (final language in ['ar', 'en']) {
      for (final scale in [1.0, 2.0]) {
        for (final rated in [false, true]) {
          testWidgets(
            'card $width $language scale$scale rated$rated truthful and accessible',
            (tester) async {
              tester.view.physicalSize = Size(width, 844);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              final l10n = await AppLocalizations.delegate.load(
                Locale(language),
              );
              final listing = _listing(
                long: true,
                rated: rated,
                trusted: rated,
                unknown: !rated,
                english: language == 'en',
              );
              var opens = 0;
              var saves = 0;
              final semantics = tester.ensureSemantics();

              await tester.pumpWidget(
                MaterialApp(
                  locale: Locale(language),
                  theme: BatshTheme.light(),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 844),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Scaffold(
                      body: SingleChildScrollView(
                        child: ReferenceProfessionalCard(
                          listing: listing,
                          saved: rated,
                          photos: const [],
                          onOpen: () => opens++,
                          onSave: () => saves++,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(
                find.text(rated ? '4.8 (123)' : l10n.referenceUnratedLabel),
                findsOneWidget,
              );
              expect(
                find.text(
                  l10n.referenceDirectoryYearsExperienceCount(
                    rated ? '25' : '—',
                  ),
                  findRichText: true,
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  l10n.referenceCompletedProjectsCount(rated ? 1234 : 0),
                  findRichText: true,
                ),
                findsOneWidget,
              );
              expect(
                find.text(l10n.referenceVerified),
                rated ? findsOneWidget : findsNothing,
              );
              expect(
                find.text(l10n.referenceAdDisclosure),
                rated ? findsOneWidget : findsNothing,
              );
              final save = find.bySemanticsLabel(
                rated
                    ? l10n.referenceUnsaveProfessional
                    : l10n.referenceSaveProfessional,
              );
              expect(
                tester.getSize(save).shortestSide,
                greaterThanOrEqualTo(44),
              );
              await tester.tap(save);
              await tester.pump();
              expect(saves, 1);
              expect(opens, 0);
              final profile = find.text(l10n.referenceViewProfile);
              await tester.ensureVisible(profile);
              await tester.pumpAndSettle();
              await tester.tap(profile);
              await tester.pump();
              expect(opens, 1);
              expect(tester.takeException(), isNull);
              semantics.dispose();
            },
          );
        }
      }
    }
  }
}

class _LocalDirectory extends ProfessionalReferenceDiscoveryRepository {
  _LocalDirectory() : super(Supabase.instance.client);
  @override
  Future<DiscoveryPage> fetchContractorsPage(
    DiscoveryFilters filters, {
    int limit = DiscoveryRepository.pageSize,
    DiscoveryCursor? after,
  }) async => DiscoveryPage(
    items: [
      _listing(),
      const ContractorListing(
        id: 'qa-directory-second',
        fullName: 'محترف تجريبي',
        businessName: '',
        specialties: ['paint'],
        serviceAreas: ['القاهرة'],
        projectsCompleted: 0,
        coverPhotoUrl: ProfessionalReferenceFixture.bedroomImage,
      ),
    ],
    cursor: null,
    requestedLimit: limit,
  );
  @override
  Future<List<ContractorListing>> fetchSponsoredProfessionals({
    String? specialty,
    String? city,
  }) async => [];
}
