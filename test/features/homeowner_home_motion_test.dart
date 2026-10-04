import 'package:batsh/core/widgets/professional_reference_navigation.dart';
import 'package:batsh/core/widgets/professional_reference_primitives.dart';
import 'package:batsh/features/home/presentation/widgets/reference_home_experience.dart';
import 'package:batsh/features/onboarding/presentation/homeowner/homeowner_details_screen.dart';
import 'package:batsh/features/onboarding/presentation/homeowner/location_screen.dart';
import 'package:batsh/features/onboarding/presentation/role_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/homeowner_reference_harness.dart';

void main() {
  setUpAll(initializeHomeownerTestClient);
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('Arabic reference home controls and layout $width/$scale', (
        tester,
      ) async {
        await pumpHomeownerReference(
          tester,
          query: 'scenario=noactive&textScale=$scale',
          size: Size(width, 844),
        );
        expect(
          Directionality.of(
            tester.element(find.byType(ReferenceHomeExperience)),
          ),
          TextDirection.rtl,
        );
        final notification = find.byWidgetPredicate(
          (w) => w is IconButton && w.tooltip == 'الإشعارات',
        );
        expect(tester.getSize(notification).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(notification).height, greaterThanOrEqualTo(48));
        final saves = find.byWidgetPredicate(
          (w) => w is IconButton && w.tooltip == 'حفظ المحترف',
        );
        expect(saves, findsWidgets);
        for (final save in saves.evaluate()) {
          final size = tester.getSize(find.byWidget(save.widget));
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        final nav = find.byType(ProfessionalReferenceNavigation);
        expect(nav, findsOneWidget);
        final semantics = find.descendant(
          of: nav,
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.button == true,
          ),
        );
        expect(semantics, findsNWidgets(5));
        for (final target in semantics.evaluate()) {
          final size = tester.getSize(find.byWidget(target.widget));
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        final home = find.byType(ReferenceHomeExperience);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(home, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final step in [1, 2, 3]) {
    testWidgets(
      'onboarding $step safe area keyboard insets and scroll at 320/1.3',
      (tester) async {
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 20);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await pumpHomeownerReference(
          tester,
          query: 'scenario=onboarding$step&textScale=1.3',
          size: const Size(320, 844),
        );
        final footer = find.byType(ProfessionalReferencePrimaryButton);
        final button = find.descendant(
          of: footer,
          matching: find.byType(ElevatedButton),
        );
        expect(tester.getSize(button).height, greaterThanOrEqualTo(56));
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        final before = tester.getRect(button);
        expect(before.bottom, lessThanOrEqualTo(564));
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.getRect(button), before);
        expect(MediaQuery.disableAnimationsOf(tester.element(footer)), isTrue);
        expect(
          find.byType(switch (step) {
            1 => RoleSelectScreen,
            2 => HomeownerDetailsScreen,
            _ => LocationScreen,
          }),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'reduced-motion busy action is static and cannot duplicate submission',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpHomeownerReference(
        tester,
        query: 'scenario=onboarding2&saveDelay=600',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      final primary = tester.widget<ProfessionalReferencePrimaryButton>(
        find.byType(ProfessionalReferencePrimaryButton),
      );
      expect(primary.isLoading, isTrue);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pumpAndSettle();
      expect(find.byType(LocationScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
