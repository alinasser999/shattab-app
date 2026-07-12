import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/utils/error_mapper.dart';
import 'providers/otp_provider.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  String? _errorText;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _phoneFocus.dispose();
    _scrollController.dispose();
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

  void _scrollToPhone() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: BatshMotion.normal,
      curve: BatshMotion.easeOut,
    );
    _phoneFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpControllerProvider);
    final isMobile = context.isMobile;
    final disableMotion = MediaQuery.of(context).disableAnimations;
    final isWide = MediaQuery.of(context).size.width > 480;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _BackgroundLayer()),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? BatshSpacing.lg : BatshSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: isWide ? 56 : 32),
                      _LogoTagline(disableMotion: disableMotion),
                      SizedBox(height: isMobile ? 28 : 40),
                      _HeroHeadline(disableMotion: disableMotion),
                      SizedBox(height: BatshSpacing.sm),
                      _HeroSubtitle(disableMotion: disableMotion),
                      SizedBox(height: BatshSpacing.xl + 4),
                      _LoginCard(
                        controller: _controller,
                        focusNode: _phoneFocus,
                        errorText: _errorText,
                        state: state,
                        onSubmit: _submit,
                        disableMotion: disableMotion,
                      ),
                      SizedBox(height: BatshSpacing.gutter),
                      _Footer(
                        onLoginTap: _scrollToPhone,
                        disableMotion: disableMotion,
                      ),
                      SizedBox(height: BatshSpacing.xl),
                      if (kDebugMode) _DemoLoginBlock(),
                      SizedBox(height: BatshSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background ──────────────────────────────────────────────────────────────

class _BackgroundLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/login_bg.png',
      fit: BoxFit.cover,
      alignment: Alignment.topRight,
    );
  }
}

// ─── Logo & Tagline ──────────────────────────────────────────────────────────

class _LogoTagline extends StatelessWidget {
  const _LogoTagline({required this.disableMotion});
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: BatshColors.primaryFixed,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            'ش',
            style: BatshTypography.headlineLg.copyWith(
              color: BatshColors.primary,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        Text(
          S.appName,
          style: BatshTypography.titleLg.copyWith(
            fontWeight: FontWeight.w700,
            color: BatshColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          S.taglineNew,
          style: BatshTypography.labelMd.copyWith(
            color: BatshColors.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
    if (disableMotion) return child;
    return child
        .animate()
        .fadeIn(duration: 500.ms, curve: Curves.easeOutQuad)
        .slideY(begin: -12, end: 0, duration: 500.ms, curve: Curves.easeOutQuad);
  }
}

// ─── Hero Headline ───────────────────────────────────────────────────────────

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline({required this.disableMotion});
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 480;
    final child = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: isMobile
            ? BatshTypography.headlineLg.copyWith(fontWeight: FontWeight.w800, height: 1.2)
            : BatshTypography.displayMd.copyWith(fontWeight: FontWeight.w800, height: 1.2),
        children: [
          TextSpan(
            text: '${S.heroLine1}\n',
            style: TextStyle(color: BatshColors.onSurface),
          ),
          TextSpan(
            text: S.heroLine2,
            style: TextStyle(color: BatshColors.primary),
          ),
        ],
      ),
    );
    if (disableMotion) return child;
    return child
        .animate()
        .fadeIn(duration: 500.ms, delay: 150.ms, curve: Curves.easeOutQuad)
        .slideY(begin: 12, end: 0, duration: 500.ms, delay: 150.ms, curve: Curves.easeOutQuad);
  }
}

// ─── Hero Subtitle ───────────────────────────────────────────────────────────

