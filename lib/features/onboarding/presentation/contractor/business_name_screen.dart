import 'package:flutter/material.dart';
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
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class BusinessNameScreen extends ConsumerStatefulWidget {
  const BusinessNameScreen({super.key});

  @override
  ConsumerState<BusinessNameScreen> createState() =>
      _BusinessNameScreenState();
}

class _BusinessNameScreenState extends ConsumerState<BusinessNameScreen> {
  final TextEditingController _bizCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  bool _hydrated = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _bizCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final biz = _bizCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (biz.length < 2 || name.length < 2) {
      setState(() => _error = 'املا الحقلين');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .setBusinessName(businessName: biz, displayName: name);
      if (!mounted) return;
      context.go(Routes.onboardingContractorSpecialties);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(contractorProfileProvider).value;
    final profile = ref.watch(currentProfileProvider).value;
    if (!_hydrated) {
      if (existing?.businessName != null) {
        _bizCtrl.text = existing!.businessName!;
      }
      if (profile?.fullName.isNotEmpty ?? false) {
        _nameCtrl.text = profile!.fullName;
      }
      _hydrated = true;
    }
    final isMobile = context.isMobile;

    return BatshScaffold(
      title: S.businessNameTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            Text(
              S.businessNameTitle,
              style: isMobile
                  ? BatshTypography.headlineLgMobile
                  : BatshTypography.headlineLg,
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshTextField(
              controller: _bizCtrl,
              label: S.businessNameTitle,
              hint: S.businessNameHint,
            ),
            const SizedBox(height: BatshSpacing.gutter),
            BatshTextField(
              controller: _nameCtrl,
              label: S.displayNameLabel,
              errorText: _error,
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.next,
              onPressed: _busy ? null : _next,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ],
        ),
      ),
    );
  }
}
