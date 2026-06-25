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

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  Set<String> _selected = {};
  bool _busy = false;
  bool _hydrated = false;

  Future<void> _finish() async {
    if (_selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      final controller = ref.read(onboardingControllerProvider.notifier);
      await controller.setHomeownerInterests(_selected.toList());
      await controller.markComplete();
      if (!mounted) return;
      // Router will redirect to homeowner shell once profile state updates.
      context.go(Routes.homeownerDiscover);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(homeownerProfileProvider).value;
    if (!_hydrated && existing != null) {
      _selected = existing.renovationInterests.toSet();
      _hydrated = true;
    }
    final isMobile = context.isMobile;

    return BatshScaffold(
      title: S.interestsTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            Text(
              S.interestsTitle,
              style: isMobile
                  ? BatshTypography.headlineLgMobile
                  : BatshTypography.headlineLg,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              S.interestsSubtitle,
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant),
            ),
            const SizedBox(height: BatshSpacing.lg),
            Wrap(
              spacing: BatshSpacing.sm,
              runSpacing: BatshSpacing.sm,
              children: OnboardingCatalog.interestsCatalog.entries
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
              label: S.done,
              onPressed: _selected.isEmpty || _busy ? null : _finish,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ],
        ),
      ),
    );
  }
}
