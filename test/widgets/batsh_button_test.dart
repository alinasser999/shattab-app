import 'package:batsh/core/widgets/batsh_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatshButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatshButton(
              label: 'احفظ',
              onPressed: () {},
              hapticOnPress: false,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('احفظ'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatshButton(
              label: 'احفظ',
              onPressed: () {},
              isLoading: true,
              hapticOnPress: false,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('احفظ'), findsNothing);
    });

    testWidgets('fires onPressed when enabled', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatshButton(
              label: 'اضغط',
              onPressed: () => pressed = true,
              hapticOnPress: false,
              animate: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('اضغط'));
      expect(pressed, isTrue);
    });

    testWidgets('does not fire onPressed when loading', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatshButton(
              label: 'اضغط',
              onPressed: () => pressed = true,
              isLoading: true,
              hapticOnPress: false,
              animate: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CircularProgressIndicator));
      expect(pressed, isFalse);
    });

    testWidgets('does not fire onPressed when onPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatshButton(
              label: 'معطل',
              onPressed: null,
              hapticOnPress: false,
              animate: false,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('renders with fullWidth by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatshButton(
              label: 'عرض كامل',
              onPressed: () {},
              hapticOnPress: false,
              animate: false,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == double.infinity,
        ),
      );
      expect(sizedBox, isNotNull);
    });

    testWidgets('renders secondary style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatshButton(
              label: 'ثانوي',
              onPressed: () {},
              style: BatshButtonStyle.secondary,
              hapticOnPress: false,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('renders ghost style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatshButton(
              label: 'نصي',
              onPressed: () {},
              style: BatshButtonStyle.ghost,
              hapticOnPress: false,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
