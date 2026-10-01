import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/phone_number_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../../onboarding/data/onboarding_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/otp_provider.dart';
import '../../../core/widgets/batsh_sheet.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Sign-in bottom sheet shown to a guest-browsing homeowner at the moment
/// of a write action (save / send request / create post). The screen
/// underneath never unmounts. It returns `true` only after authentication and
/// required profile setup are ready; dismissing it returns `false`.
Future<bool> showSignInSheet(
  BuildContext context, {
  required String reason,
}) async {
  final completed = await BatshSheet.show<bool>(
    context,
    contentPadding: EdgeInsets.zero,
    builder: (_) => _SignInSheet(reason: reason),
  );
  return completed == true;
}

final Expando<bool> _pendingSignInGates = Expando<bool>(
  'Shattab pending sign-in gate',
);

/// Runs [action] immediately if signed in; otherwise shows the sign-in
/// sheet first and only runs [action] if sign-in actually succeeded.
Future<void> runSignedIn(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
  required VoidCallback action,
}) async {
  if (_pendingSignInGates[context] == true) return;
  if (ref.read(currentSessionProvider) != null) {
    action();
    return;
  }
  _pendingSignInGates[context] = true;
  try {
    final completed = await showSignInSheet(context, reason: reason);
    if (!completed || !context.mounted) return;
    if (ref.read(currentSessionProvider) != null) action();
  } finally {
    _pendingSignInGates[context] = false;
  }
}

enum _Step { phone, otp, profile, name }

class _SignInSheet extends ConsumerStatefulWidget {
  const _SignInSheet({required this.reason});
  final String reason;

  @override
  ConsumerState<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends ConsumerState<_SignInSheet> {
  _Step _step = _Step.phone;
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _error;
  bool _otpVerified = false;
  bool _isRefreshingProfile = false;
  bool _isSavingName = false;
  String? _pendingSavedName;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String _normalizeToE164(String raw) {
    return normalizeEgyptPhone(raw);
  }

  Future<void> _sendCode() async {
    final otpState = ref.read(otpControllerProvider);
    if (otpState.isSending || otpState.isVerifying) return;
    final phone = _normalizeToE164(_phoneCtrl.text);
    if (!Validators.isEgyptianPhone(phone)) {
      setState(() => _error = context.l10n.invalidPhone);
      return;
    }
    setState(() => _error = null);
    final ok = await ref.read(otpControllerProvider.notifier).sendOtp(phone);
    if (!mounted) return;
    if (ok) {
      setState(() => _step = _Step.otp);
    }
  }

  Future<void> _resendCode() async {
    if (!ref.read(otpControllerProvider).canResend) return;
    setState(() => _error = null);
    final ok = await ref.read(otpControllerProvider.notifier).resendCode();
    if (!mounted) return;
    if (ok) setState(() => _error = null);
  }

  Future<void> _verifyCode() async {
    if (_isRefreshingProfile) return;
    if (_otpVerified) {
      await _refreshProfileAndContinue(expectedName: _pendingSavedName);
      return;
    }
    final otpState = ref.read(otpControllerProvider);
    if (otpState.isSending || otpState.isVerifying) return;
    final code = asciiDigitsOnly(_otpCtrl.text);
    if (!Validators.isOtpCode(code)) {
      setState(() => _error = context.l10n.invalidOtp);
      return;
    }
    setState(() => _error = null);
    final ok = await ref.read(otpControllerProvider.notifier).verifyOtp(code);
    if (!mounted) return;
    if (!ok) return;
    _otpVerified = true;
    await _refreshProfileAndContinue();
  }

  Future<void> _refreshProfileAndContinue({String? expectedName}) async {
    if (_isRefreshingProfile) return;
    setState(() {
      _isRefreshingProfile = true;
      _error = null;
    });
    try {
      if (ref.read(currentSessionProvider) == null) {
        if (!mounted) return;
        setState(() {
          _step = _Step.profile;
          _error = context.l10n.errAuthFailed;
        });
        return;
      }

      await ref.read(currentProfileProvider.notifier).refresh();
      if (!mounted) return;
      final profileState = ref.read(currentProfileProvider);
      final profile = profileState.asData?.value;
      if (profileState.hasError || profileState.isLoading || profile == null) {
        setState(() {
          _step = _Step.profile;
          _error = context.l10n.profileError;
        });
        return;
      }

      if (expectedName != null) {
        if (profile.fullName.trim() == expectedName) {
          Navigator.of(context).pop(true);
          return;
        }
        _pendingSavedName = null;
        setState(() {
          _step = _Step.name;
          _error = context.l10n.profileError;
        });
        return;
      }

      if (profile.fullName.trim().isEmpty) {
        setState(() => _step = _Step.name);
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = _Step.profile;
        _error = context.l10n.profileError;
      });
    } finally {
      if (mounted) setState(() => _isRefreshingProfile = false);
    }
  }

