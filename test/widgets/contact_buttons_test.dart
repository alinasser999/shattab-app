import 'package:batsh/l10n/app_localizations.dart';
import 'package:batsh/core/l10n/strings.dart';
import 'package:batsh/core/widgets/contact_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes Egyptian phone numbers for WhatsApp', () {
    expect(whatsappPhoneDigits('010 0123 4567'), '201001234567');
    expect(whatsappPhoneDigits('+20 10 0123 4567'), '201001234567');
    expect(whatsappPhoneDigits('0020 10 0123 4567'), '201001234567');
    expect(whatsappPhoneDigits(''), isEmpty);
  });

  group('WhatsAppButton', () {
    testWidgets('renders WhatsApp label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          home: Scaffold(body: WhatsAppButton(phone: '+201001234567')),
        ),
      );

      // Visible label is the short form; the full sentence is what a screen
      // reader announces. Both are asserted so the terse label can never drift
      // into being terse for assistive tech too.
      expect(find.text(S.whatsappShort), findsOneWidget);
      expect(find.bySemanticsLabel(S.contactViaWhatsApp), findsOneWidget);
    });

    testWidgets('renders with empty phone without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          home: Scaffold(body: WhatsAppButton(phone: '')),
        ),
      );

      // Visible label is the short form; the full sentence is what a screen
      // reader announces. Both are asserted so the terse label can never drift
      // into being terse for assistive tech too.
      expect(find.text(S.whatsappShort), findsOneWidget);
      expect(find.bySemanticsLabel(S.contactViaWhatsApp), findsOneWidget);
    });
  });

  group('CallButton', () {
    testWidgets('renders call label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          home: Scaffold(body: CallButton(phone: '+201001234567')),
        ),
      );

      expect(find.text(S.call), findsOneWidget);
    });

    testWidgets('renders with empty phone without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          home: Scaffold(body: CallButton(phone: '')),
        ),
      );

      expect(find.text(S.call), findsOneWidget);
    });
  });

  group('PhoneInline', () {
    testWidgets('renders phone label and number', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          home: Scaffold(body: PhoneInline(phone: '+201001234567')),
        ),
      );

      expect(find.textContaining(S.phone), findsOneWidget);
      expect(find.textContaining('+201001234567'), findsOneWidget);
    });
  });
}
