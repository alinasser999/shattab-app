import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_text_field.dart';
import '../providers/onboarding_provider.dart';

class ExperienceScreen extends ConsumerStatefulWidget {
  const ExperienceScreen({super.key});

  @override
  ConsumerState<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends ConsumerState<ExperienceScreen> {
  final TextEditingController _yearsCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  bool _hydrated = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _yearsCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final years = int.tryParse(_yearsCtrl.text.trim());
    final bio = _bioCtrl.text.trim();
    if (years == null || years < 0 || years > 80) {
      setState(() => _error = 'سنين خبرة غير صحيحة');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final controller = ref.read(onboardingControllerProvider.notifier);
      await controller.setExperienceAndBio(yearsExperience: years, bio: bio);
      await controller.markComplete();
      if (!mounted) return;
      context.go(Routes.contractorDashboard);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(contractorProfileProvider).value;
    if (!_hydrated && existing != null) {
      if (existing.yearsExperience != null) {
        _yearsCtrl.text = '${existing.yearsExperience}';
      }
      if (existing.bio != null) _bioCtrl.text = existing.bio!;
      _hydrated = true;
    }
    final isMobile = context.isMobile;

    return BatshScaffold(
      title: S.experienceTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            Text(
              S.experienceTitle,
              style: isMobile
                  ? BatshTypography.headlineLgMobile
                  : BatshTypography.headlineLg,
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshTextField(
              controller: _yearsCtrl,
              label: S.yearsExperience,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              errorText: _error,
            ),
            const SizedBox(height: BatshSpacing.gutter),
            BatshTextField(
              controller: _bioCtrl,
              label: S.bioLabel,
              hint: S.bioHint,
              maxLines: 4,
              maxLength: 400,
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.done,
              onPressed: _busy ? null : _finish,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ],
        ),
      ),
    );
  }
}
