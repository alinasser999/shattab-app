import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/domain/professional_reference_fixture.dart';
import 'package:batsh/features/discovery/presentation/widgets/professional_reference_components.dart';
import 'package:batsh/features/discovery/presentation/widgets/reference_professional_profile.dart';
import 'package:batsh/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:batsh/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:batsh/features/saved/presentation/providers/saved_providers.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final text = FontLoader('Tajawal');
    for (final weight in const ['400', '500', '700', '800', '900']) {
      text.addFont(rootBundle.load('assets/fonts/Tajawal-$weight.ttf'));
    }
    await text.load();

    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  group(
    'reference professional profile',
    skip: !professionalReferenceEnabled,
    () {
      testWidgets(
        'mounts every section, keeps actions fixed, and fits at 426px',
        (tester) async {
          await _setViewport(tester, const Size(426, 820));
          final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

          await tester.pumpWidget(_profileApp());
          await tester.pumpAndSettle();

          _expectAllSections(tester, l10n);
          expect(find.text('32'), findsOneWidget);
          expect(find.text('8'), findsOneWidget);
          expect(tester.takeException(), isNull);

          final quoteButton = _actionButton(tester, l10n.referenceRequestQuote);
          final fixedTop = tester.getTopLeft(quoteButton).dy;
          expect(tester.getSize(quoteButton).height, greaterThanOrEqualTo(44));

          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -4000),
          );
          await tester.pumpAndSettle();

          expect(tester.getTopLeft(quoteButton).dy, closeTo(fixedTop, 0.5));
          final finalReview = find.text('متابعة ممتازة واهتمام بكل التفاصيل.');
          expect(finalReview, findsOneWidget);
          expect(
            tester.getRect(finalReview).bottom,
            lessThan(tester.getTopLeft(quoteButton).dy),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('supports 320px at 1.3 text scale without overflow', (
        tester,
      ) async {
        await _setViewport(tester, const Size(320, 820));
        final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

        await tester.pumpWidget(_profileApp(textScale: 1.3));
        await tester.pumpAndSettle();

        _expectAllSections(tester, l10n);
        expect(find.text(l10n.referenceRequestQuote), findsOneWidget);
        expect(find.text(l10n.referenceMessageProfessional), findsOneWidget);
        expect(tester.takeException(), isNull);

        final saveButton = find.byType(ReferenceIconButton).last;
        expect(tester.getSize(saveButton).width, greaterThanOrEqualTo(44));
        expect(tester.getSize(saveButton).height, greaterThanOrEqualTo(44));
        final servicesAnchor = find.text(l10n.referenceServices).first;
        final anchorButton = find
            .ancestor(of: servicesAnchor, matching: find.byType(InkWell))
            .first;
        expect(tester.getSize(anchorButton).height, greaterThanOrEqualTo(44));
      });

      testWidgets('each section anchor scrolls within the continuous page', (
        tester,
      ) async {
        await _setViewport(tester, const Size(426, 820));
        final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
        final anchors = [
          l10n.referenceAbout,
          l10n.referenceWorks,
          l10n.referenceServices,
          l10n.reviewsSheetTitle,
        ];

        for (final label in anchors) {
          await tester.pumpWidget(_profileApp(key: ValueKey(label)));
          await tester.pumpAndSettle();
          final outerScrollable = find
              .descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(Scrollable),
              )
              .first;
          final before = tester
              .state<ScrollableState>(outerScrollable)
              .position
              .pixels;
          await tester.tap(find.text(label).first);
          await tester.pumpAndSettle();
          final after = tester
              .state<ScrollableState>(outerScrollable)
              .position
              .pixels;

          expect(after, greaterThan(before), reason: '$label should scroll');
          _expectAllSections(tester, l10n);
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('the photo gallery swipes and updates its active dot', (
        tester,
      ) async {
        await _setViewport(tester, const Size(426, 820));
        await tester.pumpWidget(_profileApp());
        await tester.pumpAndSettle();

        final gallery = find.byType(ReferenceGallery).first;
        final pageView = find
            .descendant(of: gallery, matching: find.byType(PageView))
            .first;
        final galleryScrollable = find
            .descendant(of: pageView, matching: find.byType(Scrollable))
            .first;
        final position = tester
            .state<ScrollableState>(galleryScrollable)
            .position;
        final initialPixels = position.pixels;
        final initialDots = _galleryDotColors(tester, gallery);
        expect(initialDots, hasLength(5));

        Offset? successfulSwipe;
        for (final offset in [const Offset(-260, 0), const Offset(260, 0)]) {
          await tester.drag(pageView, offset);
          await tester.pumpAndSettle();
          if ((position.pixels - initialPixels).abs() > 1) {
            successfulSwipe = offset;
            break;
          }
        }

        expect(successfulSwipe, isNotNull);
        expect((position.pixels - initialPixels).abs(), greaterThan(1));
        final advancedDots = _galleryDotColors(tester, gallery);
        expect(advancedDots, isNot(initialDots));

        await tester.drag(
          pageView,
          Offset(-successfulSwipe!.dx, -successfulSwipe.dy),
        );
        await tester.pumpAndSettle();

        expect(position.pixels, closeTo(initialPixels, 1));
        expect(_galleryDotColors(tester, gallery), initialDots);
        expect(tester.takeException(), isNull);
      });

      testWidgets('paid promotion and verification remain independent', (
        tester,
      ) async {
        await _setViewport(tester, const Size(426, 820));
        final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

        await tester.pumpWidget(
          _profileApp(listing: _listing(sponsored: true, verified: false)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ReferencePremiumBadge), findsOneWidget);
        expect(find.text(l10n.referenceVerified), findsNothing);

        await tester.pumpWidget(
          _profileApp(listing: _listing(sponsored: false, verified: true)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ReferencePremiumBadge), findsNothing);
        expect(find.text(l10n.referenceVerified), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    },
  );
}

void _expectAllSections(WidgetTester tester, AppLocalizations l10n) {
  expect(find.text(l10n.referenceAboutProfessional), findsOneWidget);
  expect(find.text(l10n.referencePreviousWork), findsOneWidget);
  expect(find.text(l10n.referenceServiceAreas), findsOneWidget);
  expect(find.text(l10n.referenceWorkingApproach), findsOneWidget);
  expect(find.text(l10n.reviewsSheetTitle), findsWidgets);
}

Finder _actionButton(WidgetTester tester, String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first;

List<Color?> _galleryDotColors(WidgetTester tester, Finder gallery) => tester
    .widgetList<Container>(
      find.descendant(
        of: gallery,
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container || widget.decoration is! BoxDecoration) {
            return false;
          }
          return (widget.decoration! as BoxDecoration).shape == BoxShape.circle;
        }),
      ),
    )
    .map((dot) => (dot.decoration! as BoxDecoration).color)
    .toList();

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _profileApp({
  Key? key,
  ContractorListing? listing,
  double textScale = 1,
}) {
  final profileListing = listing ?? ProfessionalReferenceFixture.noorListing;
  return ProviderScope(
    key: key,
    overrides: [
      portfolioForContractorProvider(profileListing.id).overrideWith(
        (_) async =>
            ProfessionalReferenceFixture.projectsForId(profileListing.id),
      ),
      reviewsForContractorProvider(profileListing.id).overrideWith(
        (_) async =>
            ProfessionalReferenceFixture.reviewsForId(profileListing.id),
      ),
      savedContractorIdsProvider.overrideWith((_) async => <String>{}),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: BatshTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: ReferenceProfessionalProfile(listing: profileListing),
          ),
        ),
      ),
    ),
  );
}

ContractorListing _listing({required bool sponsored, required bool verified}) {
  final original = ProfessionalReferenceFixture.noorListing;
  return ContractorListing(
    id: original.id,
    fullName: original.fullName,
    businessName: original.businessName,
    specialties: original.specialties,
    serviceAreas: original.serviceAreas,
    projectsCompleted: original.projectsCompleted,
    bio: original.bio,
    logoUrl: original.logoUrl,
    coverPhotoUrl: original.coverPhotoUrl,
    headline: original.headline,
    yearsExperience: original.yearsExperience,
    reviewCount: original.reviewCount,
    reviewAvg: original.reviewAvg,
    verified: verified,
    plan: 'pro',
    planExpiresAt: original.planExpiresAt,
    isSponsored: sponsored,
    memberSince: original.memberSince,
    providerKind: original.providerKind,
  );
}
