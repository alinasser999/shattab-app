import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/utils/phone_number_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../data/auth_repository.dart';
import '../domain/assistant_reauthentication_request.dart';
import '../domain/profile.dart';
import 'providers/auth_provider.dart';
import '../../assistant/presentation/providers/assistant_providers.dart';

/// Opaque, challenge-gated existing-account recovery for one assistant turn.
class AssistantReauthenticationScreen extends ConsumerStatefulWidget {
  const AssistantReauthenticationScreen({super.key, required this.request});

  final AssistantReauthenticationRequest request;

  @override
  ConsumerState<AssistantReauthenticationScreen> createState() =>
      _AssistantReauthenticationScreenState();
}

class _AssistantReauthenticationScreenState
    extends ConsumerState<AssistantReauthenticationScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _mismatch = false;
  bool _showForm = true;
  String? _phoneError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    AssistantReauthenticationChallenges.clear(widget.request);
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!AssistantReauthenticationChallenges.isActive(widget.request) ||
        !widget.request.isValid) {
      _setFormError();
      return;
    }
    final phone = normalizeEgyptPhone(_phoneController.text);
    final password = _passwordController.text;
    setState(() {
      _phoneError = Validators.isEgyptianPhone(phone)
          ? null
          : context.l10n.invalidPhone;
      _passwordError = password.length >= 6
          ? null
          : context.l10n.passwordTooShort;
      _formError = null;
    });
    if (_phoneError != null || _passwordError != null) return;

    setState(() => _busy = true);
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .signInWithPhonePassword(phone: phone, password: password);
      final returnedSession = response.session;
      final returnedUserId = returnedSession?.user.id;
      if (returnedSession == null ||
          returnedUserId == null ||
          (response.user != null && response.user!.id != returnedUserId)) {
        _setFormError();
        return;
      }
      if (!mounted) {
        return;
      }
      if (returnedUserId != widget.request.originalUserId) {
        setState(() {
          _mismatch = true;
          _showForm = false;
        });
        return;
      }

      final activeUserId = await _waitForActiveSession(returnedUserId);
      if (activeUserId != widget.request.originalUserId) {
        if (activeUserId != null) {
          setState(() {
            _mismatch = true;
            _showForm = false;
          });
        } else {
          _setFormError();
        }
        return;
      }

      await ref.read(currentProfileProvider.notifier).refresh();
      if (!mounted) return;
      final profile = ref.read(currentProfileProvider).asData?.value;
      if (profile == null ||
          profile.id != widget.request.originalUserId ||
          profile.role != widget.request.expectedRole ||
          !profile.roleSelectionLocked) {
        setState(() {
          _mismatch = true;
          _showForm = false;
        });
        return;
      }

      final confirmed = ref
          .read(assistantChatProvider.notifier)
          .confirmReauthentication(
            userId: widget.request.originalUserId,
            role: profile.role.name,
            failedTurnId: widget.request.failedTurnId,
          );
      if (!confirmed) {
        _setFormError();
        return;
      }

      if (!mounted) return;
      context.pop(
        AssistantReauthenticationOutcome(
          originalUserId: widget.request.originalUserId,
          expectedRole: widget.request.expectedRole,
          assistantRoute: widget.request.assistantRoute,
          failedTurnId: widget.request.failedTurnId,
        ),
      );
    } catch (_) {
      _setFormError();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _waitForActiveSession(String expectedUserId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(deadline)) {
      final session = ref.read(currentSessionProvider);
      if (session?.user.id == expectedUserId) return session!.user.id;
      if (session != null && session.user.id != widget.request.originalUserId) {
        return session.user.id;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return ref.read(currentSessionProvider)?.user.id;
  }

  void _setFormError() {
    if (mounted) {
      setState(() => _formError = context.l10n.assistantReauthFailed);
    }
  }

  void _discardQuestion() {
    ref.read(assistantChatProvider.notifier).clearChat();
    AssistantReauthenticationChallenges.clear(widget.request);
    final session = ref.read(currentSessionProvider);
    final profile = ref.read(currentProfileProvider).asData?.value;
    final String destination;
    if (session == null) {
      destination = Routes.homeownerHome;
    } else if (profile == null || profile.id != session.user.id) {
      destination = Routes.splash;
    } else {
      destination = profile.role == UserRole.homeowner
          ? Routes.homeownerHome
          : Routes.contractorDashboard;
    }
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final identityChanged =
        session != null && session.user.id != widget.request.originalUserId;
    final lockedMismatch = _mismatch || identityChanged;
    return PopScope(
      canPop: !lockedMismatch && !_busy,
      child: BatshScaffold(
        title: context.l10n.assistantReauthTitle,
        leading: lockedMismatch
            ? const SizedBox(width: BatshSpacing.xxxl)
            : IconButton(
                tooltip: context.l10n.cancel,
                onPressed: _busy ? null : () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        padding: const EdgeInsets.all(BatshSpacing.lg),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                lockedMismatch
                    ? context.l10n.assistantReauthMismatchMessage
                    : context.l10n.assistantReauthMessage,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: BatshSpacing.lg),
              if (lockedMismatch && !_showForm) ...[
                BatshButton(
                  label: context.l10n.assistantReauthTryOriginal,
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _showForm = true;
                          _formError = null;
                        }),
                ),
                const SizedBox(height: BatshSpacing.sm),
                BatshButton(
                  label: context.l10n.assistantReauthDiscard,
                  style: BatshButtonStyle.ghost,
                  onPressed: _busy ? null : _discardQuestion,
                ),
              ] else ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [LocalizedDigitsOnlyFormatter()],
                  decoration: InputDecoration(
                    labelText: context.l10n.phoneLabel,
                    hintText: context.l10n.phoneLocalHint,
                    prefixText: '+20 ',
                    errorText: _phoneError,
                  ),
                ),
                const SizedBox(height: BatshSpacing.md),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: context.l10n.passwordLabel,
                    hintText: context.l10n.passwordHint,
                    errorText: _passwordError,
                  ),
                  onSubmitted: (_) => _busy ? null : _submit(),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: BatshSpacing.sm),
                  Text(
                    _formError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: BatshSpacing.lg),
                BatshButton(
                  label: context.l10n.assistantSignInAgain,
                  isLoading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
                if (lockedMismatch) ...[
                  const SizedBox(height: BatshSpacing.sm),
                  BatshButton(
                    label: context.l10n.assistantReauthDiscard,
                    style: BatshButtonStyle.ghost,
                    onPressed: _busy ? null : _discardQuestion,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
