import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:go_router/go_router.dart';
import 'package:batsh/features/auth/domain/profile.dart';
import 'package:batsh/core/models/draft_photo.dart';
import 'package:batsh/core/widgets/photo_picker.dart';
import 'package:batsh/core/widgets/professional_reference_states.dart';
import 'package:batsh/core/widgets/professional_reference_primitives.dart';
import 'package:batsh/features/home/domain/empty_states_reference_fixture.dart';
import 'package:batsh/features/quotes/domain/quote.dart';
import 'package:batsh/features/quotes/presentation/providers/quotes_providers.dart';
import 'package:batsh/features/quotes/presentation/widgets/quotes_received_section.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/discovery/presentation/widgets/reference_professional_profile.dart';
import 'package:batsh/features/explore/presentation/widgets/community_feed_widgets.dart';
import 'package:batsh/features/auth/presentation/providers/auth_provider.dart';
import 'package:batsh/features/onboarding/presentation/contractor/company_profile_screen.dart';
import 'package:batsh/features/onboarding/presentation/contractor/contractor_services_screen.dart';
import 'package:batsh/features/onboarding/presentation/contractor/experience_screen.dart';
import 'package:batsh/features/onboarding/presentation/providers/onboarding_draft_provider.dart';
import 'package:batsh/features/onboarding/data/onboarding_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/empty_states_harness.dart';

