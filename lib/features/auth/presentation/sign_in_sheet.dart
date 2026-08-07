import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
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
/// underneath never unmounts, so the caller just re-checks
/// [currentSessionProvider] after this future resolves and re-runs the
/// original action if it's now non-null.
Future<void> showSignInSheet(BuildContext context, {required String reason}) {
  return BatshSheet.show<void>(
    context,
    contentPadding: EdgeInsets.zero,
    builder: (_) => _SignInSheet(reason: reason),
  );
}

/// Runs [action] immediately if signed in; otherwise shows the sign-in
/// sheet first and only runs [action] if sign-in actually succeeded.
Future<void> runSignedIn(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
  required VoidCallback action,
}) async {
  if (ref.read(currentSessionProvider) != null) {
    action();
    return;
  }
  await showSignInSheet(context, reason: reason);
  if (!context.mounted) return;
  if (ref.read(currentSessionProvider) != null) action();
}

enum _Step { phone, otp, name }

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

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String _normalizeToE164(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0020')) digits = digits.substring(4);
    if (digits.startsWith('20')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+20$digits';
  }

  Future<void> _sendCode() async {
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
    } else {
      setState(
        () => _error =
            ref.read(otpControllerProvider).errorMessage ??
            context.l10n.unknownErrorRetry,
      );
    }
  }

  Future<void> _verifyCode() async {
    final code = _otpCtrl.text.trim();
    if (!Validators.isOtpCode(code)) {
      setState(() => _error = context.l10n.invalidOtp);
      return;
    }
    setState(() => _error = null);
    final ok = await ref.read(otpControllerProvider.notifier).verifyOtp(code);
    if (!mounted) return;
    if (!ok) {
      setState(
        () => _error =
            ref.read(otpControllerProvider).errorMessage ??
            context.l10n.invalidOtp,
      );
      return;
    }
    await ref.read(currentProfileProvider.notifier).refresh();
    if (!mounted) return;
    final profile = ref.read(currentProfileProvider).value;
    if (profile != null && profile.fullName.isEmpty) {
      setState(() => _step = _Step.name);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.nameRequired);
      return;
    }
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) return;
    setState(() => _error = null);
    await ref
        .read(onboardingRepositoryProvider)
        .updateFullName(profileId: profile.id, fullName: name);
    await ref.read(currentProfileProvider.notifier).refresh();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        BatshSpacing.marginMobile,
        BatshSpacing.lg,
        BatshSpacing.marginMobile,
        BatshSpacing.lg + bottomInset,
      ),
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
                FilteringTextInputFormatter.allow(RegExp(r'[\d]')),
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
          ] else if (_step == _Step.otp) ...[
            Text(
              otpState.phone ?? '',
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.md),
            BatshTextField(
              controller: _otpCtrl,
              hint: context.l10n.otpHint,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _verifyCode(),
              errorText: _error,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              autofocus: true,
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshButton(
              label: context.l10n.continueLabel,
              onPressed: otpState.isVerifying ? null : _verifyCode,
              isLoading: otpState.isVerifying,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Center(
              child: TextButton(
                onPressed: otpState.canResend
                    ? () => ref
                          .read(otpControllerProvider.notifier)
                          .sendOtp(otpState.phone!)
                    : null,
                child: Text(
                  otpState.canResend
                      ? context.l10n.resendCode
                      : context.l10n.resendInSeconds.replaceAll(
                          '%s',
                          '${otpState.cooldownSeconds}',
                        ),
                ),
              ),
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
            BatshButton(label: context.l10n.saveProfile, onPressed: _saveName),
          ],
        ],
      ),
    );
  }
}
