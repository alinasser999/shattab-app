import 'package:batsh/features/saved/presentation/providers/saved_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:batsh/core/widgets/professional_reference_primitives.dart';
import 'package:batsh/features/discovery/presentation/professional_directory_screen.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/home/domain/reference_home_data.dart';
import 'package:batsh/features/home/presentation/widgets/reference_home_experience.dart';
import 'package:batsh/features/portfolio/domain/portfolio_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/homeowner_reference_harness.dart';

void main() {
  setUpAll(initializeHomeownerTestClient);
  test(
    'generic portfolio media is deduplicated without false before/after claims',
    () {
      final work = ReferenceHomeWork.fromProject(
        const PortfolioProject(
          id: 'w',
          contractorId: 'c',
          title: 'عمل',
          coverPhotoUrl: ' first ',
          photoUrls: ['first', 'second', ' second '],
          position: 0,
        ),
      );
      expect(work.galleryUrls, ['first', 'second']);
      expect(work.mediaKind, ReferenceHomeWorkMediaKind.gallery);
      expect(work.beforeUrl, isEmpty);
      expect(work.afterUrl, isEmpty);
      expect(work.rating, isNull);
      expect(work.reviewCount, 0);
      expect(work.isPreview, isFalse);
    },
  );
  testWidgets(
    'standalone search retains query in real discovery destination and external updates',
    (tester) async {
      final container = await pumpHomeownerReference(tester);
      final field = find.descendant(
        of: find.byType(ProfessionalReferenceSearch),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'نور');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(ProfessionalDirectoryScreen), findsOneWidget);
      final controller = tester
          .widget<TextField>(find.byType(TextField).first)
          .controller!;
      expect(controller.text, 'نور');
      await tester.enterText(find.byType(TextField).first, '  نور  ');
      final selection = controller.selection;
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.text, '  نور  ');
      expect(controller.selection, selection);
      await tester.enterText(find.byType(TextField).first, 'stale');
      container
          .read(discoveryFiltersControllerProvider.notifier)
          .setSearch('ورشة');
      await tester.pumpAndSettle();
      expect(controller.text, 'ورشة');
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        container.read(discoveryFiltersControllerProvider).searchQuery,
        'ورشة',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('services preserve query while setting the discovery specialty', (
    tester,
  ) async {
    final container = await pumpHomeownerReference(tester);
    container
        .read(discoveryFiltersControllerProvider.notifier)
        .setSearch('نور');
    final design = find.widgetWithText(
      ProfessionalReferenceCategory,
      'تصميم داخلي',
    );
    await Scrollable.ensureVisible(tester.element(design), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(design);
    await tester.pumpAndSettle();
    expect(
      container.read(discoveryFiltersControllerProvider).specialty,
      'design',
    );
    expect(
      container.read(discoveryFiltersControllerProvider).searchQuery,
      'نور',
    );
    expect(find.byType(ProfessionalDirectoryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('local save and profile removal stay synchronized', (
    tester,
  ) async {
    final container = await pumpHomeownerReference(
      tester,
      disposeInTearDown: false,
    );
    final experience = tester.widget<ReferenceHomeExperience>(
      find.byType(ReferenceHomeExperience),
    );
    final id = experience.featuredProfessionals.first.id;
    final save = find
        .byWidgetPredicate((w) => w is IconButton && w.tooltip == 'حفظ المحترف')
        .first;
    await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ReferenceHomeExperience>(find.byType(ReferenceHomeExperience))
          .savedProfessionalIds,
      contains(id),
    );
    experience.onOpenProfessional(id);
    await tester.pumpAndSettle();
    final unsave = find.byTooltip('إزالة من المحفوظات');
    expect(unsave, findsOneWidget);
    final router = GoRouter.of(tester.element(unsave));
    await tester.tap(unsave);
    await tester.pumpAndSettle();
    expect(
      container.read(savedContractorIdsProvider).value,
      isNot(contains(id)),
    );
    router.pop();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ReferenceHomeExperience>(find.byType(ReferenceHomeExperience))
          .savedProfessionalIds,
      isNot(contains(id)),
    );
    // The real route screen and shared local controller are exercised, not a separate saved mock.
    expect(
      container.read(discoveryFiltersControllerProvider).searchQuery,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
  testWidgets('real current-project callback opens its existing destination', (
    tester,
  ) async {
    await pumpHomeownerReference(tester, query: 'scenario=active');
    final experience = tester.widget<ReferenceHomeExperience>(
      find.byType(ReferenceHomeExperience),
    );
    final project = experience.project!;
    experience.onOpenProject(project);
    await tester.pumpAndSettle();
    expect(find.text(project.title), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
