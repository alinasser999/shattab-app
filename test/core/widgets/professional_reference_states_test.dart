import 'dart:async';
import 'package:batsh/core/widgets/professional_reference_states.dart';
import 'package:batsh/core/widgets/professional_reference_primitives.dart';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:batsh/features/onboarding/presentation/widgets/specialty_picker.dart';
import 'package:batsh/core/utils/connectivity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'read adapter marks known offline and retries once on reconnect',
    (tester) async {
      final connection = StreamController<bool>();
      addTearDown(connection.close);
      var retries = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((_) => connection.stream),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ProfessionalReferenceReadError(onRetry: () => retries++),
            ),
          ),
        ),
      );
      connection.add(false);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ProfessionalReferenceState>(
              find.byType(ProfessionalReferenceState),
            )
            .kind,
        ProfessionalReferenceStateKind.offline,
      );
      connection.add(true);
      await tester.pumpAndSettle();
      expect(retries, 1);
      expect(
        tester
            .widget<ProfessionalReferenceState>(
              find.byType(ProfessionalReferenceState),
            )
            .kind,
        ProfessionalReferenceStateKind.error,
      );
      connection.add(true);
      await tester.pumpAndSettle();
      expect(retries, 1);
      await tester.tap(find.byType(ProfessionalReferencePrimaryButton));
      await tester.pump();
      expect(retries, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'every architectural motif paints statically and excludes decoration from semantics',
    (tester) async {
      for (final motif in ProfessionalReferenceMotif.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProfessionalReferenceStateIllustration(motif: motif),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(CustomPaint), findsWidgets);
        expect(
          find.descendant(
            of: find.byType(ProfessionalReferenceStateIllustration),
            matching: find.byType(ExcludeSemantics),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(tester.binding.transientCallbackCount, 0);
      }
    },
  );
  for (final width in [320.0, 390.0]) {
    for (final kind in ProfessionalReferenceStateKind.values) {
      testWidgets(
        '$kind Arabic RTL at $width/1.3 fits, announces errors, and acts',
        (tester) async {
          tester.view.physicalSize = Size(width, 600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final handle = tester.ensureSemantics();
          var primary = 0;
          var secondary = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: BatshTheme.light(),
              locale: const Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 600),
                  textScaler: const TextScaler.linear(1.3),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  viewInsets: const EdgeInsets.only(bottom: 120),
                ),
                child: Scaffold(
                  body: SafeArea(
                    child: ProfessionalReferenceState(
                      kind: kind,
                      title: 'لا توجد نتائج مطابقة لبحثك الآن',
                      message:
                          'يمكنك تغيير اختيارات البحث أو العودة لمتابعة مشروعك.',
                      motif: ProfessionalReferenceMotif.search,
                      primaryLabel: 'غيّر اختيارات البحث لعرض النتائج',
                      onPrimary: () => primary++,
                      secondaryLabel: 'ارجع إلى الصفحة الرئيسية',
                      onSecondary: () => secondary++,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            Directionality.of(
              tester.element(find.byType(ProfessionalReferenceState)),
            ),
            TextDirection.rtl,
          );
          final title = tester.widget<Text>(
            find.text('لا توجد نتائج مطابقة لبحثك الآن'),
          );
          expect(title.style!.fontSize, greaterThanOrEqualTo(22));
          expect(
            tester
                .widget<Text>(
                  find.text(
                    'يمكنك تغيير اختيارات البحث أو العودة لمتابعة مشروعك.',
                  ),
                )
                .style!
                .fontSize,
            greaterThanOrEqualTo(16),
          );
          final header = tester.widget<Semantics>(
            find
                .ancestor(
                  of: find.text(title.data!),
                  matching: find.byType(Semantics),
                )
                .first,
          );
          expect(header.properties.header, isTrue);
          expect(
            header.properties.liveRegion,
            kind == ProfessionalReferenceStateKind.error ||
                kind == ProfessionalReferenceStateKind.offline,
          );
          expect(
            find.ancestor(
              of: find.byType(ProfessionalReferenceStateIllustration),
              matching: find.byType(ExcludeSemantics),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: find.byType(ProfessionalReferenceStateIllustration),
              matching: find.byType(ExcludeSemantics),
            ),
            findsOneWidget,
          );
          final button = find.byType(ProfessionalReferencePrimaryButton);
          await tester.ensureVisible(button);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(56));
          final label = tester.widget<Text>(
            find.text('غيّر اختيارات البحث لعرض النتائج'),
          );
          expect(label.style!.fontSize, greaterThanOrEqualTo(19));
          expect(label.style!.fontWeight, FontWeight.w700);
          await tester.tap(button);
          await tester.pump();
          final second = find.byType(TextButton);
          await tester.ensureVisible(second);
          expect(tester.getSize(second).height, greaterThanOrEqualTo(48));
          await tester.tap(second);
          await tester.pump();
          await tester.pumpAndSettle();
          expect(primary, 1);
          expect(secondary, 1);
          expect(tester.takeException(), isNull);
          expect(tester.binding.transientCallbackCount, 0);
          handle.dispose();
        },
      );
    }
  }
  testWidgets(
    'inline recovery is live, wraps, retains separate retry/secondary actions',
    (tester) async {
      var retries = 0;
      var exits = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: ProfessionalReferenceInlineStatus(
                message: 'تعذر حفظ البيانات. اختياراتك ما زالت موجودة.',
                retryLabel: 'حاول تاني',
                onRetry: () => retries++,
                secondaryLabel: 'كمّل',
                onSecondary: () => exits++,
              ),
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(ProfessionalReferenceInlineStatus),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.liveRegion == true,
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('حاول تاني'));
      await tester.tap(find.text('كمّل'));
      expect(retries, 1);
      expect(exits, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('reduced-motion loading button exposes static busy status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ProfessionalReferencePrimaryButton(
              label: 'جارٍ الحفظ',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      ),
      findsOneWidget,
    );
    expect(tester.binding.transientCallbackCount, 0);
  });
  for (final reference in [false, true]) {
    testWidgets(
      'specialty picker presentation opt-in $reference preserves catalog selection',
      (tester) async {
        List<String> selected = [];
        await tester.pumpWidget(
          MaterialApp(
            theme: BatshTheme.light(),
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SpecialtyPicker(
                  initialSelection: const [],
                  referenceStyle: reference,
                  onChanged: (v) => selected = v,
                ),
              ),
            ),
          ),
        );
        final paint = find.text('دهانات');
        await tester.ensureVisible(paint);
        await tester.tap(paint);
        await tester.pumpAndSettle();
        expect(selected, ['paint']);
        if (reference) {
          expect(
            tester.widget<Text>(paint).style!.fontSize,
            greaterThanOrEqualTo(16),
          );
          final semantics = find
              .ancestor(
                of: paint,
                matching: find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.button == true,
                ),
              )
              .first;
          expect(tester.getSize(semantics).height, greaterThanOrEqualTo(48));
        }
        await tester.tap(paint);
        await tester.pumpAndSettle();
        expect(selected, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
