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

class ServiceAreasScreen extends ConsumerStatefulWidget {
  const ServiceAreasScreen({super.key});

  @override
  ConsumerState<ServiceAreasScreen> createState() => _ServiceAreasScreenState();
}

class _ServiceAreasScreenState extends ConsumerState<ServiceAreasScreen> {
  Set<String> _selected = {};
  bool _hydrated = false;
  bool _busy = false;

  Future<void> _next() async {
    if (_selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .setServiceAreas(_selected.toList());
      if (!mounted) return;
      context.go(Routes.onboardingContractorLogo);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(contractorProfileProvider).value;
    if (!_hydrated && existing != null) {
      _selected = existing.serviceAreas.toSet();
      _hydrated = true;
    }
    final isMobile = context.isMobile;

    return BatshScaffold(
      title: S.serviceAreasTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            Text(
              S.serviceAreasTitle,
              style: isMobile
                  ? BatshTypography.headlineLgMobile
                  : BatshTypography.headlineLg,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              S.serviceAreasSubtitle,
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant),
            ),
            const SizedBox(height: BatshSpacing.lg),
            Wrap(
              spacing: BatshSpacing.sm,
              runSpacing: BatshSpacing.sm,
              children: OnboardingCatalog.citiesAndDistricts
                  .map(
                    (entry) => BatshChip(
                      label: entry.city,
                      selected: _selected.contains(entry.city),
                      onTap: () => setState(() {
                        if (_selected.contains(entry.city)) {
                          _selected.remove(entry.city);
                        } else {
                          _selected.add(entry.city);
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