void main() {
  setUpAll(initializeEmptyStateTests);
  test('local logo fixture decodes into an eight by eight image', () async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAE0lEQVR4nGP4//vLf3yYYWQoAACWd/tB2yDuvwAAAABJRU5ErkJggg==',
    );
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 8);
    expect(frame.image.height, 8);
    frame.image.dispose();
    codec.dispose();
  });
  for (final width in [390.0, 320.0]) {
    for (final scene in [
      'A1',
      'A2',
      'A3',
      'A4',
      'A5',
      'A6',
      'B1',
      'B2',
      'B3',
      'B4',
      'B5',
      'B6',
      'B7',
      'B8',
      'B9',
      'B10',
      'B11',
      'B12',
      'C3',
      'C4',
      'C5',
      'C6',
      'profile',
      'quotes',
      'projects',
      'signin',
    ]) {
      testWidgets('mounted $scene fits Arabic $width at text1.3', (
        tester,
      ) async {
        final result = await pumpEmptyScene(
          tester,
          scene,
          size: Size(width, 844),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
        expect(
          result.fixture.actions.where(
            (a) => a.startsWith('blocked transport'),
          ),
          isEmpty,
        );
      });
    }
  }
  for (final entry in [
    ('B3', '/h/discover'),
    ('B6', '/h/home'),
    ('B7', '/c/portfolio/new'),
    ('B8', '/h/discover/contractor/empty-reference-professional'),
  ]) {
    testWidgets('${entry.$1} real empty action navigates to ${entry.$2}', (
      tester,
    ) async {
      final result = await pumpEmptyScene(tester, entry.$1);
      final primary = find
          .descendant(
            of: find.byType(ProfessionalReferenceState),
            matching: find.byType(ProfessionalReferencePrimaryButton),
          )
          .first;
      await tester.ensureVisible(primary);
      await tester.tap(primary);
      await tester.pumpAndSettle();
      expect(result.fixture.actions, contains('router location:${entry.$2}'));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'directory filtered empty clears actual filter and reissues read',
    (tester) async {
      final r = await pumpEmptyScene(tester, 'B5');
      expect(
        r.container.read(discoveryFiltersControllerProvider).searchQuery,
        isNotEmpty,
      );
      await act(tester, l10n(tester).stateClearSearchFilters);
      expect(
        r.container.read(discoveryFiltersControllerProvider).searchQuery,
        isNull,
      );
      expect(r.fixture.actions, contains('directory:all'));
      expect(tester.takeException(), isNull);
    },
  );
  for (final scene in ['C1', 'C2']) {
    testWidgets(
      '$scene actual directory read failure stays distinct and retries',
      (tester) async {
        final r = await pumpEmptyScene(tester, scene, settle: false);
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        final copy = l10n(tester);
        expect(
          find.text(
            scene == 'C2' ? copy.stateOfflineTitle : copy.stateReadErrorTitle,
          ),
          findsOneWidget,
        );
        expect(find.byType(ProfessionalReferenceState), findsOneWidget);
        final attempts = r.fixture.actions
            .where((a) => a.startsWith('directory:'))
            .length;
        await act(tester, copy.tryAgain);
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(
          r.fixture.actions.where((a) => a.startsWith('directory:')).length,
          greaterThan(attempts),
        );
        expect(
          find.text(
            scene == 'C2' ? copy.stateOfflineTitle : copy.stateReadErrorTitle,
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('both actual profile empty CTAs reveal Services section', (
    tester,
  ) async {
    await pumpEmptyScene(tester, 'profile');
    final copy = l10n(tester);
    final actions = find.text(copy.stateServicesAction);
    expect(actions, findsNWidgets(2));
    for (final index in [0, 1]) {
      await tester.ensureVisible(actions.at(index));
      await tester.pumpAndSettle();
      await tester.tap(actions.at(index));
      await tester.pumpAndSettle();
      final headings = find.text(copy.referenceServices);
      final section = headings.last;
      expect(tester.getRect(section).top, inInclusiveRange(0, 844));
      expect(tester.getRect(section).bottom, lessThan(844));
    }
    expect(find.byType(ReferenceProfessionalProfile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reviews empty action dismisses only the sheet', (tester) async {
    await pumpEmptyScene(tester, 'B9');
    final copy = l10n(tester);
    expect(find.byType(ProfessionalReferenceState), findsOneWidget);
    await act(tester, copy.stateCloseAction);
    expect(find.byType(ProfessionalReferenceState), findsNothing);
    expect(find.text('عرض التقييمات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('B1 actual home start opens existing creation flow', (
    tester,
  ) async {
    final r = await pumpEmptyScene(tester, 'B1');
    await act(tester, l10n(tester).homeReferenceHeroPrimary);
    expect(r.fixture.actions, contains('router location:/h/requests/new-post'));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'guest saved opens access sheet and dismissal stays unauthenticated',
    (tester) async {
      final r = await pumpEmptyScene(tester, 'B4');
      final primary = find
          .descendant(
            of: find.byType(ProfessionalReferenceState),
            matching: find.byType(ProfessionalReferencePrimaryButton),
          )
          .first;
      await tester.ensureVisible(primary);
      await tester.tap(primary);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(r.container.read(currentSessionProvider), isNull);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(r.container.read(currentSessionProvider), isNull);
      expect(
        r.fixture.actions.where((a) => a == 'sendOtp' || a == 'verifyOtp'),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('filtered community clear selects all and removes clear action', (
    tester,
  ) async {
    await pumpEmptyScene(tester, 'B11');
    final copy = l10n(tester);
    expect(
      tester.widget<FeedFilterChips>(find.byType(FeedFilterChips)).selected,
      CommunityFeedFilter.requests,
    );
    await act(tester, copy.communityClearFilter);
    expect(
      tester.widget<FeedFilterChips>(find.byType(FeedFilterChips)).selected,
      CommunityFeedFilter.all,
    );
    expect(find.text(copy.communityClearFilter), findsNothing);
    expect(find.text(copy.stateCommunityAllTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('My Projects filtered zero clears local filter only', (
    tester,
  ) async {
    final r = await pumpEmptyScene(tester, 'projects');
    final copy = l10n(tester);
    final reads = r.fixture.actions.where((a) => a == 'myBriefs').length;
    await act(tester, copy.homeownerOrdersCompleted);
    expect(find.text(copy.stateProjectsNoResultsMessage), findsOneWidget);
    await act(tester, copy.clearFilters);
    expect(find.text(copy.homeownerOrdersEmptyTitle), findsOneWidget);
    expect(r.fixture.actions.where((a) => a == 'myBriefs').length, reads);
    expect(tester.takeException(), isNull);
  });
  for (final role in [false, true]) {
    for (final scene in ['B10', 'B12']) {
      testWidgets('$scene home exit follows actual profile role $role', (
        tester,
      ) async {
        final r = await pumpEmptyScene(tester, scene, contractorRole: role);
        final primary = find
            .descendant(
              of: find.byType(ProfessionalReferenceState),
              matching: find.byType(ProfessionalReferencePrimaryButton),
            )
            .first;
        await tester.ensureVisible(primary);
        await tester.tap(primary);
        await tester.pumpAndSettle();
        expect(
          r.fixture.actions,
          contains('router location:${role ? '/c/dashboard' : '/h/home'}'),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final fallback in ['guest', 'loading', 'error', 'null']) {
    testWidgets('B10 safe home fallback for $fallback profile', (tester) async {
      final r = await pumpEmptyScene(
        tester,
        'B10',
        extraOverrides: [
          if (fallback == 'guest')
            currentSessionProvider.overrideWith((_) => null),
          currentProfileProvider.overrideWith(
            () => _UnresolvedNotificationProfile(fallback),
          ),
        ],
      );
      await act(tester, l10n(tester).stateHomeAction);
      final location = GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      ).routeInformationProvider.value.uri.path;
      expect(location, fallback == 'guest' ? '/h/home' : '/');
      expect(
        r.fixture.actions,
        isNot(contains('router location:/c/dashboard')),
      );
      if (fallback != 'guest') {
        expect(r.fixture.actions, isNot(contains('router location:/h/home')));
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final scale in [1.0, 1.3]) {
    testWidgets(
      'C6 service tile retains geometry and selection at scale$scale',
      (tester) async {
        await pumpEmptyScene(tester, 'C6', textScale: scale);
        final tiles = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_ChoiceTile',
        );
        expect(tiles, findsNWidgets(8));
        final heights = <double>[];
        for (var i = 0; i < 8; i++) {
          final container = find.descendant(
            of: tiles.at(i),
            matching: find.byType(AnimatedContainer),
          );
          final rect = tester.getRect(container);
          expect(rect.width, 108);
          expect(rect.height, greaterThanOrEqualTo(94));
          heights.add(rect.height);
          final text = tester.widget<Text>(
            find.descendant(of: tiles.at(i), matching: find.byType(Text)),
          );
          expect(text.maxLines, isNull);
          expect(text.overflow, isNull);
        }
        if (scale == 1) {
          expect(heights, everyElement(94));
        } else {
          expect(heights.any((h) => h > 94), isTrue);
        }
        await tester.ensureVisible(tiles.first);
        await tester.tap(tiles.first);
        await tester.pumpAndSettle();
        final semantics = tester.widget<Semantics>(
          find
              .descendant(of: tiles.first, matching: find.byType(Semantics))
              .first,
        );
        expect(semantics.properties.selected, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('no quotes retain real project and refresh only its quotes', (
    tester,
  ) async {
    final r = await pumpEmptyScene(tester, 'B2');
    final beforeBrief = r.fixture.actions.where((a) => a == 'myBriefs').length;
    final beforeQuote = r.fixture.actions
        .where((a) => a == 'quotesForBrief:empty-reference-brief')
        .length;
    expect(find.text('مشروع تجديد الشقة'), findsOneWidget);
    await act(tester, l10n(tester).homeownerReferenceOffers(0));
    expect(find.text(l10n(tester).briefDetailTitle), findsOneWidget);
    expect(find.text(r.fixture.brief.workDescription), findsOneWidget);
    // BriefDetailScreen lazily builds its lower quote section in the outer list.
    await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.byType(QuotesReceivedSection), findsOneWidget);
    await tester.ensureVisible(find.byType(QuotesReceivedSection));
    await tester.pumpAndSettle();
    final emptyQuotesCopy = l10n(tester);
    expect(find.text(emptyQuotesCopy.noQuotesYet), findsOneWidget);
    expect(find.text(emptyQuotesCopy.stateQuotesRefresh), findsOneWidget);
    final quotesList = find.descendant(
      of: find.byType(QuotesReceivedSection),
      matching: find.byType(ListView),
    );
    expect(quotesList, findsOneWidget);
    // The quote section is an always-scrollable list with a RefreshIndicator.
    // Pull it down as a homeowner would instead of invoking the empty-state
    // CTA, which may be outside the currently built viewport.
    await tester.drag(quotesList, const Offset(0, 360));
    await tester.pumpAndSettle();
    expect(r.fixture.actions.where((a) => a == 'myBriefs').length, beforeBrief);
    expect(
      r.fixture.actions
          .where((a) => a == 'quotesForBrief:empty-reference-brief')
          .length,
      beforeQuote + 1,
    );
    final cancelAction = find.text(emptyQuotesCopy.cancelButton);
    await tester.dragUntilVisible(
      cancelAction,
      find.text(emptyQuotesCopy.quotesSectionTitle),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.dragFrom(
      tester.getCenter(cancelAction),
      const Offset(0, 1200),
    );
    await tester.pumpAndSettle();
    expect(find.text(r.fixture.brief.workDescription), findsOneWidget);
    expect(
      r.fixture.actions
          .where((a) => a == 'quotesForBrief:empty-reference-brief')
          .length,
      beforeQuote + 1,
    );
    expect(tester.takeException(), isNull);
  });
  for (final failed in [false, true]) {
    testWidgets(
      'actual home retains project and hides unknown quote count: failure=$failed',
      (tester) async {
        final pending = Completer<List<Quote>>();
        await pumpEmptyScene(
          tester,
          'B2',
          settle: false,
          extraOverrides: [
            quotesForBriefProvider(
              'empty-reference-brief',
            ).overrideWith((_) => pending.future),
          ],
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('مشروع تجديد الشقة'), findsOneWidget);
        final copy = l10n(tester);
        expect(find.text(copy.homeownerReferenceOffers(0)), findsNothing);
        if (failed) {
          pending.completeError(StateError('local read failure'));
        } else {
          pending.complete([]);
        }
        await tester.pumpAndSettle();
        expect(find.text('مشروع تجديد الشقة'), findsOneWidget);
        expect(
          find.text(copy.homeownerReferenceOffers(0)),
          failed ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'identity validation focuses name; failed save keeps draft and retry',
    (tester) async {
      final r = await pumpEmptyScene(tester, 'C4');
      final copy = l10n(tester);
      await tester.enterText(find.byType(TextField), '');
      await act(tester, copy.next);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'business name');
      await tester.enterText(find.byType(TextField), 'شركة محفوظة');
      await act(tester, copy.next);
      expect(find.byType(CompanyProfileScreen), findsOneWidget);
      expect(find.text(copy.onboardingContinueWithoutLogo), findsNothing);
      expect(
        r.container.read(onboardingDraftProvider).businessName,
        'شركة محفوظة',
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'شركة محفوظة',
      );
      await act(tester, copy.onboardingRetrySave);
      expect(find.byType(ContractorServicesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'optional logo skip only follows saved identity and preserves identity',
    (tester) async {
      final r = await pumpEmptyScene(tester, 'C5');
      final copy = l10n(tester);
      expect(find.text(copy.onboardingContinueWithoutLogo), findsNothing);
      await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
      await tester.pumpAndSettle();
      await act(tester, copy.next);
      expect(
        r.fixture.actions.indexOf('upsertContractor'),
        lessThan(r.fixture.actions.indexOf('uploadLogo')),
      );
      expect(find.byType(CompanyProfileScreen), findsOneWidget);
      await act(tester, copy.onboardingRetryLogo);
      expect(r.fixture.actions.where((a) => a == 'upsertContractor').length, 1);
      expect(r.fixture.actions.where((a) => a == 'uploadLogo').length, 2);
      await act(tester, copy.onboardingContinueWithoutLogo);
      expect(find.byType(ContractorServicesScreen), findsOneWidget);
      expect(
        r.container.read(onboardingDraftProvider).contractorLogoFile,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'services missing fields focus then mandatory chain completes without experience',
    (tester) async {
      final r = await pumpEmptyScene(tester, 'A5');
      final copy = l10n(tester);
      await act(tester, copy.done);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'specialties');
      await act(tester, copy.specialtyPaint);
      await act(tester, copy.done);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'service areas');
      await act(tester, 'القاهرة');
      await act(tester, copy.done);
      expect(r.fixture.actions, contains('markComplete'));
      expect(r.fixture.actions, contains('router location:/c/dashboard'));
      expect(find.byType(ExperienceScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'experience invalid years focus then valid completion retains values',
    (tester) async {
      final r = await pumpEmptyScene(tester, 'A6');
      final copy = l10n(tester);
      await act(tester, copy.done);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'years of experience',
      );
      await tester.enterText(find.byType(TextField).first, '12');
      await tester.enterText(find.byType(TextField).last, 'خبرة محفوظة');
      await act(tester, copy.done);
      expect(r.fixture.professional.yearsExperience, 12);
      expect(r.fixture.professional.bio, 'خبرة محفوظة');
      expect(r.fixture.actions, contains('router location:/c/dashboard'));
      expect(tester.takeException(), isNull);
    },
  );
  for (final scene in ['A5', 'A6']) {
    testWidgets(
      '$scene failed save preserves entered values and retry completes',
      (tester) async {
        final failure = EmptyReferenceFixture('C4');
        final repo = EmptyReferenceOnboardingRepository(
          Supabase.instance.client,
          failure,
        );
        final r = await pumpEmptyScene(
          tester,
          scene,
          extraOverrides: [
            onboardingRepositoryProvider.overrideWithValue(repo),
          ],
        );
        final copy = l10n(tester);
        if (scene == 'A5') {
          await act(tester, copy.specialtyPaint);
          await act(tester, 'القاهرة');
        } else {
          await tester.enterText(find.byType(TextField).first, '12');
          await tester.enterText(
            find.byType(TextField).last,
            'نبذة محفوظة بعد فشل الحفظ',
          );
        }
        await act(tester, copy.done);
        expect(find.byType(ProfessionalReferenceInlineStatus), findsOneWidget);
        expect(find.text(copy.onboardingContinueWithoutLogo), findsNothing);
        if (scene == 'A5') {
          expect(
            r.container.read(onboardingDraftProvider).specialties,
            contains('paint'),
          );
          expect(
            r.container.read(onboardingDraftProvider).serviceAreas,
            contains('القاهرة'),
          );
        } else {
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText).first)
                .controller
                .text,
            '12',
          );
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText).last)
                .controller
                .text,
            'نبذة محفوظة بعد فشل الحفظ',
          );
        }
        await act(tester, copy.onboardingRetrySave);
        expect(r.fixture.actions, contains('router location:/c/dashboard'));
        expect(failure.actions, contains('markComplete'));
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final scene in ['A1', 'A4', 'A6']) {
    testWidgets(
      '$scene focused real input stays reachable at320/text1.3 with keyboard',
      (tester) async {
        await pumpEmptyScene(
          tester,
          scene,
          size: const Size(320, 844),
          textScale: 1.3,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final field = find.byType(TextField).first;
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
        final editable = find.byType(EditableText).first;
        expect(
          tester.widget<EditableText>(editable).focusNode.hasFocus,
          isTrue,
        );
        expect(tester.getRect(editable).bottom, lessThanOrEqualTo(544));
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'photo-picker failure preserves selected photos and retries without skip',
    (tester) async {
      var calls = 0;
      var changes = 0;
      final photo = DraftPhoto(
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAE0lEQVR4nGP4//vLf3yYYWQoAACWd/tB2yDuvwAAAABJRU5ErkJggg==',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoPickerCallbackProvider.overrideWithValue((_) async {
              calls++;
              throw StateError('picker failure');
            }),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PhotoPicker(initial: [photo], onChanged: (_) => changes++),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
      await tester.pumpAndSettle();
      final copy = AppLocalizations.of(
        tester.element(find.byType(PhotoPicker)),
      )!;
      expect(find.text('${copy.photos} (1/5)'), findsOneWidget);
      expect(find.text(copy.onboardingContinueWithoutLogo), findsNothing);
      await tester.tap(find.text(copy.tryAgain));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(changes, 0);
      expect(find.text('${copy.photos} (1/5)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

AppLocalizations l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
Future<void> act(WidgetTester tester, String label) async {
  final f = find.text(label).last;
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.3);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

class _UnresolvedNotificationProfile extends CurrentProfile {
  _UnresolvedNotificationProfile(this.mode);
  final String mode;
  @override
  Future<Profile?> build() {
    if (mode == 'error') return Future.error(StateError('local profile error'));
    if (mode == 'null' || mode == 'guest') return Future.value(null);
    return Completer<Profile?>().future;
  }
}
