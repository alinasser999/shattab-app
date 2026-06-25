import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../domain/onboarding_models.dart';
import '../providers/onboarding_provider.dart';

class SpecialtiesScreen extends ConsumerStatefulWidget {
  const SpecialtiesScreen({super.key});

  @override
  ConsumerState<SpecialtiesScreen> createState() => _SpecialtiesScreenState();
}

class _SpecialtiesScreenState extends ConsumerState<SpecialtiesScreen> {
  Set<String> _selected = {};
  bool _hydrated = false;
  bool _busy = false;

  Future<void> _next() async {
    if (_selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .setSpecialties(_selected.toList());
      if (!mounted) return;
      context.go(Routes.onboardingContractorAreas);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(contractorProfileProvider).value;
    if (!_hydrated && existing != null) {
      _selected = existing.specialties.toSet();
      _hydrated = true;
    }
    final isMobile = context.isMobile;

    return BatshScaffold(
      title: S.specialtiesTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            Text(
              S.specialtiesTitle,
              style: isMobile
                  ? BatshTypography.headlineLgMobile
                  : BatshTypography.headlineLg,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              S.specialtiesSubtitle,
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant),
            ),
            const SizedBox(height: BatshSpacing.lg),
            Wrap(
              spacing: BatshSpacing.sm,
              runSpacing: BatshSpacing.sm,
              children: OnboardingCatalog.specialtiesCatalog.entries
                  .map(
                    (e) => BatshChip(
                      label: e.value,
                      selected: _selected.contains(e.key),
                      onTap: () => setState(() {
                        if (_selected.contains(e.key)) {
                          _selected.remove(e.key);
                        } else {
                          _selected.add(e.key);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.next,
              onPressed: _selected.isEmpty || _busy ? null : _next,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ],
        ),
      ),
    );
  }
}
