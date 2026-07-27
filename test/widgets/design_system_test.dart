import 'package:batsh/core/theme/batsh_border_width.dart';
import 'package:batsh/core/theme/batsh_icon_size.dart';
import 'package:batsh/core/theme/batsh_shadows.dart';
import 'package:batsh/core/widgets/batsh_badge.dart';
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
        expect(scale[i], greaterThan(scale[i - 1]),
            reason: 'rung $i must be larger than rung ${i - 1}');
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
      expect(error, greaterThan(BatshSnack.durationFor(BatshSnackKind.success)));
      expect(error, greaterThan(BatshSnack.durationFor(BatshSnackKind.info)));
    });
  });

  group('BatshBadge', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BatshBadge(label: 'مفتوح')),
      ));
      expect(find.text('مفتوح'), findsOneWidget);
    });

    testWidgets('renders a leading icon only when given one', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BatshBadge(label: '4.8')),
      ));
      expect(find.byType(Icon), findsNothing);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: BatshBadge(label: '4.8', icon: Icons.star_rounded),
        ),
      ));
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('announces semanticLabel over a meaningless label',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: BatshBadge(label: '12', semanticLabel: '12 عرض سعر'),
        ),
      ));
      expect(find.bySemanticsLabel('12 عرض سعر'), findsOneWidget);
    });

    testWidgets('is not a button in the semantics tree', (tester) async {
      // A badge that announces as tappable teaches the user to tap something
      // that does nothing. This is the line between BatshBadge and BatshChip.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BatshBadge(label: 'ملغي')),
      ));
      final node = tester.getSemantics(find.bySemanticsLabel('ملغي'));
      expect(node.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    test('every tone and emphasis pairing clears 4.5:1 contrast', () {
      // Badge text sits at labelMd (13) and labelSm (11). Both are below the
      // WCAG large-text threshold, so the full 4.5:1 applies to all of them.
      for (final tone in BatshBadgeTone.values) {
        for (final emphasis in BatshBadgeEmphasis.values) {
          final (foreground, background, _) =
              BatshBadge(label: 'x', tone: tone, emphasis: emphasis)
                  .debugPalette;
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
