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

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  String? _selectedCity;
  String? _selectedDistrict;
  bool _busy = false;

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
      context.go(Routes.onboardingHomeownerInterests);
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
    _selectedCity ??= existing?.city;
    _selectedDistrict ??= existing?.district;
    final isMobile = context.isMobile;

    return BatshScaffold(
      title: S.locationTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            Text(
              S.locationTitle,
              style: isMobile
                  ? BatshTypography.headlineLgMobile
                  : BatshTypography.headlineLg,
            ),
            const SizedBox(height: BatshSpacing.lg),
            Text(S.cityLabel,
                style: BatshTypography.labelMd
                    .copyWith(color: BatshColors.onSurfaceVariant)),
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
              Text(S.districtLabel,
                  style: BatshTypography.labelMd
                      .copyWith(color: BatshColors.onSurfaceVariant)),
              const SizedBox(height: BatshSpacing.sm),
              Wrap(
                spacing: BatshSpacing.sm,
                runSpacing: BatshSpacing.sm,
                children: _districts
                    .map(
                      (d) => BatshChip(
                        label: d,
                        selected: _selectedDistrict == d,
                        onTap: () => setState(() => _selectedDistrict = d),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.next,
              onPressed: (_selectedCity == null ||
                      _selectedDistrict == null ||
                      _busy)
                  ? null
                  : _next,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ],
        ),
      ),
    );
  }
}
