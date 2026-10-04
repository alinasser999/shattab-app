import 'package:batsh/features/auth/domain/profile.dart';
import 'package:batsh/features/discovery/presentation/professional_directory_screen.dart';
import 'package:batsh/features/onboarding/presentation/homeowner/homeowner_details_screen.dart';
import 'package:batsh/features/onboarding/presentation/homeowner/location_screen.dart';
import 'package:batsh/features/onboarding/presentation/providers/onboarding_draft_provider.dart';
import 'package:batsh/features/onboarding/presentation/role_select_screen.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/homeowner_reference_harness.dart';

void main() {
  setUpAll(initializeHomeownerTestClient);
  testWidgets(
    'first-run role and name validation focuses actual missing name',
    (tester) async {
      final container = await pumpHomeownerReference(
        tester,
        query: 'scenario=onboarding1&blank=true&textScale=1.3',
        size: const Size(320, 844),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoleSelectScreen)),
      )!;
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.onboardingRoleRequired), findsOneWidget);
      final role = find.text(l10n.roleHomeowner);
      await tester.ensureVisible(role);
      await tester.tap(role);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.onboardingNameRequired), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.enterText(find.byType(TextField), 'أحمد صالح');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeownerDetailsScreen), findsOneWidget);
      expect(container.read(onboardingDraftProvider).fullName, 'أحمد صالح');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'locked homeowner role cannot change; back restores edited name',
    (tester) async {
      final container = await pumpHomeownerReference(
        tester,
        query: 'scenario=onboarding1',
      );
      final roleNodes = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.selected == true,
      );
      expect(roleNodes, findsWidgets);
      await tester.enterText(find.byType(TextField), 'اسم محفوظ');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeownerDetailsScreen), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(HomeownerDetailsScreen)),
      )!;
      await tester.tap(find.text(l10n.back));
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'اسم محفوظ',
      );
      expect(container.read(onboardingDraftProvider).role, UserRole.homeowner);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'details required groups focus and retain draft after failure and retry',
    (tester) async {
      final container = await pumpHomeownerReference(
        tester,
        query: 'scenario=onboarding2&failOnce=true',
        extraOverrides: [onboardingDraftProvider.overrideWith(_EmptyDraft.new)],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(HomeownerDetailsScreen)),
      )!;
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'apartment type');
      final apartment = find.text(l10n.apartmentTwoBedroom);
      await tester.ensureVisible(apartment);
      await tester.tap(apartment);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'renovation interests',
      );
      final design = find.text(l10n.specialtyDesign);
      await tester.ensureVisible(design);
      await tester.tap(design);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeownerDetailsScreen), findsOneWidget);
      expect(
        container.read(onboardingDraftProvider).renovationInterests,
        contains('design'),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(LocationScreen), findsOneWidget);
      await tester.tap(find.text(l10n.back));
      await tester.pumpAndSettle();
      expect(find.byType(HomeownerDetailsScreen), findsOneWidget);
      expect(
        container.read(onboardingDraftProvider).renovationInterests,
        contains('design'),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'city district validation and failure retry complete to discovery',
    (tester) async {
      final container = await pumpHomeownerReference(
        tester,
        query: 'scenario=onboarding3&failOnce=true',
        extraOverrides: [onboardingDraftProvider.overrideWith(_EmptyDraft.new)],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LocationScreen)),
      )!;
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.onboardingCityRequired), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'homeowner city');
      final city = find.text('القاهرة الجديدة');
      await tester.ensureVisible(city);
      await tester.tap(city);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.onboardingDistrictRequired), findsOneWidget);
      final district = find.text('التجمع الخامس');
      await tester.ensureVisible(district);
      await tester.tap(district);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(LocationScreen), findsOneWidget);
      expect(container.read(onboardingDraftProvider).district, 'التجمع الخامس');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(ProfessionalDirectoryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _EmptyDraft extends OnboardingDraftController {
  @override
  OnboardingDraft build() => const OnboardingDraft(
    accountId: 'fixture-homeowner-001',
    role: UserRole.homeowner,
    fullName: 'أحمد محمد',
    fullNameEdited: true,
    homeownerDetailsEdited: true,
    homeownerLocationEdited: true,
  );
}