class _HeroSubtitle extends StatelessWidget {
  const _HeroSubtitle({required this.disableMotion});
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
      child: Text(
        S.heroSubtitle,
        textAlign: TextAlign.center,
        style: BatshTypography.bodyLg.copyWith(
          color: BatshColors.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
    if (disableMotion) return child;
    return child
        .animate()
        .fadeIn(duration: 500.ms, delay: 250.ms, curve: Curves.easeOutQuad)
        .slideY(begin: 12, end: 0, duration: 500.ms, delay: 250.ms, curve: Curves.easeOutQuad);
  }
}

// ─── Login Card ──────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.state,
    required this.onSubmit,
    required this.disableMotion,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final OtpState state;
  final VoidCallback onSubmit;
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BatshSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: BatshShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              S.phoneLabel,
              style: BatshTypography.titleMd.copyWith(
                fontWeight: FontWeight.w700,
                color: BatshColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: errorText != null
                    ? BatshColors.error
                    : BatshColors.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(BatshRadius.md + 2),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    height: 54,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: errorText != null
                              ? BatshColors.error
                              : BatshColors.outlineVariant,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🇪🇬',
                          style: TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+20',
                          style: BatshTypography.bodyLg.copyWith(
                            fontWeight: FontWeight.w600,
                            color: BatshColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: BatshColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onSubmit(),
                      style: BatshTypography.bodyLg.copyWith(
                        color: BatshColors.onSurface,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: S.phoneLocalHint,
                        hintStyle: BatshTypography.bodyLg.copyWith(
                          color: BatshColors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: BatshSpacing.md,
                          vertical: 14,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d]')),
                        LengthLimitingTextInputFormatter(11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: BatshSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(right: BatshSpacing.sm),
              child: Text(
                errorText!,
                style: BatshTypography.labelSm.copyWith(color: BatshColors.error),
              ),
            ),
          ],
          const SizedBox(height: BatshSpacing.lg),
          BatshButton(
            label: S.continueLabel,
            onPressed: state.isSending ? null : onSubmit,
            isLoading: state.isSending,
          ),
          const SizedBox(height: BatshSpacing.md),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 13, color: BatshColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  S.verifyMessage,
                  style: BatshTypography.labelSm.copyWith(
                    color: BatshColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (disableMotion) return card;
    return card
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms, curve: Curves.easeOutQuad)
        .slideY(begin: 20, end: 0, duration: 500.ms, delay: 600.ms, curve: Curves.easeOutQuad)
        .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1),
            duration: 500.ms, delay: 600.ms, curve: BatshMotion.springTap);
  }
}

// ─── Footer ──────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onLoginTap,
    required this.disableMotion,
  });
  final VoidCallback onLoginTap;
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                size: 13, color: BatshColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              S.dataSecure,
              style: BatshTypography.labelSm.copyWith(
                color: BatshColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.gutter),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${S.loginPrompt} ',
              style: BatshTypography.bodyMd.copyWith(
                color: BatshColors.onSurfaceVariant,
              ),
            ),
            GestureDetector(
              onTap: onLoginTap,
              child: Text(
                S.loginAction,
                style: BatshTypography.bodyMd.copyWith(
                  color: BatshColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
    if (disableMotion) return child;
    return child
        .animate()
        .fadeIn(duration: 500.ms, delay: 900.ms, curve: Curves.easeOutQuad)
        .slideY(begin: 12, end: 0, duration: 500.ms, delay: 900.ms, curve: Curves.easeOutQuad);
  }
}

// ─── Debug Demo Login ────────────────────────────────────────────────────────

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
      setState(() => _error = ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: BatshShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.debugMode,
            textAlign: TextAlign.center,
            style: BatshTypography.labelMd.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          BatshButton(
            label: S.demoLoginHomeowner,
            style: BatshButtonStyle.secondary,
            onPressed: _busy ? null : () => _signInAs('homeowner@batsh.demo'),
            isLoading: _busy,
          ),
          const SizedBox(height: BatshSpacing.sm),
          BatshButton(
            label: S.demoLoginContractor,
            style: BatshButtonStyle.secondary,
            onPressed: _busy ? null : () => _signInAs('contractor@batsh.demo'),
          ),
          if (_error != null) ...[
            const SizedBox(height: BatshSpacing.sm),
            Text(_error!,
                textAlign: TextAlign.center,
                style: BatshTypography.labelMd
                    .copyWith(color: BatshColors.error)),
          ],
        ],
      ),
    );
  }
}
