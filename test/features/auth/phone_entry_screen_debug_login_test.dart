import 'dart:async';

import 'package:batsh/core/debug/debug_flags.dart';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/widgets/batsh_button.dart';
import 'package:batsh/features/auth/data/auth_repository.dart';
import 'package:batsh/features/auth/domain/profile.dart';
import 'package:batsh/features/auth/presentation/phone_entry_screen.dart';
import 'package:batsh/features/auth/presentation/providers/auth_provider.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('debug login is localized and starts with empty account fields', (
    tester,
  ) async {
    _setViewport(tester);
    final repository = _FakeAuthRepository();
    final profile = _CurrentProfileFixture(_profile(UserRole.homeowner));
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        currentProfileProvider.overrideWith(() => profile),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      _resetViewport(tester);
    });

    await tester.pumpWidget(_loginApp(container, const Locale('ar')));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(PhoneEntryScreen)),
    )!;
    expect(DebugFlags.loginVisible, isTrue);
    expect(find.text(l10n.debugLoginTitle), findsOneWidget);
    expect(find.text(l10n.demoLoginHomeowner), findsOneWidget);
    expect(find.text(l10n.demoLoginContractor), findsOneWidget);

    final homeownerButton = _accountButton(l10n.demoLoginHomeowner);
    await tester.ensureVisible(homeownerButton);
    await tester.tap(homeownerButton);
    await tester.pumpAndSettle();
    expect(_debugField(tester, l10n.debugLoginEmailLabel), findsOneWidget);
    expect(_debugField(tester, l10n.debugLoginPasswordLabel), findsOneWidget);
    expect(
      tester
          .widget<TextField>(_debugField(tester, l10n.debugLoginEmailLabel))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextField>(_debugField(tester, l10n.debugLoginPasswordLabel))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextField>(_debugField(tester, l10n.debugLoginPasswordLabel))
          .obscureText,
      isTrue,
    );

    await tester.enterText(
      _debugField(tester, l10n.debugLoginEmailLabel),
      'synthetic@example.invalid',
    );
    await tester.enterText(
      _debugField(tester, l10n.debugLoginPasswordLabel),
      'synthetic-password',
    );
    final cancelButton = find.text(l10n.debugLoginCancel);
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
    final contractorButton = _accountButton(l10n.demoLoginContractor);
    await tester.ensureVisible(contractorButton);
    await tester.tap(contractorButton);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(_debugField(tester, l10n.debugLoginEmailLabel))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextField>(_debugField(tester, l10n.debugLoginPasswordLabel))
          .controller!
          .text,
      isEmpty,
    );
    expect(repository.signInCalls, isEmpty);
  });

  testWidgets(
    'submission clears credentials, locks both paths, and calls auth repository',
    (tester) async {
      _setViewport(tester);
      final repository = _FakeAuthRepository();
      final response = Completer<AuthResponse>();
      repository.response = response.future;
      final profile = _CurrentProfileFixture(_profile(UserRole.homeowner));
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          currentProfileProvider.overrideWith(() => profile),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        _resetViewport(tester);
      });

      await tester.pumpWidget(_loginApp(container, const Locale('en')));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PhoneEntryScreen)),
      )!;
      final contractorButton = _accountButton(l10n.demoLoginContractor);
      await tester.ensureVisible(contractorButton);
      await tester.tap(contractorButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        _debugField(tester, l10n.debugLoginEmailLabel),
        'synthetic@example.invalid',
      );
      await tester.enterText(
        _debugField(tester, l10n.debugLoginPasswordLabel),
        'synthetic-password',
      );
      final submitButton = _debugSubmitButton(l10n.debugLoginSubmit);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(repository.signInCalls, hasLength(1));
      expect(repository.signInCalls.single.email, 'synthetic@example.invalid');
      expect(repository.signInCalls.single.password, 'synthetic-password');
      expect(
        tester
            .widget<TextField>(_debugField(tester, l10n.debugLoginEmailLabel))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextField>(
              _debugField(tester, l10n.debugLoginPasswordLabel),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextField>(_debugField(tester, l10n.debugLoginEmailLabel))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<BatshButton>(
              find.widgetWithText(BatshButton, l10n.demoLoginHomeowner).first,
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<BatshButton>(
              find.widgetWithText(BatshButton, l10n.demoLoginContractor).first,
            )
            .onPressed,
        isNull,
      );

      response.complete(AuthResponse(session: null, user: null));
      await tester.pumpAndSettle();
      expect(profile.refreshCalls, 1);
      expect(find.text(l10n.debugLoginFailed), findsNothing);
    },
  );

  testWidgets('safe sign-in failure is visible and retry succeeds', (
    tester,
  ) async {
    _setViewport(tester);
    final repository = _FakeAuthRepository()..failNext = true;
    final profile = _CurrentProfileFixture(_profile(UserRole.contractor));
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        currentProfileProvider.overrideWith(() => profile),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      _resetViewport(tester);
    });

    await tester.pumpWidget(_loginApp(container, const Locale('en')));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(PhoneEntryScreen)),
    )!;
    final homeownerButton = _accountButton(l10n.demoLoginHomeowner);
    await tester.ensureVisible(homeownerButton);
    await tester.tap(homeownerButton);
    await tester.pumpAndSettle();

    Future<void> enterSyntheticCredentialsAndSubmit() async {
      await tester.enterText(
        _debugField(tester, l10n.debugLoginEmailLabel),
        'synthetic@example.invalid',
      );
      await tester.enterText(
        _debugField(tester, l10n.debugLoginPasswordLabel),
        'synthetic-password',
      );
      final submitButton = _debugSubmitButton(l10n.debugLoginSubmit);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
    }

    await enterSyntheticCredentialsAndSubmit();
    expect(repository.signInCalls, hasLength(1));
    expect(find.text(l10n.debugLoginFailed), findsOneWidget);
    expect(find.textContaining('synthetic'), findsNothing);
    expect(profile.refreshCalls, 0);

    repository.failNext = false;
    await enterSyntheticCredentialsAndSubmit();
    expect(repository.signInCalls, hasLength(2));
    expect(find.text(l10n.debugLoginFailed), findsNothing);
    expect(profile.refreshCalls, 1);
  });

  test(
    'Preview login and role switching retain separate compile-time gates',
    () {
      const previewLogin = bool.fromEnvironment(
        'SHATTAB_PREVIEW_DEBUG_LOGIN',
        defaultValue: false,
      );
      const debugTools = bool.fromEnvironment(
        'SHATTAB_DEBUG_TOOLS',
        defaultValue: true,
      );
      expect(DebugFlags.loginVisible, isTrue);
      expect(
        DebugFlags.roleSwitcher,
        kDebugMode && !previewLogin && debugTools,
      );
    },
  );
}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1500);
  tester.view.devicePixelRatio = 1;
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Finder _debugField(WidgetTester tester, String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Finder _accountButton(String label) => find.widgetWithText(BatshButton, label);

Finder _debugSubmitButton(String label) =>
    find.widgetWithText(BatshButton, label).last;

Widget _loginApp(ProviderContainer container, Locale locale) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: BatshTheme.light(),
        home: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: PhoneEntryScreen(),
          ),
        ),
      ),
    );

Profile _profile(UserRole role) => Profile(
  id: 'synthetic-user-id',
  role: role,
  fullName: 'Synthetic User',
  phone: '+201000000000',
  onboardingComplete: true,
);

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'synthetic-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final List<({String email, String password})> signInCalls = [];
  Future<AuthResponse>? response;
  bool failNext = false;
  void Function()? onSignIn;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCalls.add((email: email, password: password));
    onSignIn?.call();
    if (failNext) {
      failNext = false;
      throw StateError('synthetic authentication failure');
    }
    final pendingResponse = response;
    if (pendingResponse != null) return pendingResponse;
    return AuthResponse(session: null, user: null);
  }
}

class _CurrentProfileFixture extends CurrentProfile {
  _CurrentProfileFixture(this.profile);

  final Profile profile;
  int refreshCalls = 0;

  @override
  Future<Profile?> build() async => profile;

  @override
  Future<void> refresh() async {
    refreshCalls++;
    state = AsyncData(profile);
  }
}
