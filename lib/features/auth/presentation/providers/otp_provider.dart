import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/auth_repository.dart';
import '../../../../core/utils/error_mapper.dart';

part 'otp_provider.g.dart';

class OtpState {
  const OtpState({
    this.phone,
    this.isSending = false,
    this.isVerifying = false,
    this.cooldownSeconds = 0,
    this.errorMessage,
    this.lastSentAt,
  });

  final String? phone;
  final bool isSending;
  final bool isVerifying;
  final int cooldownSeconds;
  final String? errorMessage;
  final DateTime? lastSentAt;

  bool get canResend => cooldownSeconds == 0 && !isSending;

  OtpState copyWith({
    String? phone,
    bool? isSending,
    bool? isVerifying,
    int? cooldownSeconds,
    String? errorMessage,
    DateTime? lastSentAt,
    bool clearError = false,
  }) => OtpState(
    phone: phone ?? this.phone,
    isSending: isSending ?? this.isSending,
    isVerifying: isVerifying ?? this.isVerifying,
    cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
    state = state.copyWith(phone: phone, isSending: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      _startCooldown();
      state = state.copyWith(isSending: false, lastSentAt: DateTime.now());
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: ErrorMapper.map(e),
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    final phone = state.phone;
    if (phone == null) return false;
    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(phone: phone, code: code);
      state = state.copyWith(isVerifying: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        errorMessage: ErrorMapper.map(e),
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
