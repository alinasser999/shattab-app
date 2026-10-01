import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/phone_number_formatter.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_text_field.dart';
import 'providers/otp_provider.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (!Validators.isOtpCode(code)) {
      setState(() => _errorText = context.l10n.invalidOtp);
      return;
    }
    setState(() => _errorText = null);
    await ref.read(otpControllerProvider.notifier).verifyOtp(code);
    // On success the router redirect kicks in via currentSessionProvider.
  }

  Future<void> _resend() async {
    setState(() => _errorText = null);
    await ref.read(otpControllerProvider.notifier).resendCode();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpControllerProvider);
    final isMobile = context.isMobile;
    final verificationError = state.errorOperation == OtpOperation.verify
        ? state.errorMessage
        : null;
    final resendError = state.errorOperation == OtpOperation.resend
        ? state.errorMessage
        : null;
    final signupPhone =
        state.purpose == OtpPurpose.signupConfirmation && state.phone != null
        ? _maskPhone(state.phone!)
        : null;

    return BatshScaffold(
      title: context.l10n.otpTitle,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BatshSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.otpTitle,
                style: isMobile
                    ? BatshTypography.headlineLgMobile
                    : BatshTypography.headlineLg,
              ),
              const SizedBox(height: BatshSpacing.sm),
              if (signupPhone != null)
                Semantics(
                  liveRegion: true,
                  label: context.l10n.signupOtpSentTo(signupPhone),
                  child: ExcludeSemantics(
                    child: Text(
                      context.l10n.signupOtpSentTo('\u2066$signupPhone\u2069'),
                      style: BatshTypography.bodyMd.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  '\u2066${state.phone ?? ''}\u2069',
                  textDirection: TextDirection.ltr,
                  style: BatshTypography.bodyMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: BatshSpacing.lg),
              BatshTextField(
                controller: _controller,
                semanticLabel: context.l10n.otpTitle,
                hint: context.l10n.otpHint,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                errorText: _errorText ?? verificationError,
                inputFormatters: [
                  LocalizedDigitsOnlyFormatter(),
                  LengthLimitingTextInputFormatter(6),
                ],
                autofocus: true,
              ),
              const SizedBox(height: BatshSpacing.lg),
              BatshButton(
                label: context.l10n.continueLabel,
                onPressed: state.isVerifying ? null : _submit,
                isLoading: state.isVerifying,
              ),
              const SizedBox(height: BatshSpacing.md),
              Center(
                child: TextButton(
                  onPressed: state.canResend ? _resend : null,
                  child: Text(
                    state.cooldownSeconds > 0
                        ? context.l10n.resendInSeconds.replaceAll(
                            '%s',
                            '${state.cooldownSeconds}',
                          )
                        : context.l10n.resendCode,
                  ),
                ),
              ),
              if (resendError != null) ...[
                const SizedBox(height: BatshSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    resendError,
                    textAlign: TextAlign.center,
                    style: BatshTypography.bodySm.copyWith(
                      color: context.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _maskPhone(String phone) {
  final digits = asciiDigitsOnly(phone);
  if (digits.length <= 4) return '••••';
  final countryPrefix = digits.startsWith('20') ? '+20 ' : '';
  return '$countryPrefix•••• ${digits.substring(digits.length - 4)}';
}
