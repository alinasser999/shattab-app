import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
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
    final ok = await ref.read(otpControllerProvider.notifier).verifyOtp(code);
    if (!mounted) return;
    if (!ok) {
      final error = ref.read(otpControllerProvider).errorMessage;
      setState(() => _errorText = error ?? context.l10n.invalidOtp);
    }
    // On success the router redirect kicks in via currentSessionProvider.
  }

  Future<void> _resend() async {
    final phone = ref.read(otpControllerProvider).phone;
    if (phone == null) return;
    await ref.read(otpControllerProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpControllerProvider);
    final isMobile = context.isMobile;

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
              Text(
                state.phone ?? '',
                style: BatshTypography.bodyMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: BatshSpacing.lg),
              BatshTextField(
                controller: _controller,
                hint: context.l10n.otpHint,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                errorText: _errorText,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
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
                    state.canResend
                        ? context.l10n.resendCode
                        : context.l10n.resendInSeconds.replaceAll(
                            '%s',
                            '${state.cooldownSeconds}',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
