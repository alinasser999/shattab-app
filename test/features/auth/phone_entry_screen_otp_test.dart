import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/auth/data/auth_repository.dart';
import 'package:batsh/features/auth/presentation/phone_entry_screen.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets(
    'recovery SMS failure stays off phone validation and allows retry',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = _OtpFailureRepository();
      await tester.pumpWidget(_phoneEntryApp(repository));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PhoneEntryScreen));
      final l10n = AppLocalizations.of(context)!;
      final phoneField = find.byType(TextField).first;
      await tester.enterText(phoneField, '1000000000');

      final forgotPassword = find.widgetWithText(
        TextButton,
        l10n.forgotPassword,
      );
      await tester.ensureVisible(forgotPassword);
      await tester.tap(forgotPassword);
      await tester.pumpAndSettle();

      expect(repository.sendOtpCalls, 1);
      expect(repository.lastPhone, '+201000000000');
      expect(find.byType(PhoneEntryScreen), findsOneWidget);
      expect(find.text(l10n.unknownErrorRetry), findsOneWidget);
      expect(find.text(l10n.invalidPhone), findsNothing);
      expect(find.text(l10n.errOtpFailed), findsNothing);
      expect(
        tester.widget<TextField>(phoneField).decoration?.errorText,
        isNull,
      );

      await tester.tap(forgotPassword);
      await tester.pumpAndSettle();

      expect(repository.sendOtpCalls, 2);
      expect(repository.lastPhone, '+201000000000');
      expect(find.text(l10n.unknownErrorRetry), findsOneWidget);
      expect(find.text(l10n.invalidPhone), findsNothing);
    },
  );
}

Widget _phoneEntryApp(_OtpFailureRepository repository) => ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: BatshTheme.light(),
    home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: const PhoneEntryScreen(),
    ),
  ),
);

class _OtpFailureRepository extends AuthRepository {
  _OtpFailureRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'synthetic-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  int sendOtpCalls = 0;
  String? lastPhone;

  @override
  Future<void> sendOtp(String phone) async {
    sendOtpCalls++;
    lastPhone = phone;
    throw const FormatException('sms_send_failed');
  }
}
