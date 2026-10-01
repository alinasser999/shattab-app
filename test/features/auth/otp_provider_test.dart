import 'dart:async';

import 'package:batsh/core/l10n/strings.dart';
import 'package:batsh/core/utils/error_mapper.dart';
import 'package:batsh/features/auth/data/auth_repository.dart';
import 'package:batsh/features/auth/presentation/providers/otp_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('signup confirmation verifies the saved phone and SMS code', (
    tester,
  ) async {
    final repository = _RecordingAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(otpControllerProvider, (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    final controller = container.read(otpControllerProvider.notifier);
    controller.beginSignupConfirmation('opaque-test-phone');

    expect(
      container.read(otpControllerProvider).purpose,
      OtpPurpose.signupConfirmation,
    );
    await tester.pump(const Duration(seconds: 60));
    expect(repository.signupResendCalls, 0);
    expect(repository.signInOtpCalls, 0);

    final verified = await controller.verifyOtp('synthetic-code-token');

    expect(verified, isTrue);
    expect(repository.verifiedPhone, 'opaque-test-phone');
    expect(repository.verifiedCode, 'synthetic-code-token');
    expect(repository.verifyCalls, 1);
    expect(
      container.read(otpControllerProvider).purpose,
      OtpPurpose.signupConfirmation,
    );
  });

  testWidgets(
    'signup confirmation cooldown blocks resend, then uses only the signup resend operation',
    (tester) async {
      final repository = _RecordingAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      final subscription = container.listen(otpControllerProvider, (_, _) {});
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      final controller = container.read(otpControllerProvider.notifier);

      controller.beginSignupConfirmation('opaque-test-phone');
      expect(container.read(otpControllerProvider).cooldownSeconds, 60);
      expect(await controller.resendCode(), isFalse);
      expect(repository.signupResendCalls, 0);
      expect(repository.signInOtpCalls, 0);

      await tester.pump(const Duration(seconds: 60));
      expect(container.read(otpControllerProvider).canResend, isTrue);

      expect(await controller.resendCode(), isTrue);
      expect(repository.signupResendCalls, 1);
      expect(repository.resendPhone, 'opaque-test-phone');
      expect(repository.signInOtpCalls, 0);
      expect(
        container.read(otpControllerProvider).purpose,
        OtpPurpose.signupConfirmation,
      );
      expect(container.read(otpControllerProvider).cooldownSeconds, 60);
      await tester.pump(const Duration(seconds: 60));
    },
  );

  testWidgets(
    'legacy guest/recovery OTP keeps the sign-in operation and purpose',
    (tester) async {
      final repository = _RecordingAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      final subscription = container.listen(otpControllerProvider, (_, _) {});
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      final controller = container.read(otpControllerProvider.notifier);

      expect(await controller.sendOtp('opaque-test-phone'), isTrue);
      expect(repository.signInOtpCalls, 1);
      expect(repository.lastSignInPhone, 'opaque-test-phone');
      expect(
        container.read(otpControllerProvider).purpose,
        OtpPurpose.signInOrRecovery,
      );
      await tester.pump(const Duration(seconds: 60));
      expect(await controller.resendCode(), isTrue);
      expect(repository.signInOtpCalls, 2);
      expect(repository.signupResendCalls, 0);
      expect(
        container.read(otpControllerProvider).purpose,
        OtpPurpose.signInOrRecovery,
      );
      await tester.pump(const Duration(seconds: 60));
    },
  );

  testWidgets('failed signup resend retains the confirmation flow for retry', (
    tester,
  ) async {
    final repository = _RecordingAuthRepository()..failSignupResend = true;
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(otpControllerProvider, (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });
    final controller = container.read(otpControllerProvider.notifier);

    controller.beginSignupConfirmation('opaque-test-phone');
    await tester.pump(const Duration(seconds: 60));

    expect(await controller.resendCode(), isFalse);
    final state = container.read(otpControllerProvider);
    expect(state.purpose, OtpPurpose.signupConfirmation);
    expect(state.phone, 'opaque-test-phone');
    expect(state.isSending, isFalse);
    expect(state.errorOperation, OtpOperation.resend);
    expect(state.errorMessage, S.unknownErrorRetry);
    expect(repository.signInOtpCalls, 0);
  });

  testWidgets('send and sign-in resend tag failures and clear them on retry', (
    tester,
  ) async {
    final repository = _RecordingAuthRepository()
      ..sendError = const FormatException('sms_send_failed');
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(otpControllerProvider, (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });
    final controller = container.read(otpControllerProvider.notifier);

    expect(await controller.sendOtp('opaque-test-phone'), isFalse);
    var state = container.read(otpControllerProvider);
    expect(state.errorOperation, OtpOperation.send);
    expect(state.errorMessage, S.unknownErrorRetry);
    expect(state.phone, 'opaque-test-phone');
    expect(state.purpose, OtpPurpose.signInOrRecovery);

    repository.sendError = null;
    expect(await controller.sendOtp('opaque-test-phone'), isTrue);
    state = container.read(otpControllerProvider);
    expect(state.errorOperation, isNull);
    expect(state.errorMessage, isNull);
    await tester.pump(const Duration(seconds: 60));

    repository.sendError = const FormatException('invalid token');
    expect(await controller.resendCode(), isFalse);
    state = container.read(otpControllerProvider);
    expect(state.errorOperation, OtpOperation.resend);
    expect(state.errorMessage, S.unknownErrorRetry);
    expect(state.phone, 'opaque-test-phone');
    expect(state.purpose, OtpPurpose.signInOrRecovery);
    expect(repository.signInOtpCalls, 3);

    repository.sendError = null;
    expect(await controller.resendCode(), isTrue);
    state = container.read(otpControllerProvider);
    expect(state.errorOperation, isNull);
    expect(state.errorMessage, isNull);
    expect(repository.signInOtpCalls, 4);
    await tester.pump(const Duration(seconds: 60));
  });

  test('OTP verification requires a session and can be retried', () async {
    final repository = _RecordingAuthRepository()
      ..nextVerificationResponse = AuthResponse();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(otpControllerProvider, (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });
    final controller = container.read(otpControllerProvider.notifier);
    controller.beginSignupConfirmation('opaque-test-phone');

    expect(await controller.verifyOtp('synthetic-code-token'), isFalse);
    final rejectedState = container.read(otpControllerProvider);
    expect(rejectedState.isVerifying, isFalse);
    expect(rejectedState.errorOperation, OtpOperation.verify);
    expect(rejectedState.errorMessage, S.unknownErrorRetry);

    repository.nextVerificationResponse = AuthResponse(
      session: _syntheticSession,
    );
    expect(await controller.verifyOtp('synthetic-code-token'), isTrue);
    final acceptedState = container.read(otpControllerProvider);
    expect(acceptedState.isVerifying, isFalse);
    expect(acceptedState.errorOperation, isNull);
    expect(acceptedState.errorMessage, isNull);
    expect(repository.verifyCalls, 2);
  });

  test('verification exceptions clear loading and allow a retry', () async {
    final repository = _RecordingAuthRepository()
      ..verificationError = const FormatException('network timeout');
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(otpControllerProvider, (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });
    final controller = container.read(otpControllerProvider.notifier);
    controller.beginSignupConfirmation('opaque-test-phone');

    expect(await controller.verifyOtp('synthetic-code-token'), isFalse);
    var state = container.read(otpControllerProvider);
    expect(state.isVerifying, isFalse);
    expect(state.errorOperation, OtpOperation.verify);
    expect(state.errorMessage, S.errNetwork);

    repository.verificationError = null;
    repository.nextVerificationResponse = AuthResponse(
      session: _syntheticSession,
    );
    expect(await controller.verifyOtp('synthetic-code-token'), isTrue);
    state = container.read(otpControllerProvider);
    expect(state.isVerifying, isFalse);
    expect(state.errorOperation, isNull);
    expect(state.errorMessage, isNull);
    expect(repository.verifyCalls, 2);
  });

  test(
    'concurrent verify, send, and resend do not stack auth requests',
    () async {
      final pendingVerification = Completer<AuthResponse>();
      final repository = _RecordingAuthRepository()
        ..pendingVerification = pendingVerification;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      final subscription = container.listen(otpControllerProvider, (_, _) {});
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      final controller = container.read(otpControllerProvider.notifier);
      controller.beginSignupConfirmation('opaque-test-phone');

      final firstAttempt = controller.verifyOtp('first-synthetic-code');
      expect(container.read(otpControllerProvider).isVerifying, isTrue);
      expect(await controller.verifyOtp('second-synthetic-code'), isFalse);
      expect(await controller.sendOtp('another-synthetic-phone'), isFalse);
      expect(await controller.resendCode(), isFalse);
      expect(repository.verifyCalls, 1);
      expect(repository.signInOtpCalls, 0);
      expect(repository.signupResendCalls, 0);

      pendingVerification.complete(AuthResponse(session: _syntheticSession));
      expect(await firstAttempt, isTrue);
      expect(container.read(otpControllerProvider).isVerifying, isFalse);
      expect(repository.verifiedCode, 'first-synthetic-code');
    },
  );
}

class _RecordingAuthRepository extends AuthRepository {
  _RecordingAuthRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  int signInOtpCalls = 0;
  int signupResendCalls = 0;
  int verifyCalls = 0;
  String? lastSignInPhone;
  String? resendPhone;
  String? verifiedPhone;
  String? verifiedCode;
  bool failSignupResend = false;
  Object? sendError;
  AuthResponse? nextVerificationResponse = AuthResponse(
    session: _syntheticSession,
  );
  Object? verificationError;
  Completer<AuthResponse>? pendingVerification;

  @override
  Future<void> sendOtp(String phone) async {
    signInOtpCalls++;
    lastSignInPhone = phone;
    final error = sendError;
    if (error != null) throw error;
  }

  @override
  Future<void> resendPhoneSignupConfirmation(String phone) async {
    signupResendCalls++;
    resendPhone = phone;
    if (failSignupResend) throw const FormatException('fixture failure');
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String code,
  }) async {
    verifyCalls++;
    verifiedPhone = phone;
    verifiedCode = code;
    final error = verificationError;
    if (error != null) throw error;
    final pending = pendingVerification;
    if (pending != null) return pending.future;
    return nextVerificationResponse ?? AuthResponse();
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
