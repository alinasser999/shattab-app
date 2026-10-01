import 'dart:async';

import 'package:batsh/core/utils/error_mapper.dart';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/auth/data/auth_repository.dart';
import 'package:batsh/features/auth/domain/profile.dart';
import 'package:batsh/features/auth/presentation/providers/auth_provider.dart';
import 'package:batsh/features/auth/presentation/providers/otp_provider.dart';
import 'package:batsh/features/auth/presentation/sign_in_sheet.dart';
import 'package:batsh/features/onboarding/data/onboarding_repository.dart';
import 'package:batsh/core/widgets/batsh_text_field.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets(
    'ready guest session resumes the original action once despite duplicate gate calls',
    (tester) async {
      final fixture = await _GuestFixture.create();
      var actionCalls = 0;
      await tester.pumpWidget(
        fixture.app(onAction: () => actionCalls++, duplicateGateTap: true),
      );
      await _openGate(tester);
      final l10n = _localizations(tester);
      await _submitPhone(tester, l10n);
      final otpField = tester.widget<BatshTextField>(
        find.byType(BatshTextField),
      );
      expect(otpField.semanticLabel, l10n.otpTitle);
      await _submitCode(tester, l10n);
      await tester.pumpAndSettle();

      expect(fixture.repository.verifyCalls, 1);
      expect(fixture.profile.refreshCalls, 1);
      expect(actionCalls, 1);
      expect(find.text(l10n.signInSheetTitle), findsNothing);
      await fixture.dispose(tester);
    },
  );

  testWidgets('OTP response without session stays in sheet and never resumes', (
    tester,
  ) async {
    final fixture = await _GuestFixture.create();
    fixture.repository.verificationResponse = AuthResponse();
    var actionCalls = 0;
    await tester.pumpWidget(fixture.app(onAction: () => actionCalls++));
    await _openGate(tester);
    final l10n = _localizations(tester);
    await _submitPhone(tester, l10n);
    await _submitCode(tester, l10n);
    await tester.pumpAndSettle();

    expect(fixture.repository.verifyCalls, 1);
    expect(fixture.profile.refreshCalls, 0);
    expect(actionCalls, 0);
    expect(find.text(l10n.signInSheetTitle), findsOneWidget);
    final otpState = fixture.container.read(otpControllerProvider);
    expect(otpState.errorOperation, OtpOperation.verify);
    final error = otpState.errorMessage!;
    expect(error, isNotNull);
    expect(_fieldErrorText(tester), error);
    await fixture.dispose(tester);
  });

  testWidgets('initial OTP send failure remains visible on the phone step', (
    tester,
  ) async {
    final fixture = await _GuestFixture.create();
    fixture.repository.failSendOtpOnCall = 1;
    var actionCalls = 0;
    await tester.pumpWidget(fixture.app(onAction: () => actionCalls++));
    await _openGate(tester);
    final l10n = _localizations(tester);
    await tester.enterText(find.byType(TextFormField).first, '01000000000');
    await tester.tap(find.text(l10n.continueLabel));
    await tester.pumpAndSettle();

    expect(fixture.repository.sendOtpCalls, 1);
    expect(fixture.repository.verifyCalls, 0);
    expect(actionCalls, 0);
    expect(find.text(l10n.signInSheetTitle), findsOneWidget);
    final otpState = fixture.container.read(otpControllerProvider);
    expect(otpState.errorOperation, OtpOperation.send);
    final error = otpState.errorMessage!;
    expect(_fieldErrorText(tester), isNull);
    expect(find.text(error), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(error)).dy,
      greaterThan(tester.getTopLeft(find.text(l10n.continueLabel)).dy),
    );
    await fixture.dispose(tester);
  });

  testWidgets(
    'profile refresh retry keeps pending feedback and does not verify OTP twice',
    (tester) async {
      final profileRefresh = Completer<void>();
      final fixture = await _GuestFixture.create();
      fixture.profile.refreshBehavior = (attempt) async {
        if (attempt == 1) {
          await profileRefresh.future;
        }
        fixture.profile.state = AsyncData(_readyProfile);
      };
      var actionCalls = 0;
      await tester.pumpWidget(fixture.app(onAction: () => actionCalls++));
      await _openGate(tester);
      final l10n = _localizations(tester);
      await _submitPhone(tester, l10n);
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.tap(find.text(l10n.continueLabel));
      await tester.pump();

      final otpTextField = tester.widget<TextField>(
        find.descendant(
          of: find.byType(TextFormField).first,
          matching: find.byType(TextField),
        ),
      );
      otpTextField.onSubmitted?.call('123456');
      await tester.pump();

      expect(fixture.repository.verifyCalls, 1);
      expect(fixture.profile.refreshCalls, 1);
      expect(actionCalls, 0);
      final sheetContinue = find.byType(ElevatedButton).last;
      expect(tester.widget<ElevatedButton>(sheetContinue).onPressed, isNull);

      profileRefresh.complete();
      await tester.pumpAndSettle();
      expect(fixture.repository.verifyCalls, 1);
      expect(fixture.profile.refreshCalls, 1);
      expect(actionCalls, 1);
      await fixture.dispose(tester);
    },
  );

  testWidgets('profile error retry does not consume the OTP again', (
    tester,
  ) async {
    final fixture = await _GuestFixture.create();
    fixture.profile.refreshBehavior = (attempt) async {
      if (attempt == 1) {
        fixture.profile.state = AsyncError(
          StateError('synthetic profile unavailable'),
          StackTrace.current,
        );
      } else {
        fixture.profile.state = AsyncData(_readyProfile);
      }
    };
    var actionCalls = 0;
    await tester.pumpWidget(fixture.app(onAction: () => actionCalls++));
    await _openGate(tester);
    final l10n = _localizations(tester);
    await _submitPhone(tester, l10n);
    await _submitCode(tester, l10n);
    await tester.pumpAndSettle();

    expect(fixture.repository.verifyCalls, 1);
    expect(fixture.profile.refreshCalls, 1);
    expect(actionCalls, 0);
    expect(find.text(l10n.profileError), findsOneWidget);
    await tester.tap(find.text(l10n.tryAgain));
    await tester.pumpAndSettle();

    expect(fixture.repository.verifyCalls, 1);
    expect(fixture.profile.refreshCalls, 2);
    expect(actionCalls, 1);
    await fixture.dispose(tester);
  });

  testWidgets('missing profile stays in the sheet until a retry returns data', (
    tester,
  ) async {
    final fixture = await _GuestFixture.create();
    fixture.profile.refreshBehavior = (attempt) async {
      fixture.profile.state = AsyncData(attempt == 1 ? null : _readyProfile);
    };
    var actionCalls = 0;
    await tester.pumpWidget(fixture.app(onAction: () => actionCalls++));
    await _openGate(tester);
    final l10n = _localizations(tester);
    await _submitPhone(tester, l10n);
    await _submitCode(tester, l10n);
    await tester.pumpAndSettle();

    expect(fixture.repository.verifyCalls, 1);
    expect(fixture.profile.refreshCalls, 1);
    expect(actionCalls, 0);
    expect(find.text(l10n.profileError), findsOneWidget);
    await tester.tap(find.text(l10n.tryAgain));
    await tester.pumpAndSettle();

    expect(fixture.repository.verifyCalls, 1);
    expect(fixture.profile.refreshCalls, 2);
    expect(actionCalls, 1);
    await fixture.dispose(tester);
  });

  testWidgets('failed resend stays visible and does not resume the action', (
    tester,
  ) async {
    final fixture = await _GuestFixture.create();
    fixture.repository.failSendOtpOnCall = 2;
    var actionCalls = 0;
    await tester.pumpWidget(fixture.app(onAction: () => actionCalls++));
    await _openGate(tester);
    final l10n = _localizations(tester);
    await _submitPhone(tester, l10n);
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    await tester.tap(find.text(l10n.resendCode));
    await tester.pumpAndSettle();

    expect(fixture.repository.sendOtpCalls, 2);
    final otpState = fixture.container.read(otpControllerProvider);
    expect(otpState.errorOperation, OtpOperation.resend);
    final error = otpState.errorMessage!;
    expect(_fieldErrorText(tester), isNull);
    expect(find.text(error), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(error)).dy,
      greaterThan(tester.getTopLeft(find.text(l10n.resendCode)).dy),
    );
    expect(find.text(l10n.signInSheetTitle), findsOneWidget);
    expect(actionCalls, 0);
    await fixture.dispose(tester);
  });

  testWidgets('dismissing the compact sheet does not resume the action', (
    tester,
  ) async {
    final fixture = await _GuestFixture.create();
    var actionCalls = 0;
    await tester.pumpWidget(fixture.app(onAction: () => actionCalls++));
    await _openGate(tester);
    final title = find.text(_localizations(tester).signInSheetTitle);
    Navigator.of(tester.element(title)).pop();
    await tester.pumpAndSettle();

    expect(actionCalls, 0);
    expect(fixture.repository.verifyCalls, 0);
    expect(find.text(_localizations(tester).signInSheetTitle), findsNothing);
    await fixture.dispose(tester);
  });

  testWidgets('name save failure remains actionable and blocks the action', (
    tester,
  ) async {
    final fixture = await _GuestFixture.create(
      profile: _readyProfile.copyWith(fullName: ''),
    );
    fixture.onboardingRepository.updateError = StateError(
      'synthetic profile update failure',
    );
    var actionCalls = 0;
    await tester.pumpWidget(fixture.app(onAction: () => actionCalls++));
    await _openGate(tester);
    final l10n = _localizations(tester);
    await _submitPhone(tester, l10n);
    await _submitCode(tester, l10n);
    await tester.pumpAndSettle();
    expect(find.text(l10n.profileNameLabel), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Synthetic Name');
    await tester.tap(find.text(l10n.saveProfile));
    await tester.pumpAndSettle();
    expect(fixture.onboardingRepository.updateCalls, 1);
    expect(_fieldErrorText(tester), l10n.unknownErrorRetry);
    expect(actionCalls, 0);
    expect(find.text(l10n.signInSheetTitle), findsOneWidget);
    await fixture.dispose(tester);
  });

  testWidgets('confirmed name save completes profile before resuming once', (
    tester,
  ) async {
    final fixture = await _GuestFixture.create(
      profile: _readyProfile.copyWith(fullName: ''),
    );
    var actionCalls = 0;
    await tester.pumpWidget(fixture.app(onAction: () => actionCalls++));
    await _openGate(tester);
    final l10n = _localizations(tester);
    await _submitPhone(tester, l10n);
    await _submitCode(tester, l10n);
    await tester.pumpAndSettle();

    expect(find.text(l10n.whatsYourName), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Synthetic Name');
    await tester.tap(find.text(l10n.saveProfile));
    await tester.pumpAndSettle();

    expect(fixture.repository.verifyCalls, 1);
    expect(fixture.onboardingRepository.updateCalls, 1);
    expect(fixture.profile.refreshCalls, 2);
    expect(fixture.profile.profile?.fullName, 'Synthetic Name');
    expect(actionCalls, 1);
    expect(find.text(l10n.signInSheetTitle), findsNothing);
    await fixture.dispose(tester);
  });
}

Future<void> _openGate(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('gated-action-trigger')));
  await tester.pumpAndSettle();
  expect(find.text(_localizations(tester).signInSheetTitle), findsOneWidget);
}

