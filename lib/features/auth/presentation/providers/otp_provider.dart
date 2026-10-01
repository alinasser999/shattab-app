import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/auth_repository.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/phone_number_formatter.dart';

part 'otp_provider.g.dart';

enum OtpPurpose { signInOrRecovery, signupConfirmation }

class OtpState {
  const OtpState({
    this.phone,
    this.purpose = OtpPurpose.signInOrRecovery,
    this.isSending = false,
    this.isVerifying = false,
    this.cooldownSeconds = 0,
    this.errorMessage,
    this.errorOperation,
    this.lastSentAt,
  });

  final String? phone;
  final OtpPurpose purpose;
  final bool isSending;
  final bool isVerifying;
  final int cooldownSeconds;
  final String? errorMessage;
  final OtpOperation? errorOperation;
  final DateTime? lastSentAt;

  bool get canResend => cooldownSeconds == 0 && !isSending && !isVerifying;

  OtpState copyWith({
    String? phone,
    OtpPurpose? purpose,
    bool? isSending,
    bool? isVerifying,
    int? cooldownSeconds,
    String? errorMessage,
    OtpOperation? errorOperation,
    DateTime? lastSentAt,
    bool clearError = false,
  }) => OtpState(
    phone: phone ?? this.phone,
    purpose: purpose ?? this.purpose,
    isSending: isSending ?? this.isSending,
    isVerifying: isVerifying ?? this.isVerifying,
    cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    errorOperation: clearError ? null : (errorOperation ?? this.errorOperation),
    lastSentAt: lastSentAt ?? this.lastSentAt,
  );
}

@riverpod
class OtpController extends _$OtpController {
  Timer? _ticker;
  static const int _cooldownSeconds = 60;

  @override
  OtpState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const OtpState();
  }

  Future<bool> sendOtp(String phone) async {
    if (state.isSending || state.isVerifying) return false;
    return _requestOtp(
      phone,
      purpose: OtpPurpose.signInOrRecovery,
      operation: OtpOperation.send,
    );
  }

  Future<bool> _requestOtp(
    String phone, {
    required OtpPurpose purpose,
    required OtpOperation operation,
  }) async {
    // Existing callers use this for guest sign-in and account recovery.
    // Reset any pending signup intent before starting a different OTP flow.
    _ticker?.cancel();
    state = OtpState(phone: phone, purpose: purpose, isSending: true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      _startCooldown();
      state = state.copyWith(isSending: false, lastSentAt: DateTime.now());
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: ErrorMapper.mapOtp(e, operation: operation),
        errorOperation: operation,
      );
      return false;
    }
  }

  /// Starts the confirmation screen after Supabase has already sent the
  /// initial signup SMS. This deliberately does not request another code.
  void beginSignupConfirmation(String phone) {
    _ticker?.cancel();
    state = OtpState(
      phone: phone,
      purpose: OtpPurpose.signupConfirmation,
      lastSentAt: DateTime.now(),
    );
    _startCooldown();
  }

  /// Resends using the operation that matches the current flow. Signup
  /// confirmation must use Auth's resend endpoint, never signInWithOtp.
  Future<bool> resendCode() async {
    final phone = state.phone;
    if (phone == null || state.isVerifying || !state.canResend) return false;
    if (state.purpose == OtpPurpose.signInOrRecovery) {
      return _requestOtp(
        phone,
        purpose: state.purpose,
        operation: OtpOperation.resend,
      );
    }

    state = state.copyWith(isSending: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resendPhoneSignupConfirmation(phone);
      _startCooldown();
      state = state.copyWith(isSending: false, lastSentAt: DateTime.now());
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: ErrorMapper.mapOtp(e, operation: OtpOperation.resend),
        errorOperation: OtpOperation.resend,
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    final phone = state.phone;
    if (phone == null || state.isSending || state.isVerifying) return false;
    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .verifyOtp(phone: phone, code: asciiDigitsOnly(code));
      if (response.session == null) {
        state = state.copyWith(
          isVerifying: false,
          errorMessage: ErrorMapper.mapOtp(
            'verification completed without a session',
            operation: OtpOperation.verify,
          ),
          errorOperation: OtpOperation.verify,
        );
        return false;
      }
      state = state.copyWith(isVerifying: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        errorMessage: ErrorMapper.mapOtp(e, operation: OtpOperation.verify),
        errorOperation: OtpOperation.verify,
      );
      return false;
    }
  }

  void _startCooldown() {
    _ticker?.cancel();
    state = state.copyWith(cooldownSeconds: _cooldownSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.cooldownSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(cooldownSeconds: 0);
      } else {
        state = state.copyWith(cooldownSeconds: remaining);
      }
    });
  }
}
