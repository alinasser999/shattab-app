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

  /// Forgot-password: send an SMS OTP so the user can sign back in, then set a
  /// new password. Only path that costs SMS — normal login is phone+password.
  Future<void> _forgotPassword() async {
    final phone = normalizeEgyptPhoneToE164(_controller.text);
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
                        phoneController: _controller,
                        phoneFocus: _phoneFocus,
                        phoneErrorText: _errorText,
                        forgotState: state,
                        onForgot: _forgotPassword,
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
      alignment: Alignment.center,
    );
  }
}

// ─── Logo & Tagline ──────────────────────────────────────────────────────────

class _LogoTagline extends StatelessWidget {
  const _LogoTagline({required this.disableMotion});
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/logo_wordmark.png',
      height: 76,
      fit: BoxFit.contain,
    );
    final tagline = Text(
      S.taglineNew,
      style: BatshTypography.labelMd.copyWith(
        color: BatshColors.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );

    if (disableMotion) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [logo, const SizedBox(height: BatshSpacing.sm), tagline],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo settles in: soft fade + gentle scale-down, no bounce.
        logo
            .animate()
            .fadeIn(duration: 600.ms, curve: Curves.easeOut)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              duration: 700.ms,
              curve: BatshMotion.heroEase,
            )
            .slideY(begin: -0.14, end: 0, duration: 700.ms, curve: BatshMotion.heroEase),
        const SizedBox(height: BatshSpacing.sm),
        tagline
            .animate()
            .fadeIn(duration: 500.ms, delay: 320.ms, curve: Curves.easeOut)
            .slideY(begin: 0.6, end: 0, duration: 500.ms, delay: 320.ms, curve: Curves.easeOut),
      ],
    );
  }
}

// ─── Hero Headline ───────────────────────────────────────────────────────────

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline({required this.disableMotion});
  final bool disableMotion;

  // Word-reveal cadence.
  static const int _baseDelayMs = 420;
  static const int _stepMs = 95;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 480;
    final base = (isMobile ? BatshTypography.headlineLg : BatshTypography.displayMd)
        .copyWith(fontWeight: FontWeight.w800, height: 1.18);

    final line1 = S.heroLine1.split(' ');
    final line2 = S.heroLine2.split(' ');
    final line2Start = _baseDelayMs + line1.length * _stepMs + 140;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WordLine(
          words: line1,
          style: base.copyWith(color: BatshColors.onSurface),
          startMs: _baseDelayMs,
          stepMs: _stepMs,
          disableMotion: disableMotion,
        ),
        const SizedBox(height: 8),
        _WordLine(
          words: line2,
          style: base.copyWith(color: BatshColors.primary),
          startMs: line2Start,
          stepMs: _stepMs,
          disableMotion: disableMotion,
        ),
      ],
    );
  }
}

/// One headline line whose words fade + rise + sharpen in sequence,
/// so the sentence reads itself in rather than popping as a block.
class _WordLine extends StatelessWidget {
  const _WordLine({
    required this.words,
    required this.style,
    required this.startMs,
    required this.stepMs,
    required this.disableMotion,
  });

  final List<String> words;
  final TextStyle style;
  final int startMs;
  final int stepMs;
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        for (var i = 0; i < words.length; i++)
          disableMotion
              ? Text(words[i], style: style)
              : Text(words[i], style: style)
                  .animate()
                  .fadeIn(
                    duration: 460.ms,
                    delay: (startMs + i * stepMs).ms,
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: 0.7,
                    end: 0,
                    duration: 520.ms,
                    delay: (startMs + i * stepMs).ms,
                    curve: BatshMotion.heroEase,
                  )
                  .blurXY(
                    begin: 6,
                    end: 0,
                    duration: 460.ms,
                    delay: (startMs + i * stepMs).ms,
                    curve: Curves.easeOut,
                  ),
      ],
    );
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
        .fadeIn(duration: 500.ms, delay: 1080.ms, curve: Curves.easeOut)
        .slideY(begin: 0.5, end: 0, duration: 500.ms, delay: 1080.ms, curve: Curves.easeOut);
  }
}

// ─── Login Card ──────────────────────────────────────────────────────────────

