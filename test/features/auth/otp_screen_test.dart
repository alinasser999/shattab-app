import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/utils/error_mapper.dart';
import 'package:batsh/core/widgets/batsh_text_field.dart';
import 'package:batsh/features/auth/presentation/otp_screen.dart';
import 'package:batsh/features/auth/presentation/providers/otp_provider.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'zero cooldown shows resend label but stays disabled during verification',
    (tester) async {
      await tester.pumpWidget(
        _otpScreenApp(const OtpState(isVerifying: true, cooldownSeconds: 0)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      });

      final context = tester.element(find.byType(OtpScreen));
      final l10n = AppLocalizations.of(context)!;
      final resend = find.widgetWithText(TextButton, l10n.resendCode);
      expect(resend, findsOneWidget);
      expect(tester.widget<TextButton>(resend).onPressed, isNull);
    },
  );

  testWidgets('positive cooldown displays the countdown and stays disabled', (
    tester,
  ) async {
    const seconds = 17;
    await tester.pumpWidget(
      _otpScreenApp(const OtpState(cooldownSeconds: seconds)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    final context = tester.element(find.byType(OtpScreen));
    final l10n = AppLocalizations.of(context)!;
    final countdown = l10n.resendInSeconds.replaceAll('%s', '$seconds');
    final resend = find.widgetWithText(TextButton, countdown);
    expect(resend, findsOneWidget);
    expect(tester.widget<TextButton>(resend).onPressed, isNull);
  });

  testWidgets('verify feedback belongs to the labeled code field', (
    tester,
  ) async {
    const error = 'Verification failed';
    await tester.pumpWidget(
      _otpScreenApp(
        const OtpState(
          errorMessage: error,
          errorOperation: OtpOperation.verify,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final context = tester.element(find.byType(OtpScreen));
    final l10n = AppLocalizations.of(context)!;
    final codeField = tester.widget<BatshTextField>(
      find.byType(BatshTextField),
    );
    expect(codeField.semanticLabel, l10n.otpTitle);
    expect(_fieldErrorText(tester), error);
    expect(find.text(error), findsOneWidget);
  });

  testWidgets('resend feedback stays by resend and out of the code field', (
    tester,
  ) async {
    const error = 'Please try sending again';
    await tester.pumpWidget(
      _otpScreenApp(
        const OtpState(
          errorMessage: error,
          errorOperation: OtpOperation.resend,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final context = tester.element(find.byType(OtpScreen));
    final l10n = AppLocalizations.of(context)!;
    final resend = find.widgetWithText(TextButton, l10n.resendCode);
    expect(resend, findsOneWidget);
    expect(_fieldErrorText(tester), isNull);
    expect(find.text(error), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(error)).dy,
      greaterThan(tester.getTopLeft(resend).dy),
    );
  });
}

String? _fieldErrorText(WidgetTester tester) {
  final decorator = find.descendant(
    of: find.byType(TextFormField),
    matching: find.byType(InputDecorator),
  );
  expect(decorator, findsOneWidget);
  return tester.widget<InputDecorator>(decorator).decoration.errorText;
}

Widget _otpScreenApp(OtpState initialState) => ProviderScope(
  overrides: [otpControllerProvider.overrideWithValue(initialState)],
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: BatshTheme.light(),
    home: TickerMode(
      enabled: false,
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: const OtpScreen(),
      ),
    ),
  ),
);
