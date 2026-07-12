import 'package:batsh/core/l10n/strings.dart';
import 'package:batsh/core/widgets/contact_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsAppButton', () {
    testWidgets('renders WhatsApp label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WhatsAppButton(phone: '+201001234567'),
          ),
        ),
      );

      expect(find.text(S.contactViaWhatsApp), findsOneWidget);
    });

    testWidgets('renders with empty phone without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WhatsAppButton(phone: ''),
          ),
        ),
      );

      expect(find.text(S.contactViaWhatsApp), findsOneWidget);
    });
  });

  group('CallButton', () {
    testWidgets('renders call label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallButton(phone: '+201001234567'),
          ),
        ),
      );

      expect(find.text(S.call), findsOneWidget);
    });

    testWidgets('renders with empty phone without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallButton(phone: ''),
          ),
        ),
      );

      expect(find.text(S.call), findsOneWidget);
    });
  });

  group('PhoneInline', () {
    testWidgets('renders phone label and number', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneInline(phone: '+201001234567'),
          ),
        ),
      );

      expect(find.textContaining(S.phone), findsOneWidget);
      expect(find.textContaining('+201001234567'), findsOneWidget);
    });
  });
}