/// Normalises an Egyptian phone entry to E.164 (`+20xxxxxxxxxx`).
String normalizeEgyptPhoneToE164(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0020')) digits = digits.substring(4);
  if (digits.startsWith('20')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = digits.substring(1);
  return '+20$digits';
}

class _LoginCard extends ConsumerStatefulWidget {
  const _LoginCard({
    required this.phoneController,
    required this.phoneFocus,
    required this.phoneErrorText,
    required this.forgotState,
    required this.onForgot,
    required this.disableMotion,
  });
  final TextEditingController phoneController;
  final FocusNode phoneFocus;

  /// Phone-level validation error surfaced by the parent (used by forgot flow).
  final String? phoneErrorText;
  final OtpState forgotState;
  final VoidCallback onForgot;
  final bool disableMotion;

  @override
  ConsumerState<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends ConsumerState<_LoginCard> {
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = normalizeEgyptPhoneToE164(widget.phoneController.text);
    final password = _passwordController.text;
    if (!Validators.isEgyptianPhone(phone)) {
      setState(() => _error = S.invalidPhone);
      return;
    }
    if (password.length < 6) {
      setState(() => _error = S.passwordTooShort);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isSignUp) {
        await repo.signUpWithPhonePassword(phone: phone, password: password);
      } else {
        await repo.signInWithPhonePassword(phone: phone, password: password);
      }
      // Session now exists → router redirect handles navigation; refresh so the
      // freshly-created profile row is loaded.
      await ref.read(currentProfileProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      // On web this redirects the page; the finally below may not run before
      // navigation, which is fine.
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error ?? widget.phoneErrorText;
    final hasError = error != null;
    final fieldFill = BatshColors.surfaceContainerLow;
    final fieldRadius = BorderRadius.circular(16);

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.lg, vertical: BatshSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: BatshShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Google — fastest path, free, no SMS.
          _GoogleButton(onPressed: _busy ? null : _google),
          const SizedBox(height: BatshSpacing.md),
          Row(
            children: [
              const Expanded(child: Divider(color: BatshColors.outlineVariant)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
                child: Text(
                  S.orDivider,
                  style: BatshTypography.labelSm
                      .copyWith(color: BatshColors.onSurfaceVariant),
                ),
              ),
              const Expanded(child: Divider(color: BatshColors.outlineVariant)),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          // Phone
          Container(
            decoration: BoxDecoration(
              color: fieldFill,
              borderRadius: fieldRadius,
              border: hasError ? Border.all(color: BatshColors.error) : null,
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    height: 54,
                    decoration: const BoxDecoration(
                      border: Border(
                          right: BorderSide(color: BatshColors.outlineVariant)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🇪🇬', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          '+20',
                          style: BatshTypography.bodyLg.copyWith(
                            fontWeight: FontWeight.w600,
                            color: BatshColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            size: 18, color: BatshColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.phoneController,
                      focusNode: widget.phoneFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      style: BatshTypography.bodyLg
                          .copyWith(color: BatshColors.onSurface, height: 1.4),
                      decoration: InputDecoration(
                        hintText: S.phoneLocalHint,
                        hintStyle: BatshTypography.bodyLg.copyWith(
                          color: BatshColors.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: BatshSpacing.md, vertical: 14),
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
          const SizedBox(height: BatshSpacing.md),
          // Password
          Container(
            decoration: BoxDecoration(
              color: fieldFill,
              borderRadius: fieldRadius,
              border: hasError ? Border.all(color: BatshColors.error) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    style: BatshTypography.bodyLg
                        .copyWith(color: BatshColors.onSurface, height: 1.4),
                    decoration: InputDecoration(
                      hintText: S.passwordHint,
                      hintStyle: BatshTypography.bodyLg.copyWith(
                        color:
                            BatshColors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: BatshSpacing.md, vertical: 14),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: BatshColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: BatshSpacing.xs),
            Text(
              error,
              style: BatshTypography.labelSm.copyWith(color: BatshColors.error),
            ),
          ],
          const SizedBox(height: BatshSpacing.lg),
          BatshButton(
            label: _isSignUp ? S.createAccountAction : S.signInAction,
            onPressed: _busy ? null : _submit,
            isLoading: _busy,
          ),
          const SizedBox(height: BatshSpacing.sm),
          // Forgot password (sign-in mode only) — the sole SMS path.
          if (!_isSignUp)
            Center(
              child: TextButton(
                onPressed: widget.forgotState.isSending ? null : widget.onForgot,
                child: Text(
                  S.forgotPassword,
                  style: BatshTypography.labelMd.copyWith(
                    color: BatshColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: BatshSpacing.xs),
          // Mode toggle
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_isSignUp ? S.haveAccountPrompt : S.noAccountPrompt} ',
                  style: BatshTypography.bodyMd
                      .copyWith(color: BatshColors.onSurfaceVariant),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _isSignUp = !_isSignUp;
                    _error = null;
                  }),
                  child: Text(
                    _isSignUp ? S.signInAction : S.createAccountAction,
                    style: BatshTypography.bodyMd.copyWith(
                      color: BatshColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (widget.disableMotion) return card;
    return card
        .animate()
        .fadeIn(duration: 550.ms, delay: 1200.ms, curve: Curves.easeOut)
        .slideY(begin: 0.12, end: 0, duration: 600.ms, delay: 1200.ms, curve: BatshMotion.heroEase)
        .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1),
            duration: 600.ms, delay: 1200.ms, curve: BatshMotion.heroEase);
  }
}

// ─── Google Button ───────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BatshRadius.md + 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: BatshColors.outlineVariant),
              borderRadius: BorderRadius.circular(BatshRadius.md + 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google 'G' — brand colour, exempt from the token palette.
                Text(
                  'G',
                  style: BatshTypography.titleMd.copyWith(
                    color: const Color(0xFF4285F4),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Text(
                  S.continueWithGoogle,
                  style: BatshTypography.labelLg.copyWith(
                    color: BatshColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        .fadeIn(duration: 500.ms, delay: 1420.ms, curve: Curves.easeOut)
        .slideY(begin: 0.5, end: 0, duration: 500.ms, delay: 1420.ms, curve: Curves.easeOut);
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
