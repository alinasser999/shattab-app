import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_theme.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/utils/error_mapper.dart';
import 'providers/otp_provider.dart';
import '../../../core/theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';
part 'phone_entry_hero.dart';
part 'phone_entry_login_card.dart';

/// The cinematic intro plays once per app session. After the first mount the
/// login card should appear instantly — a returning user shouldn't pay a ~1.4s
/// choreography tax on every visit.
bool _heroIntroSeen = false;

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
  void initState() {
    super.initState();
    // Latch after the first frame so this mount still animates, but any later
    // return to the screen skips straight to the resting state.
    WidgetsBinding.instance.addPostFrameCallback((_) => _heroIntroSeen = true);
  }

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
      setState(() => _errorText = context.l10n.invalidPhone);
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
      setState(() => _errorText = error ?? context.l10n.unknownErrorRetry);
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
    // Suppress the intro once seen (or when the OS asks for reduced motion).
    final disableMotion =
        MediaQuery.disableAnimationsOf(context) || _heroIntroSeen;
    final isWide = MediaQuery.of(context).size.width > 480;

    return Scaffold(
      // Login is always a warm, light surface regardless of system theme.
      // Without pinning, the inner TextFields inherit the dark
      // InputDecorationTheme and render charcoal fills inside the white card,
      // making typed input invisible on dark-mode phones.
      body: Theme(
        data: BatshTheme.light(),
        child: Stack(
          children: [
            Positioned.fill(child: _BackgroundLayer()),
            const Positioned.fill(child: _ScrimLayer()),
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
                        SizedBox(height: BatshSpacing.md + 2),
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
      ),
    );
  }
}

// ─── Background ──────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.onLoginTap, required this.disableMotion});
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
            Icon(
              Icons.lock_outline,
              size: BatshIconSize.xs,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.dataSecure,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.gutter),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${context.l10n.loginPrompt} ',
              style: BatshTypography.bodyMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            GestureDetector(
              onTap: onLoginTap,
              child: Text(
                context.l10n.loginAction,
                style: BatshTypography.bodyMd.copyWith(
                  color: context.colorScheme.primary,
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
        .fadeIn(duration: 500.ms, delay: 1420.ms, curve: BatshMotion.easeOut)
        .slideY(
          begin: 0.5,
          end: 0,
          duration: 500.ms,
          delay: 1420.ms,
          curve: BatshMotion.easeOut,
        );
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
        borderRadius: BatshRadius.brLg,
        boxShadow: BatshShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.debugMode,
            textAlign: TextAlign.center,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          BatshButton(
            label: context.l10n.demoLoginHomeowner,
            style: BatshButtonStyle.secondary,
            onPressed: _busy ? null : () => _signInAs('homeowner@batsh.demo'),
            isLoading: _busy,
          ),
          const SizedBox(height: BatshSpacing.sm),
          BatshButton(
            label: context.l10n.demoLoginContractor,
            style: BatshButtonStyle.secondary,
            onPressed: _busy ? null : () => _signInAs('contractor@batsh.demo'),
          ),
          if (_error != null) ...[
            const SizedBox(height: BatshSpacing.sm),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: BatshTypography.labelMd.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
