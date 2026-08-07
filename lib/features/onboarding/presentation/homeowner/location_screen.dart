import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../domain/onboarding_models.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/widgets/batsh_snack.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  String? _selectedCity;
  String? _selectedDistrict;
  bool _busy = false;
  bool _hydrated = false;

  Future<void> _next() async {
    if (_selectedCity == null || _selectedDistrict == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .setHomeownerLocation(
            city: _selectedCity!,
            district: _selectedDistrict!,
          );
      if (!mounted) return;
      await ref.read(onboardingControllerProvider.notifier).markComplete();
      if (!mounted) return;
      context.go(Routes.homeownerDiscover);
    } catch (e) {
      if (!mounted) return;
      BatshSnack.error(context, ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> get _districts {
    if (_selectedCity == null) return const [];
    final entry = OnboardingCatalog.citiesAndDistricts.firstWhere(
      (c) => c.city == _selectedCity,
      orElse: () => (city: '', districts: const <String>[]),
    );
    return entry.districts;
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(homeownerProfileProvider).value;
    // Hydrate once: re-running `??=` every build resurrects the saved
    // district after the user picks a new city (which clears it), letting a
    // mismatched city/district pair pass validation.
    if (!_hydrated && existing != null) {
      _selectedCity ??= existing.city;
      _selectedDistrict ??= existing.district;
      _hydrated = true;
    }
    return BatshScaffold(
      title: context.l10n.locationTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:
              [
                    const SizedBox(height: BatshSpacing.md),
                    Text(
                      context.l10n.cityLabel,
                      style: BatshTypography.labelMd.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.sm),
                    Wrap(
                      spacing: BatshSpacing.sm,
                      runSpacing: BatshSpacing.sm,
                      children: OnboardingCatalog.citiesAndDistricts
                          .map(
                            (entry) => BatshChip(
                              label: entry.city,
                              selected: _selectedCity == entry.city,
                              onTap: () => setState(() {
                                _selectedCity = entry.city;
                                _selectedDistrict = null;
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    if (_districts.isNotEmpty) ...[
                      const SizedBox(height: BatshSpacing.lg),
                      Text(
                        context.l10n.districtLabel,
                        style: BatshTypography.labelMd.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.sm),
                      Wrap(
                        spacing: BatshSpacing.sm,
                        runSpacing: BatshSpacing.sm,
                        children: _districts
                            .map(
                              (d) => BatshChip(
                                label: d,
                                selected: _selectedDistrict == d,
                                onTap: () =>
                                    setState(() => _selectedDistrict = d),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: BatshSpacing.xl),
                    BatshButton(
                      label: context.l10n.next,
                      onPressed:
                          (_selectedCity == null ||
                              _selectedDistrict == null ||
                              _busy)
                          ? null
                          : _next,
                      isLoading: _busy,
                    ),
                    const SizedBox(height: BatshSpacing.lg),
                  ]
                  .animate(interval: 60.ms)
                  .fadeIn(
                    duration: BatshMotion.slow,
                    curve: BatshMotion.easeOut,
                  )
                  .slideY(begin: 0.08, end: 0, curve: BatshMotion.easeOut),
        ),
      ),
    );
  }
}