Future<void> _submitPhone(WidgetTester tester, AppLocalizations l10n) async {
  await tester.enterText(find.byType(TextFormField).first, '01000000000');
  await tester.tap(find.text(l10n.continueLabel));
  await tester.pumpAndSettle();
}

Future<void> _submitCode(WidgetTester tester, AppLocalizations l10n) async {
  await tester.enterText(find.byType(TextFormField).first, '123456');
  await tester.tap(find.text(l10n.continueLabel));
  await tester.pumpAndSettle();
}

AppLocalizations _localizations(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.text('Start gated action')))!;

String? _fieldErrorText(WidgetTester tester) {
  final decorator = find.descendant(
    of: find.byType(TextFormField).first,
    matching: find.byType(InputDecorator),
  );
  expect(decorator, findsOneWidget);
  return tester.widget<InputDecorator>(decorator).decoration.errorText;
}

class _GuestFixture {
  _GuestFixture({
    required this.container,
    required this.repository,
    required this.profile,
    required this.onboardingRepository,
    required this.session,
  });

  final ProviderContainer container;
  final _GuestAuthRepository repository;
  final _CurrentProfileFixture profile;
  final _OnboardingRepositoryFixture onboardingRepository;
  final _SessionFixture session;

  static Future<_GuestFixture> create({Profile? profile}) async {
    final session = _SessionFixture();
    final repository = _GuestAuthRepository();
    final profileFixture = _CurrentProfileFixture(profile ?? _readyProfile);
    final onboardingRepository = _OnboardingRepositoryFixture();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        currentSessionProvider.overrideWith((ref) => session.value),
        currentProfileProvider.overrideWith(() => profileFixture),
        onboardingRepositoryProvider.overrideWithValue(onboardingRepository),
      ],
    );
    repository.onSessionEstablished = () {
      session.value = _syntheticSession;
      container.invalidate(currentSessionProvider);
    };
    onboardingRepository.onNameSaved = (name) {
      profileFixture.profile = profileFixture.profile?.copyWith(fullName: name);
    };
    return _GuestFixture(
      container: container,
      repository: repository,
      profile: profileFixture,
      onboardingRepository: onboardingRepository,
      session: session,
    );
  }

  Widget app({required VoidCallback onAction, bool duplicateGateTap = false}) =>
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: BatshTheme.light(),
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const ValueKey('gated-action-trigger'),
                  onPressed: () {
                    unawaited(
                      runSignedIn(
                        context,
                        ref,
                        reason: 'Save this synthetic item',
                        action: onAction,
                      ),
                    );
                    if (duplicateGateTap) {
                      unawaited(
                        runSignedIn(
                          context,
                          ref,
                          reason: 'Save this synthetic item',
                          action: onAction,
                        ),
                      );
                    }
                  },
                  child: const Text('Start gated action'),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  }
}

