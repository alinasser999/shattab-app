import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../data/auth_repository.dart';
import '../presentation/providers/auth_provider.dart';
import 'providers/otp_provider.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizeToE164(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0020')) digits = digits.substring(4);
    if (digits.startsWith('20')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+20$digits';
  }

  Future<void> _submit() async {
    final phone = _normalizeToE164(_controller.text);
    if (!Validators.isEgyptianPhone(phone)) {
      setState(() => _errorText = S.invalidPhone);
      return;
    }
    setState(() => _errorText = null);

    final controller = ref.read(otpControllerProvider.notifier);
    final ok = await controller.sendOtp(phone);
    if (!mounted) return;
    if (ok) {
      context.push(Routes.otp);
    } else {
      final error = ref.read(otpControllerProvider).errorMessage;
      setState(() => _errorText = error ?? S.unknownErrorRetry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpControllerProvider);
    final isMobile = context.isMobile;

    return BatshScaffold(
      showAppBar: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BatshSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                S.appName,
                textAlign: TextAlign.center,
                style: BatshTypography.displayLg
                    .copyWith(color: BatshColors.primary),
              ),
              const SizedBox(height: BatshSpacing.xs),
              Text(
                S.appTagline,
                textAlign: TextAlign.center,
                style: BatshTypography.bodyMd
                    .copyWith(color: BatshColors.onSurfaceVariant),
              ),
              const SizedBox(height: BatshSpacing.xxl),
              Text(
                S.enterPhone,
                style: isMobile
                    ? BatshTypography.headlineLgMobile
                    : BatshTypography.headlineLg,
              ),
              const SizedBox(height: BatshSpacing.lg),
              BatshTextField(
                controller: _controller,
                hint: S.phoneHint,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                errorText: _errorText,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d +]')),
                  LengthLimitingTextInputFormatter(20),
                ],
              ),
              const SizedBox(height: BatshSpacing.lg),
              BatshButton(
                label: S.continueLabel,
                onPressed: state.isSending ? null : _submit,
                isLoading: state.isSending,
              ),
              if (kDebugMode) _DemoLoginBlock(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoLoginBlock extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DemoLoginBlock> createState() => _DemoLoginBlockState();
}

class _DemoLoginBlockState extends ConsumerState<_DemoLoginBlock> {
  bool _busy = false;
  String? _error;

  Future<void> _signInAs(String email) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithPassword(email: email, password: 'batsh-demo-2026');
      await ref.read(currentProfileProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: BatshSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: BatshSpacing.md),
          Text(
            'وضع التجربة (Debug)',
            textAlign: TextAlign.center,
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant),
          ),
          const SizedBox(height: BatshSpacing.md),
          BatshButton(
            label: 'دخول كصاحب شقة',
            style: BatshButtonStyle.secondary,
            onPressed:
                _busy ? null : () => _signInAs('homeowner@batsh.demo'),
            isLoading: _busy,
          ),
          const SizedBox(height: BatshSpacing.sm),
          BatshButton(
            label: 'دخول كمقاول',
            style: BatshButtonStyle.secondary,
            onPressed:
                _busy ? null : () => _signInAs('contractor@batsh.demo'),
          ),
          if (_error != null) ...[
            const SizedBox(height: BatshSpacing.sm),
            Text(_error!,
                style: BatshTypography.labelMd
                    .copyWith(color: BatshColors.error)),
          ],
        ],
      ),
    );
  }
}
