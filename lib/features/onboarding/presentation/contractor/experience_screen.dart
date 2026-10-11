import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/professional_reference_theme.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/professional_reference_primitives.dart';
import '../../../../core/widgets/professional_reference_states.dart';
import '../providers/onboarding_provider.dart';

class ExperienceScreen extends ConsumerStatefulWidget {
  const ExperienceScreen({super.key});

  @override
  ConsumerState<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends ConsumerState<ExperienceScreen> {
  final TextEditingController _yearsCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final FocusNode _yearsFocus = FocusNode(debugLabel: 'years of experience');
  bool _hydrated = false;
  bool _busy = false;
  String? _yearsError;
  String? _saveError;

  @override
  void dispose() {
    _yearsCtrl.dispose();
    _bioCtrl.dispose();
    _yearsFocus.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final years = int.tryParse(_yearsCtrl.text.trim());
    final bio = _bioCtrl.text.trim();
    if (years == null || years < 0 || years > 80) {
      setState(() {
        _yearsError = context.l10n.yearsExperienceInvalid;
        _saveError = null;
      });
      FocusScope.of(context).requestFocus(_yearsFocus);
      return;
    }
    setState(() {
      _busy = true;
      _yearsError = null;
      _saveError = null;
    });
    try {
      final controller = ref.read(onboardingControllerProvider.notifier);
      await controller.setExperienceAndBio(yearsExperience: years, bio: bio);
      await controller.markComplete();
      if (!mounted) return;
      context.go(Routes.contractorDashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveError = ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(contractorProfileProvider).value;
    if (!_hydrated && !_busy && existing != null) {
      if (existing.yearsExperience != null) {
        _yearsCtrl.text = '${existing.yearsExperience}';
      }
      if (existing.bio != null) _bioCtrl.text = existing.bio!;
      _hydrated = true;
    }
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BatshSpacing.md),
        ProfessionalReferenceWelcome(
          title: context.l10n.experienceTitle,
          message: context.l10n.bioHint,
          motif: ProfessionalReferenceMotif.portfolio,
        ),
        ProfessionalReferenceTextField(
          controller: _yearsCtrl,
          focusNode: _yearsFocus,
          label: context.l10n.yearsExperience,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          errorText: _yearsError,
          enabled: !_busy,
          onChanged: (_) {
            setState(() {
              _yearsError = null;
              _saveError = null;
            });
          },
        ),
        const SizedBox(height: BatshSpacing.gutter),
        ProfessionalReferenceTextField(
          controller: _bioCtrl,
          label: context.l10n.bioLabel,
          hint: context.l10n.bioHint,
          maxLines: 4,
          maxLength: 400,
          enabled: !_busy,
          onChanged: (_) => setState(() => _saveError = null),
        ),
        if (_saveError != null) ...[
          const SizedBox(height: BatshSpacing.md),
          ProfessionalReferenceInlineStatus(
            message: '${context.l10n.onboardingSaveFailed} $_saveError',
            retryLabel: context.l10n.onboardingRetrySave,
            onRetry: _finish,
          ),
        ],
        const SizedBox(height: BatshSpacing.xl),
        ProfessionalReferencePrimaryButton(
          label: context.l10n.done,
          onPressed: _busy ? null : _finish,
          isLoading: _busy,
        ),
        const SizedBox(height: BatshSpacing.lg),
      ],
    );
    final content = MediaQuery.disableAnimationsOf(context)
        ? form
        : form
              .animate()
              .fadeIn(duration: BatshMotion.slow, curve: BatshMotion.easeOut)
              .slideY(begin: 0.08, end: 0, curve: BatshMotion.easeOut);
    return Theme(
      data: ProfessionalReferenceTheme.scopedTheme(Theme.of(context)),
      child: BatshScaffold(
        title: context.l10n.experienceTitle,
        animateEntrance: false,
        body: SingleChildScrollView(child: content),
      ),
    );
  }
}
