import 'package:batsh/core/router/routes.dart';
import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:batsh/core/widgets/professional_reference_navigation.dart';
import 'package:batsh/features/auth/presentation/providers/auth_provider.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/home/presentation/widgets/reference_home_experience.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../support/homeowner_reference_harness.dart';

void main() {
  setUpAll(initializeHomeownerTestClient);
  testWidgets(
    'guest start action retains sign-in gate without creating request',
    (tester) async {
      await pumpHomeownerReference(
        tester,
        query: 'scenario=noactive&notificationState=empty',
        extraOverrides: [currentSessionProvider.overrideWithValue(null)],
      );
      final router = GoRouter.of(
        tester.element(find.byType(ReferenceHomeExperience)),
      );
      await tester.tap(find.text('ابدأ مشروعك'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        Routes.homeownerHome,
      );
      expect(find.text('طلب مشروع جديد'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final entry in [
    ('الرئيسية', Routes.homeownerHome),
    ('المحترفين', Routes.homeownerDiscover),
    ('مشاريعي', Routes.homeownerRequests),
    ('المجتمع', Routes.homeownerExplore),
    ('حسابك', Routes.homeownerProfile),
  ]) {
    testWidgets('home tab ${entry.$1} preserves branch route', (tester) async {
      final container = await pumpHomeownerReference(
        tester,
        disposeInTearDown: false,
      );
      final router = GoRouter.of(
        tester.element(find.byType(ReferenceHomeExperience)),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(ProfessionalReferenceNavigation),
          matching: find.text(
            entry.$2 == Routes.homeownerDiscover
                ? tester
                      .element(find.byType(ReferenceHomeExperience))
                      .l10n
                      .tabDiscover
                : entry.$1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        entry.$2,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
  }
  for (final kind in ['profile', 'work', 'community']) {
    testWidgets('visible $kind action retains source identifier', (
      tester,
    ) async {
      final container = await pumpHomeownerReference(
        tester,
        query: 'scenario=noactive&notificationState=empty',
        disposeInTearDown: false,
      );
      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      final router = GoRouter.of(
        tester.element(find.byType(ReferenceHomeExperience)),
      );
      final professional = experience.featuredProfessionals.first;
      final Finder target;
      final String path;
      switch (kind) {
        case 'profile':
          target = find.text(professional.name).first;
          path = Routes.homeownerContractorProfilePath(professional.id);
        case 'quote':
          target = find.text('اطلب عرض').first;
          path = Routes.homeownerSendBriefPath(professional.id);
        case 'work':
          target = find.text(experience.work!.title).first;
          path = Routes.homeownerProjectDetailPath(
            experience.work!.contractorId,
            experience.work!.id,
          );
        default:
          target = find.text(experience.communityPosts.first.authorName).first;
          path = Routes.homeownerCommunityPostPath(
            experience.communityPosts.first.id,
          );
      }
      await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        path,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
  }
  for (final action in [
    ('ابدأ مشروعك', Routes.homeownerNewPost),
    ('فلترة', Routes.homeownerDiscover),
    ('اسأل مساعد شطب', Routes.homeownerAssistant),
  ]) {
    testWidgets('visible home action ${action.$1} reaches existing route', (
      tester,
    ) async {
      await pumpHomeownerReference(
        tester,
        query: 'scenario=noactive&notificationState=empty',
        nativeSafeAreas: true,
      );
      final router = GoRouter.of(
        tester.element(find.byType(ReferenceHomeExperience)),
      );
      final target = find.text(action.$1);
      await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      // Imperative push retains the browser URL by default; inspect the actual
      // delegate match stack, not routeInformationProvider's base location.
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        action.$2,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'quote callback remains available after reference removes card footer',
    (tester) async {
      await pumpHomeownerReference(tester);
      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      final router = GoRouter.of(
        tester.element(find.byType(ReferenceHomeExperience)),
      );
      final professional = experience.featuredProfessionals.first;
      expect(find.text('اطلب عرض'), findsNothing);
      experience.onRequestQuote(professional.id);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        Routes.homeownerSendBriefPath(professional.id),
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final entry in [
    ('تشطيبات', 'full_reno'),
    ('تصميم', 'design'),
    ('مطابخ', 'kitchen'),
    ('كهرباء', 'electrical'),
    ('سباكة', 'plumbing'),
  ]) {
    testWidgets('visible service ${entry.$1} retains original key', (
      tester,
    ) async {
      final container = await pumpHomeownerReference(
        tester,
        nativeSafeAreas: true,
      );
      final router = GoRouter.of(
        tester.element(find.byType(ReferenceHomeExperience)),
      );
      await tester.tap(find.text(entry.$1).first);
      await tester.pumpAndSettle();
      expect(
        container.read(discoveryFiltersControllerProvider).specialty,
        entry.$2,
      );
      expect(
        router.routeInformationProvider.value.uri.path,
        Routes.homeownerDiscover,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('hero clear removes query and filter without navigation', (
    tester,
  ) async {
    final container = await pumpHomeownerReference(tester);
    await tester.enterText(find.byType(TextField).first, '  نور ');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('امسح البحث'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
    expect(
      container.read(discoveryFiltersControllerProvider).searchQuery,
      isNull,
    );
    expect(find.byType(ReferenceHomeExperience), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
