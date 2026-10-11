import 'package:batsh/features/home/domain/reference_home_data.dart';
import 'package:batsh/features/home/presentation/widgets/reference_home_experience.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/discovery/data/discovery_repository.dart';
import 'package:batsh/features/saved/presentation/providers/saved_providers.dart';
import 'package:batsh/features/explore/domain/post.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../support/homeowner_reference_harness.dart';

void main() {
  setUpAll(initializeHomeownerTestClient);
  test(
    'Arabic identity and anonymous author literals survive UTF8 tooling',
    () {
      expect(ReferenceHomePreviewData.professionals.map((p) => p.name), [
        'خالد للمطابخ',
        'نور للتصميم',
      ]);
      expect(ReferenceHomePreviewData.nearby.last.reviewCount, 0);
      expect(
        ReferenceHomePreviewData.professionalForId(
          'preview-finishing-ahmed',
        ).name,
        'أحمد للتشطيب',
      );
      final post = ReferenceHomeCommunityPost.fromPost(
        Post(
          id: 'ordinary',
          authorId: 'anonymous',
          authorRole: 'homeowner',
          postType: PostType.tip,
          caption: 'تجربة',
          createdAt: DateTime.utc(2026),
        ),
        timeLabel: 'اليوم',
      );
      expect(post.authorName, 'عضو في المجتمع');
      expect(post.badge, 'من واقع التجربة');
      expect(post.isQuestion, false);
    },
  );
  testWidgets(
    'all reference collections preserve vertical hierarchy and sample gate',
    (tester) async {
      await pumpHomeownerReference(tester, size: const Size(393, 852));
      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      final keys = [
        'home-clone-featured',
        'home-clone-nearby',
        'home-clone-story',
        'home-clone-top-rated',
        'home-clone-kitchens',
        'home-clone-finishing',
        'home-clone-community',
      ];
      var prior = -double.infinity;
      for (final key in keys) {
        final top = tester.getTopLeft(find.byKey(ValueKey(key))).dy;
        expect(top, greaterThan(prior));
        prior = top;
      }
      expect(
        experience.featuredProfessionals.every(
          (p) => p.id.startsWith('preview-'),
        ),
        referenceHomePreviewEnabled,
      );
      expect(
        experience.work!.mediaKind,
        referenceHomePreviewEnabled
            ? ReferenceHomeWorkMediaKind.verifiedBeforeAfter
            : ReferenceHomeWorkMediaKind.gallery,
      );
      if (referenceHomePreviewEnabled) {
        final unrated = find.ancestor(
          of: find.text('حسام للنجارة'),
          matching: find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ProfessionalRow',
          ),
        );
        expect(
          find.descendant(
            of: unrated,
            matching: find.text('جديد · بدون تقييمات'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: unrated, matching: find.text('0.0')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'specialty view-all retains search city sort and rating selection',
    (tester) async {
      final container = await pumpHomeownerReference(tester);
      final controller = container.read(
        discoveryFiltersControllerProvider.notifier,
      );
      controller.setSearch('ورشة');
      controller.setCity('القاهرة');
      controller.setSort(DiscoverySort.rating);
      controller.setMinimumRating(4);
      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      experience.onOpenKitchens!();
      await tester.pumpAndSettle();
      final filters = container.read(discoveryFiltersControllerProvider);
      expect(filters.specialty, 'kitchen');
      expect(filters.searchQuery, 'ورشة');
      expect(filters.city, 'القاهرة');
      expect(filters.sort, DiscoverySort.rating);
      expect(filters.minimumRating, 4);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'heart targets are independent and preview saves stay out of shared saved state',
    (tester) async {
      final container = await pumpHomeownerReference(tester);
      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      final id = experience.featuredProfessionals.first.id;
      final target = find
          .byWidgetPredicate(
            (w) =>
                w is IconButton &&
                (w.tooltip?.endsWith(
                      ': ${experience.featuredProfessionals.first.name}',
                    ) ??
                    false),
          )
          .first;
      await Scrollable.ensureVisible(tester.element(target), alignment: .3);
      await tester.pumpAndSettle();
      final rect = tester.getRect(target);
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      final router = GoRouter.of(
        tester.element(find.byType(ReferenceHomeExperience)),
      );
      final previous =
          router.routerDelegate.currentConfiguration.last.matchedLocation;
      final sharedBefore = Set<String>.of(
        container.read(savedContractorIdsProvider).value ?? <String>{},
      );
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        previous,
      );
      expect(
        tester
            .widget<ReferenceHomeExperience>(
              find.byType(ReferenceHomeExperience),
            )
            .savedProfessionalIds,
        contains(id),
      );
      if (referenceHomePreviewEnabled) {
        expect(
          container.read(savedContractorIdsProvider).value ?? <String>{},
          sharedBefore,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'English Home with long identities and enlarged text reflows at320',
    (tester) async {
      final container = await pumpHomeownerReference(
        tester,
        size: const Size(320, 852),
        query: 'scenario=noactive&textScale=1.3',
        configureScenario: (scenario) {
          scenario.profile = scenario.profile.copyWith(
            fullName: 'Mariam Alexandria Long Homeowner Name',
          );
          scenario.homeownerProfile = scenario.homeownerProfile!.copyWith(
            city: 'New Cairo Extended Residential District',
          );
        },
      );
      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 852),
                textScaler: TextScaler.linear(1.3),
              ),
              child: Scaffold(body: SingleChildScrollView(child: experience)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(ReferenceHomeExperience))),
        TextDirection.ltr,
      );
      expect(tester.takeException(), isNull);
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('home-clone-community'))),
        alignment: 1,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'narrow enlarged header keeps the brand icon beside its wordmark',
    (tester) async {
      await pumpHomeownerReference(
        tester,
        query: 'scenario=noactive&textScale=1.3',
        size: const Size(320, 852),
        configureScenario: (scenario) {
          scenario.homeownerProfile = scenario.homeownerProfile!.copyWith(
            city: 'القاهرة الجديدة والمنطقة العمرانية الممتدة',
          );
        },
      );
      final header = find.byType(ReferenceHomeHeader);
      final word = find.descendant(
        of: header,
        matching: find.text(tester.element(header).l10n.appName),
      );
      final icon = find.descendant(
        of: header,
        matching: find.byIcon(Icons.home_rounded),
      );
      expect(word, findsOneWidget);
      expect(icon, findsOneWidget);
      expect(
        (tester.getCenter(word).dy - tester.getCenter(icon).dy).abs(),
        lessThan(4),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('service toolbar opens real chooser and applies category', (
    tester,
  ) async {
    final container = await pumpHomeownerReference(tester);
    final control = find.text('الخدمة: الكل');
    await Scrollable.ensureVisible(tester.element(control), alignment: .3);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    final category = find.descendant(
      of: find.byType(ListTile),
      matching: find.text('تصميم داخلي'),
    );
    await Scrollable.ensureVisible(tester.element(category), alignment: .3);
    await tester.pumpAndSettle();
    await tester.tap(category);
    await tester.pumpAndSettle();
    expect(
      container.read(discoveryFiltersControllerProvider).specialty,
      'design',
    );
    expect(tester.takeException(), isNull);
  });
}
