part of 'phone_entry_screen.dart';

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
  final _passwordFocus = FocusNode();
  final _confirmController = TextEditingController();
  final _confirmFocus = FocusNode();
  bool _isSignUp = false;
  bool _obscure = true;
  bool _busy = false;
  bool _phoneFocused = false;
  bool _passwordFocused = false;
  bool _confirmFocused = false;
  // Errors are per-field so a wrong password never reddens the phone box.
  // _formError holds auth/server failures that don't belong to one field.
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    widget.phoneFocus.addListener(_onPhoneFocus);
    _passwordFocus.addListener(_onPasswordFocus);
    _confirmFocus.addListener(_onConfirmFocus);
  }

  void _onPhoneFocus() {
    if (mounted) setState(() => _phoneFocused = widget.phoneFocus.hasFocus);
  }

  void _onPasswordFocus() {
    if (mounted) setState(() => _passwordFocused = _passwordFocus.hasFocus);
  }

  void _onConfirmFocus() {
    if (mounted) setState(() => _confirmFocused = _confirmFocus.hasFocus);
  }

  void _clearErrors() {
    _phoneError = null;
    _passwordError = null;
    _confirmError = null;
    _formError = null;
  }

  Widget _errorRow(String message) => Padding(
    padding: const EdgeInsets.only(top: BatshSpacing.xs),
    child: Row(
      children: [
        Icon(
          Icons.error_outline,
          size: BatshIconSize.sm,
          color: BatshColors.error,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: BatshTypography.labelMd.copyWith(color: BatshColors.error),
          ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    widget.phoneFocus.removeListener(_onPhoneFocus);
    _passwordFocus.removeListener(_onPasswordFocus);
    _confirmFocus.removeListener(_onConfirmFocus);
    _passwordController.dispose();
    _passwordFocus.dispose();
    _confirmController.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = normalizeEgyptPhoneToE164(widget.phoneController.text);
    final password = _passwordController.text;
    setState(_clearErrors);
    if (!Validators.isEgyptianPhone(phone)) {
      setState(() => _phoneError = S.invalidPhone);
      return;
    }
    if (password.length < 6) {
      setState(() => _passwordError = S.passwordTooShort);
      return;
    }
    // Confirm-password guard only in sign-up. A typo here would otherwise lock
    // the user out and push them to the SMS-costing forgot-password path.
    if (_isSignUp && _confirmController.text != password) {
      setState(() => _confirmError = S.passwordMismatch);
      return;
    }
    setState(() => _busy = true);
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
      setState(() => _formError = ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _clearErrors();
      _busy = true;
    });
    try {
      // On web this redirects the page; the finally below may not run before
      // navigation, which is fine.
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apple() async {
    setState(() {
      _clearErrors();
      _busy = true;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parent surfaces phone-level errors from the forgot-password flow.
    final phoneError = _phoneError ?? widget.phoneErrorText;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.lg,
        vertical: BatshSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BatshRadius.brXxl,
        border: Border.all(
          color: BatshColors.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode switch — tactile segmented control up front, not a buried link.
          _AuthSegment(
            isSignUp: _isSignUp,
            onChanged: (v) => setState(() {
              _isSignUp = v;
              _clearErrors();
            }),
          ),
          const SizedBox(height: BatshSpacing.lg),
          // Apple first on Apple platforms: guideline 4.8 requires the
          // privacy-preserving option to be presented no less prominently than
          // the other third-party logins.
          if (_isApplePlatform) ...[
            _AppleButton(onPressed: _busy ? null : _apple),
            const SizedBox(height: BatshSpacing.sm),
          ],
          // Google — fastest path, free, no SMS.
          _GoogleButton(onPressed: _busy ? null : _google),
          const SizedBox(height: BatshSpacing.md),
          Row(
            children: [
              const Expanded(child: Divider(color: BatshColors.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.md,
                ),
                child: Text(
                  S.orDivider,
                  style: BatshTypography.labelSm.copyWith(
                    color: BatshColors.onSurfaceVariant,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: BatshColors.outlineVariant)),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          // Phone
          _FieldShell(
            focused: _phoneFocused,
            hasError: phoneError != null,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    height: 54,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: BatshColors.outlineVariant),
                      ),
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
                      ],
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.phoneController,
                      focusNode: widget.phoneFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      style: BatshTypography.bodyLg.copyWith(
                        color: BatshColors.onSurface,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: S.phoneLocalHint,
                        hintStyle: BatshTypography.bodyLg.copyWith(
                          color: BatshColors.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        border: InputBorder.none,
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
          if (phoneError != null) _errorRow(phoneError),
          const SizedBox(height: BatshSpacing.md),
          // Password
          _FieldShell(
            focused: _passwordFocused,
            hasError: _passwordError != null,
            child: Row(
              children: [
                const SizedBox(width: BatshSpacing.md),
                Icon(
                  Icons.lock_outline,
                  size: BatshIconSize.md,
                  color: BatshColors.onSurfaceVariant,
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscure,
                    textInputAction: _isSignUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    autofillHints: _isSignUp
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    style: BatshTypography.bodyLg.copyWith(
                      color: BatshColors.onSurface,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: S.passwordHint,
                      hintStyle: BatshTypography.bodyLg.copyWith(
                        color: BatshColors.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: BatshSpacing.md,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: BatshIconSize.md,
                    color: BatshColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_passwordError != null) _errorRow(_passwordError!),
          // Confirm password — sign-up only. Catches a typo before it becomes a
          // lockout that forces the SMS-costing forgot-password path.
          if (_isSignUp) ...[
            const SizedBox(height: BatshSpacing.md),
            _FieldShell(
              focused: _confirmFocused,
              hasError: _confirmError != null,
              child: Row(
                children: [
                  const SizedBox(width: BatshSpacing.md),
                  Icon(
                    Icons.lock_outline,
                    size: BatshIconSize.md,
                    color: BatshColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: BatshSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _confirmController,
                      focusNode: _confirmFocus,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _busy ? null : _submit(),
                      autofillHints: const [AutofillHints.newPassword],
                      style: BatshTypography.bodyLg.copyWith(
                        color: BatshColors.onSurface,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: S.confirmPasswordHint,
                        hintStyle: BatshTypography.bodyLg.copyWith(
                          color: BatshColors.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: BatshSpacing.md,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_confirmError != null) _errorRow(_confirmError!),
          ],
          if (_formError != null) ...[
            const SizedBox(height: BatshSpacing.sm),
            _errorRow(_formError!),
          ],
          const SizedBox(height: BatshSpacing.lg),
          BatshButton(
            label: _isSignUp ? S.createAccountAction : S.signInAction,
            onPressed: _busy ? null : _submit,
            isLoading: _busy,
          ),
          // Forgot password (sign-in mode only) — the sole SMS path.
          if (!_isSignUp) ...[
            const SizedBox(height: BatshSpacing.xs),
            Center(
              child: TextButton(
                onPressed: widget.forgotState.isSending
                    ? null
                    : widget.onForgot,
                child: Text(
                  S.forgotPassword,
                  style: BatshTypography.labelMd.copyWith(
                    color: BatshColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (widget.disableMotion) return card;
    return card
        .animate()
        .fadeIn(duration: 550.ms, delay: 1200.ms, curve: BatshMotion.easeOut)
        .slideY(
          begin: 0.12,
          end: 0,
          duration: 600.ms,
          delay: 1200.ms,
          curve: BatshMotion.heroEase,
        )
        .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          duration: 600.ms,
          delay: 1200.ms,
          curve: BatshMotion.heroEase,
        );
  }
}

// ─── Auth Mode Segment ───────────────────────────────────────────────────────

/// Two-cell segmented control (Sign in / Create account) with a sliding
/// terracotta highlight. RTL-safe: the Row and directional alignment share the
/// same start/end axis, so the pill tracks the active cell in either direction.
class _AuthSegment extends StatelessWidget {
  const _AuthSegment({required this.isSignUp, required this.onChanged});

  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLow,
        borderRadius: BatshRadius.brLg,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - 8) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: BatshMotion.normal,
                curve: BatshMotion.easeOut,
                alignment: isSignUp
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                  width: cellWidth,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BatshColors.primary,
                    borderRadius: BatshRadius.brMd,
                    boxShadow: BatshShadows.soft,
                  ),
                ),
              ),
              Row(
                children: [
                  _cell(S.signInAction, !isSignUp, () => onChanged(false)),
                  _cell(S.createAccountAction, isSignUp, () => onChanged(true)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cell(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: BatshMotion.fast,
            style: BatshTypography.labelLg.copyWith(
              color: selected
                  ? BatshColors.onPrimary
                  : BatshColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ─── Field Shell ─────────────────────────────────────────────────────────────

/// Filled input container with a hairline border that lifts to terracotta on
/// focus and to error red when the form is invalid. Gives the plain fields a
/// tactile, non-generic focus state.
class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.child,
    required this.focused,
    required this.hasError,
  });

  final Widget child;
  final bool focused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? BatshColors.error
        : focused
        ? BatshColors.primary
        : BatshColors.outlineVariant.withValues(alpha: 0.7);
    return AnimatedContainer(
      duration: BatshMotion.fast,
      curve: BatshMotion.easeOut,
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLow,
        borderRadius: BatshRadius.brLg,
        border: Border.all(
          color: borderColor,
          width: focused || hasError ? 1.6 : 1,
        ),
      ),
      child: child,
    );
  }
}

// ─── Google Button ───────────────────────────────────────────────────────────

/// Whether to offer Sign in with Apple.
///
/// Apple requires it on its own platforms; showing it on Android would send
/// users through a web flow for no benefit when Google is already there.
bool get _isApplePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Apple's brand guidelines are prescriptive here: black fill, white logo and
/// text, full width, and the same corner radius as neighbouring buttons. A
/// restyled version is itself grounds for rejection.
class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        // Apple black, exempt from the token palette for the same reason the
        // Google 'G' is.
        color: Colors.black,
        borderRadius: BorderRadius.circular(BatshRadius.md + 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.apple,
                color: Colors.white,
                size: BatshIconSize.md,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Text(
                S.continueWithApple,
                style: BatshTypography.labelLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