class _SessionFixture {
  Session? value;
}

class _GuestAuthRepository extends AuthRepository {
  _GuestAuthRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'synthetic-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  int sendOtpCalls = 0;
  int verifyCalls = 0;
  int? failSendOtpOnCall;
  AuthResponse verificationResponse = AuthResponse(session: _syntheticSession);
  void Function()? onSessionEstablished;

  @override
  Future<void> sendOtp(String phone) async {
    sendOtpCalls++;
    if (sendOtpCalls == failSendOtpOnCall) {
      throw Exception('SMS delivery failed');
    }
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String code,
  }) async {
    verifyCalls++;
    if (verificationResponse.session != null) onSessionEstablished?.call();
    return verificationResponse;
  }
}

class _CurrentProfileFixture extends CurrentProfile {
  _CurrentProfileFixture(this.profile);

  Profile? profile;
  int refreshCalls = 0;
  Future<void> Function(int attempt)? refreshBehavior;
  final Completer<Profile?> _initialBuild = Completer<Profile?>();

  @override
  Future<Profile?> build() => _initialBuild.future;

  @override
  Future<void> refresh() async {
    refreshCalls++;
    final behavior = refreshBehavior;
    if (behavior != null) {
      await behavior(refreshCalls);
      return;
    }
    state = AsyncData(profile);
  }
}

class _OnboardingRepositoryFixture extends OnboardingRepository {
  _OnboardingRepositoryFixture()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'synthetic-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  int updateCalls = 0;
  Object? updateError;
  void Function(String name)? onNameSaved;

  @override
  Future<void> updateFullName({
    required String profileId,
    required String fullName,
  }) async {
    updateCalls++;
    final error = updateError;
    if (error != null) throw error;
    onNameSaved?.call(fullName);
  }
}

final _readyProfile = Profile(
  id: 'synthetic-user-id',
  role: UserRole.homeowner,
  fullName: 'Synthetic User',
  phone: '+201000000000',
  onboardingComplete: true,
);

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
