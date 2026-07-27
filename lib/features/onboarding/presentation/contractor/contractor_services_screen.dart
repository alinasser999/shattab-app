import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_section_header.dart';
import '../../domain/onboarding_models.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/widgets/batsh_snack.dart';

class ContractorServicesScreen extends ConsumerStatefulWidget {
  const ContractorServicesScreen({super.key});

  @override
  ConsumerState<ContractorServicesScreen> createState() =>
      _ContractorServicesScreenState();
}

class _ContractorServicesScreenState
    extends ConsumerState<ContractorServicesScreen> {
  Set<String> _specialties = {};
  Set<String> _areas = {};
  bool _hydrated = false;
  bool _busy = false;

  static const Map<String, IconData> _specialtyIcons = {
    'paint': Icons.format_paint_outlined,
    'flooring': Icons.layers_outlined,
    'kitchen': Icons.countertops_outlined,
    'bathroom': Icons.bathtub_outlined,
    'electrical': Icons.electrical_services_outlined,
    'plumbing': Icons.plumbing_outlined,
    'carpentry': Icons.carpenter_outlined,
    'design': Icons.design_services_outlined,
    'full_reno': Icons.home_repair_service_outlined,
  };

  Future<void> _next() async {
    if (_specialties.isEmpty || _areas.isEmpty) return;
    // Snapshot before any await: the upsert invalidates
    // contractorProfileProvider, which reruns build() mid-submit.
    final specialties = _specialties.toList();
    final areas = _areas.toList();
    setState(() => _busy = true);
    try {
      final ctrl = ref.read(onboardingControllerProvider.notifier);
      await ctrl.saveContractorServices(
        specialties: specialties,
        serviceAreas: areas,
      );
      if (!mounted) return;
      context.go(Routes.onboardingContractorExperience);
    } catch (e) {
      if (!mounted) return;
      BatshSnack.error(context, ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(contractorProfileProvider).value;
    if (!_hydrated && !_busy && existing != null) {
      _specialties = existing.specialties.toSet();
      _areas = existing.serviceAreas.toSet();
      _hydrated = true;
    }
    return BatshScaffold(
      title: S.specialtiesTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            BatshSectionHeader(title: S.specialtiesTitle),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              S.specialtiesSubtitle,
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant),
            ),
            const SizedBox(height: BatshSpacing.md),
            Wrap(
              spacing: BatshSpacing.sm,
              runSpacing: BatshSpacing.sm,
              children: OnboardingCatalog.specialtiesCatalog.entries
                  .map(
                    (e) => BatshChip(
                      label: e.value,
                      icon: _specialtyIcons[e.key],
                      selected: _specialties.contains(e.key),
                      onTap: () => setState(() {
                        if (_specialties.contains(e.key)) {
                          _specialties.remove(e.key);
                        } else {
                          _specialties.add(e.key);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshSectionHeader(title: S.serviceAreasTitle),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              S.serviceAreasSubtitle,
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant),
            ),
            const SizedBox(height: BatshSpacing.md),
            Wrap(
              spacing: BatshSpacing.sm,
              runSpacing: BatshSpacing.sm,
              children: OnboardingCatalog.citiesAndDistricts
                  .map(
                    (entry) => BatshChip(
                      label: entry.city,
                      selected: _areas.contains(entry.city),
                      onTap: () => setState(() {
                        if (_areas.contains(entry.city)) {
                          _areas.remove(entry.city);
                        } else {
                          _areas.add(entry.city);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.next,
              onPressed: _specialties.isEmpty || _areas.isEmpty || _busy
                  ? null
                  : _next,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ].animate(interval: 60.ms).fadeIn(
            duration: BatshMotion.slow,
            curve: BatshMotion.easeOut,
          ).slideY(
            begin: 0.08,
            end: 0,
            curve: BatshMotion.easeOut,
          ),
        ),
      ),
    );
  }
}
