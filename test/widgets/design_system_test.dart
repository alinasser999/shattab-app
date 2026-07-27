import 'package:batsh/core/theme/batsh_border_width.dart';
import 'package:batsh/core/theme/batsh_icon_size.dart';
import 'package:batsh/core/theme/batsh_shadows.dart';
import 'package:batsh/core/widgets/batsh_badge.dart';
import 'package:batsh/core/widgets/batsh_dialog.dart';
import 'package:batsh/core/widgets/batsh_empty_state.dart';
import 'package:batsh/core/widgets/batsh_sheet.dart';
import 'package:batsh/core/widgets/batsh_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('BatshIconSize', () {
    test('scale ascends with no duplicate rungs', () {
      const scale = [
        BatshIconSize.xs,
        BatshIconSize.sm,
        BatshIconSize.md,
        BatshIconSize.lg,
        BatshIconSize.xl,
        BatshIconSize.xxl,
      ];
      for (var i = 1; i < scale.length; i++) {
        expect(
          scale[i],
          greaterThan(scale[i - 1]),
          reason: 'rung $i must be larger than rung ${i - 1}',
        );
      }
      expect(scale.toSet().length, scale.length);
    });

    test('semantic aliases resolve onto the scale', () {
      expect(BatshIconSize.inline, BatshIconSize.sm);
      expect(BatshIconSize.action, BatshIconSize.md);
      expect(BatshIconSize.nav, BatshIconSize.lg);
      expect(BatshIconSize.empty, BatshIconSize.xxl);
    });
  });

  group('BatshBorderWidth', () {
    test('strokes ascend and focusRing matches strong', () {
      expect(BatshBorderWidth.selected, greaterThan(BatshBorderWidth.hairline));
      expect(BatshBorderWidth.strong, greaterThan(BatshBorderWidth.selected));
      expect(BatshBorderWidth.focusRing, BatshBorderWidth.strong);
    });
  });

  group('BatshShadows.level', () {
    test('level 0 is no shadow, every level above it casts one', () {
      expect(BatshShadows.level(0), isEmpty);
      for (var l = 1; l <= 5; l++) {
        expect(BatshShadows.level(l), isNotEmpty, reason: 'level $l');
      }
    });

    test('out-of-range levels clamp instead of throwing', () {
      expect(BatshShadows.level(-3), BatshShadows.level(0));
      expect(BatshShadows.level(99), BatshShadows.level(5));
    });
  });

  group('BatshSnack', () {
    test('errors are held longer than success and info', () {
      final error = BatshSnack.durationFor(BatshSnackKind.error);
      expect(
        error,
        greaterThan(BatshSnack.durationFor(BatshSnackKind.success)),
      );
      expect(error, greaterThan(BatshSnack.durationFor(BatshSnackKind.info)));
    });
  });

  group('BatshBadge', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BatshBadge(label: 'مفتوح')),
        ),
      );
      expect(find.text('مفتوح'), findsOneWidget);
    });

    testWidgets('renders a leading icon only when given one', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BatshBadge(label: '4.8')),
        ),
      );
      expect(find.byType(Icon), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatshBadge(label: '4.8', icon: Icons.star_rounded),
          ),
        ),
      );
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('announces semanticLabel over a meaningless label', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatshBadge(label: '12', semanticLabel: '12 عرض سعر'),
          ),
        ),
      );
      expect(find.bySemanticsLabel('12 عرض سعر'), findsOneWidget);
    });

    testWidgets('is not a button in the semantics tree', (tester) async {
      // A badge that announces as tappable teaches the user to tap something
      // that does nothing. This is the line between BatshBadge and BatshChip.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BatshBadge(label: 'ملغي')),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('ملغي'));
      expect(node.flagsCollection.isButton, isFalse);
      handle.dispose();
    });
  });

  group('BatshDialog', () {
    testWidgets('confirm returns true when the confirm action is tapped', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await BatshDialog.confirm(
                    context,
                    title: 'عنوان',
                    message: 'رسالة',
                    confirmLabel: 'تأكيد',
                    isDestructive: true,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('confirm returns false when cancelled', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await BatshDialog.confirm(
                    context,
                    title: 'عنوان',
                    message: 'رسالة',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('info dismisses on its single action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    BatshDialog.info(context, title: 'عنوان', message: 'رسالة'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('رسالة'), findsOneWidget);
      await tester.tap(find.text('حسنًا'));
      await tester.pumpAndSettle();
      expect(find.text('رسالة'), findsNothing);
    });
  });

  group('BatshEmptyState', () {
    testWidgets('shows the message alongside the title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatshEmptyState(title: 'مفيش حاجة', message: 'ابدأ من هنا'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('مفيش حاجة'), findsOneWidget);
      expect(find.text('ابدأ من هنا'), findsOneWidget);
    });

    testWidgets('announces title and message as one label', (tester) async {
      // Two separate announcements make a screen reader read the headline and
      // then stop, which is the half that carries no instruction.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatshEmptyState(title: 'مفيش حاجة', message: 'ابدأ من هنا'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('مفيش حاجة ابدأ من هنا'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('noResults drops the brand tint that invites creation', (
      tester,
    ) async {
      // nothingYet is an invitation and takes brand colour; noResults is a
      // dead end the user made with a filter, so colouring it would read as a
      // warning about something that is not wrong.
      Color medallionOf(WidgetTester t) {
        final container = t.widget<Container>(
          find
              .descendant(
                of: find.byType(BatshEmptyState),
                matching: find.byType(Container),
              )
              .first,
        );
        return ((container.decoration! as BoxDecoration).color)!;
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatshEmptyState(title: 't', message: 'm'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final nothingYet = medallionOf(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatshEmptyState(
              title: 't',
              message: 'm',
              kind: BatshEmptyStateKind.noResults,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(medallionOf(tester), isNot(nothingYet));
    });
  });

  group('BatshSheet', () {
    testWidgets('shows its content above the drag handle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => BatshSheet.show<void>(
                  context,
                  builder: (_) => const Text('sheet content'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('sheet content'), findsOneWidget);
    });

    testWidgets('returns the popped value to the caller', (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await BatshSheet.show<String>(
                    context,
                    builder: (ctx) => TextButton(
                      onPressed: () => Navigator.of(ctx).pop('done'),
                      child: const Text('close'),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('close'));
      await tester.pumpAndSettle();
      expect(result, 'done');
    });
  });

  group('BatshBadge', () {
    test('every tone and emphasis pairing clears 4.5:1 contrast', () {
      // Badge text sits at labelMd (13) and labelSm (11). Both are below the
      // WCAG large-text threshold, so the full 4.5:1 applies to all of them.
      for (final tone in BatshBadgeTone.values) {
        for (final emphasis in BatshBadgeEmphasis.values) {
          final (foreground, background, _) = BatshBadge(
            label: 'x',
            tone: tone,
            emphasis: emphasis,
          ).debugPalette;
          // Outline has no fill, so its text sits on whatever surface the badge
          // was placed over. The app background is the realistic worst case.
          final behind = emphasis == BatshBadgeEmphasis.outline
              ? const Color(0xFFFFF8F3)
              : background;
          expect(
            _contrast(foreground, behind),
            greaterThanOrEqualTo(4.5),
            reason: '$tone / $emphasis fails contrast',
          );
        }
      }
    });
  });
}
