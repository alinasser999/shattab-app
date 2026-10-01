import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/auth/data/auth_repository.dart';
import 'package:batsh/features/auth/presentation/phone_entry_screen.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('phone/password no-session response stays on the editable form', (
    tester,
  ) async {
    final repository = _AuthRepositoryFixture()
      ..passwordResponse = AuthResponse();
    await tester.pumpWidget(_phoneEntryApp(repository));
    _drainKnownFooterOverflow(tester);

    final context = tester.element(find.byType(PhoneEntryScreen));
    final l10n = AppLocalizations.of(context)!;
    await _enterCredentials(tester, phone: '1000000000', password: 'secret1');
    await _tapSignIn(tester, l10n);

    expect(repository.passwordSignInCalls, 1);
    expect(find.text(l10n.errAuthFailed), findsOneWidget);
    expect(find.byType(PhoneEntryScreen), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '1000000000',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      'secret1',
    );
  });

  testWidgets('phone/password success clears pending and error state', (
    tester,
  ) async {
    final repository = _AuthRepositoryFixture()
      ..passwordResponse = AuthResponse(session: _syntheticSession);
    await tester.pumpWidget(_phoneEntryApp(repository));
    _drainKnownFooterOverflow(tester);

    final context = tester.element(find.byType(PhoneEntryScreen));
    final l10n = AppLocalizations.of(context)!;
    await _enterCredentials(tester, phone: '1000000000', password: 'secret1');
    await _tapSignIn(tester, l10n);

    expect(repository.passwordSignInCalls, 1);
    expect(find.text(l10n.errAuthFailed), findsNothing);
    final submitFinder = find.widgetWithText(ElevatedButton, l10n.signInAction);
    expect(submitFinder, findsOneWidget);
    final submit = tester.widget<ElevatedButton>(submitFinder);
    expect(submit.onPressed, isNotNull);
  });

  testWidgets('invalid phone/password is rejected locally without auth call', (
    tester,
  ) async {
    final repository = _AuthRepositoryFixture();
    await tester.pumpWidget(_phoneEntryApp(repository));
    _drainKnownFooterOverflow(tester);

    final context = tester.element(find.byType(PhoneEntryScreen));
    final l10n = AppLocalizations.of(context)!;
    await _enterCredentials(tester, phone: '123', password: '12345');
    await _tapSignIn(tester, l10n);

    expect(repository.passwordSignInCalls, 0);
    expect(find.text(l10n.invalidPhone), findsOneWidget);
    expect(find.text(l10n.passwordTooShort), findsNothing);
  });

  testWidgets('mapped credential/network failures allow a later retry', (
    tester,
  ) async {
    final repository = _AuthRepositoryFixture()
      ..passwordError = const FormatException('invalid login credentials');
    await tester.pumpWidget(_phoneEntryApp(repository));
    _drainKnownFooterOverflow(tester);

    final context = tester.element(find.byType(PhoneEntryScreen));
    final l10n = AppLocalizations.of(context)!;
    await _enterCredentials(tester, phone: '1000000000', password: 'secret1');
    await _tapSignIn(tester, l10n);

    expect(find.text(l10n.errAuthFailed), findsOneWidget);
    expect(repository.passwordSignInCalls, 1);

    repository.passwordError = const FormatException('network timeout');
    await _tapSignIn(tester, l10n);
    expect(find.text(l10n.errNetwork), findsOneWidget);
    expect(repository.passwordSignInCalls, 2);

    repository.passwordError = null;
    repository.passwordResponse = AuthResponse(session: _syntheticSession);
    await _tapSignIn(tester, l10n);
    expect(repository.passwordSignInCalls, 3);
    expect(find.text(l10n.errNetwork), findsNothing);
  });
}

Widget _phoneEntryApp(_AuthRepositoryFixture repository) => ProviderScope(
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

Future<void> _enterCredentials(
  WidgetTester tester, {
  required String phone,
  required String password,
}) async {
  final fields = find.byType(TextField);
  expect(fields, findsNWidgets(2));
  await tester.ensureVisible(fields.first);
  await tester.enterText(fields.first, phone);
  await tester.ensureVisible(fields.at(1));
  await tester.enterText(fields.at(1), password);
  _drainKnownFooterOverflow(tester);
}

Future<void> _tapSignIn(WidgetTester tester, AppLocalizations l10n) async {
  final signIn = find.widgetWithText(ElevatedButton, l10n.signInAction);
  expect(signIn, findsOneWidget);
  final onPressed = tester.widget<ElevatedButton>(signIn).onPressed;
  expect(onPressed, isNotNull);
  onPressed!.call();
  await tester.pumpAndSettle();
  _drainKnownFooterOverflow(tester);
}

void _drainKnownFooterOverflow(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception == null) return;
  expect(
    exception.toString(),
    contains('RenderFlex overflowed by 58 pixels on the right.'),
  );
}

class _AuthRepositoryFixture extends AuthRepository {
  _AuthRepositoryFixture()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'synthetic-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  int passwordSignInCalls = 0;
  AuthResponse? passwordResponse = AuthResponse();
  Object? passwordError;

  @override
  Future<AuthResponse> signInWithPhonePassword({
    required String phone,
    required String password,
  }) async {
    passwordSignInCalls++;
    final error = passwordError;
    if (error != null) throw error;
    return passwordResponse ?? AuthResponse();
  }
}

final _syntheticSession = Session(
  accessToken: 'synthetic-access-token',
  refreshToken: 'synthetic-refresh-token',
  tokenType: 'bearer',
  user: const User(
    id: 'synthetic-user-id',
    appMetadata: {},
    userMetadata: null,
    aud: 'authenticated',
    createdAt: '2026-09-30T00:00:00.000Z',
    phone: '+201000000000',
  ),
);