  Future<void> _saveName() async {
    if (_isSavingName) return;
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      setState(() => _error = context.l10n.nameNotEnough);
      return;
    }
    final profileState = ref.read(currentProfileProvider);
    final profile = profileState.asData?.value;
    if (profileState.hasError || profileState.isLoading || profile == null) {
      setState(() {
        _step = _Step.profile;
        _error = context.l10n.profileError;
      });
      return;
    }
    setState(() {
      _error = null;
      _isSavingName = true;
    });
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .updateFullName(profileId: profile.id, fullName: name);
      if (!mounted) return;
      _pendingSavedName = name;
      await _refreshProfileAndContinue(expectedName: name);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = context.l10n.unknownErrorRetry);
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _retryProfile() =>
      _refreshProfileAndContinue(expectedName: _pendingSavedName);

  // Profile readiness is a separate retry step so a verified OTP is never
  // submitted a second time when profile loading or saving needs another try.
  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpControllerProvider);
    final isOtpContinueBusy = otpState.isVerifying || _isRefreshingProfile;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        BatshSpacing.marginMobile,
        BatshSpacing.lg,
        BatshSpacing.marginMobile,
        BatshSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.signInSheetTitle,
              textAlign: TextAlign.center,
              style: BatshTypography.titleLg,
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              widget.reason,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            if (_step == _Step.phone) ...[
              BatshTextField(
                controller: _phoneCtrl,
                label: context.l10n.phoneLabel,
                hint: context.l10n.phoneLocalHint,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendCode(),
                errorText: _error,
                inputFormatters: [
                  LocalizedDigitsOnlyFormatter(),
                  LengthLimitingTextInputFormatter(11),
                ],
                autofocus: true,
              ),
              const SizedBox(height: BatshSpacing.lg),
              BatshButton(
                label: context.l10n.continueLabel,
                onPressed: otpState.isSending ? null : _sendCode,
                isLoading: otpState.isSending,
              ),
              if (_error == null &&
                  otpState.errorOperation == OtpOperation.send &&
                  otpState.errorMessage != null) ...[
                const SizedBox(height: BatshSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    otpState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: BatshTypography.bodySm.copyWith(
                      color: context.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ] else if (_step == _Step.otp) ...[
              Text(
                '\u2066${otpState.phone ?? ''}\u2069',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: BatshTypography.bodyMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: BatshSpacing.md),
              BatshTextField(
                controller: _otpCtrl,
                semanticLabel: context.l10n.otpTitle,
                hint: context.l10n.otpHint,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyCode(),
                errorText:
                    _error ??
                    (otpState.errorOperation == OtpOperation.verify
                        ? otpState.errorMessage
                        : null),
                inputFormatters: [
                  LocalizedDigitsOnlyFormatter(),
                  LengthLimitingTextInputFormatter(6),
                ],
                autofocus: true,
              ),
              const SizedBox(height: BatshSpacing.lg),
              BatshButton(
                label: context.l10n.continueLabel,
                onPressed: isOtpContinueBusy ? null : _verifyCode,
                isLoading: isOtpContinueBusy,
              ),
              const SizedBox(height: BatshSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: otpState.canResend ? _resendCode : null,
                  child: Text(
                    otpState.cooldownSeconds > 0
                        ? context.l10n.resendInSeconds.replaceAll(
                            '%s',
                            '${otpState.cooldownSeconds}',
                          )
                        : context.l10n.resendCode,
                  ),
                ),
              ),
              if (otpState.errorOperation == OtpOperation.resend &&
                  otpState.errorMessage != null) ...[
                const SizedBox(height: BatshSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    otpState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: BatshTypography.bodySm.copyWith(
                      color: context.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ] else if (_step == _Step.profile) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _error ?? context.l10n.profileError,
                  textAlign: TextAlign.center,
                  style: BatshTypography.bodyMd.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: BatshSpacing.lg),
              BatshButton(
                label: context.l10n.tryAgain,
                onPressed: _isRefreshingProfile ? null : _retryProfile,
                isLoading: _isRefreshingProfile,
              ),
            ] else ...[
              Text(
                context.l10n.whatsYourName,
                textAlign: TextAlign.center,
                style: BatshTypography.bodyMd,
              ),
              const SizedBox(height: BatshSpacing.md),
              BatshTextField(
                controller: _nameCtrl,
                label: context.l10n.profileNameLabel,
                hint: context.l10n.fullNameHint,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveName(),
                errorText: _error,
                autofocus: true,
              ),
              const SizedBox(height: BatshSpacing.lg),
              BatshButton(
                label: context.l10n.saveProfile,
                onPressed: _isSavingName ? null : _saveName,
                isLoading: _isSavingName,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
