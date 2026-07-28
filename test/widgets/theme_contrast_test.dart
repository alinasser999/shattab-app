import 'package:batsh/core/theme/batsh_theme.dart';
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

/// Every text slot, by the name it is read by.
Map<String, TextStyle?> _slots(TextTheme t) => {
  'displayLarge': t.displayLarge,
  'displayMedium': t.displayMedium,
  'displaySmall': t.displaySmall,
  'headlineLarge': t.headlineLarge,
  'headlineMedium': t.headlineMedium,
  'headlineSmall': t.headlineSmall,
  'titleLarge': t.titleLarge,
  'titleMedium': t.titleMedium,
  'titleSmall': t.titleSmall,
  'bodyLarge': t.bodyLarge,
  'bodyMedium': t.bodyMedium,
  'bodySmall': t.bodySmall,
  'labelLarge': t.labelLarge,
  'labelMedium': t.labelMedium,
  'labelSmall': t.labelSmall,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('theme text contrast', () {
    // The bug this pins: BatshTypography baked the light theme's ink into
    // every style, and that ink (0xFF1F1B14) is byte-identical to the dark
    // scheme's surface. Dark mode painted text on its own colour — 1.0:1,
    // perfectly invisible, on all fifteen slots at once. Nothing failed,
    // because nothing looked.
    for (final (name, build) in <(String, ThemeData Function())>[
      ('light', BatshTheme.light),
      ('dark', BatshTheme.dark),
    ]) {
      test('$name: every text slot is legible on its own surface', () {
        final theme = build();
        final surface = theme.colorScheme.surface;
        _slots(theme.textTheme).forEach((slot, style) {
          expect(style, isNotNull, reason: '$slot is missing');
          final color = style!.color;
          expect(color, isNotNull, reason: '$slot resolved to no colour');

          final ratio = _contrast(color!, surface);
          // 4.5:1 is the AA floor for body text. Display sizes could pass at
          // 3:1, but holding one bar keeps the assertion honest and every
          // slot clears it comfortably.
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$name/$slot: ${ratio.toStringAsFixed(2)}:1 against surface',
          );
        });
      });
    }

    test('the two themes do not share an ink', () {
      final light = BatshTheme.light().textTheme.bodyMedium!.color;
      final dark = BatshTheme.dark().textTheme.bodyMedium!.color;
      expect(light, isNot(dark));
    });
  });

  group('Arabic type metrics', () {
    // Arabic is a connected script. Negative tracking pulls the joins into the
    // letterforms, and the deep descenders plus above-baseline marks need more
    // leading than a Latin-calibrated ratio gives them.
    test('no style tightens the advance', () {
      _slots(BatshTheme.light().textTheme).forEach((slot, style) {
        final spacing = style!.letterSpacing;
        if (spacing != null) {
          expect(
            spacing,
            greaterThanOrEqualTo(0.0),
            reason: '$slot tracks at $spacing',
          );
        }
      });
    });

    test('display and headline leading clears 1.40', () {
      final textTheme = BatshTheme.light().textTheme;
      for (final slot in [
        'displayLarge',
        'displayMedium',
        'displaySmall',
        'headlineLarge',
        'headlineMedium',
        'headlineSmall',
      ]) {
        final style = _slots(textTheme)[slot]!;
        expect(
          style.height,
          greaterThanOrEqualTo(1.40),
          reason: '$slot leads at ${style.height}',
        );
      }
    });
  });
}
