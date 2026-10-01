import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../domain/onboarding_models.dart';
import '../providers/onboarding_draft_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_header.dart';

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
  bool _showErrors = false;
  String? _saveError;
  final FocusNode _cityFocus = FocusNode(debugLabel: 'homeowner city');
  final FocusNode _districtFocus = FocusNode(debugLabel: 'homeowner district');

  @override
  void dispose() {
    _cityFocus.dispose();
    _districtFocus.dispose();
    super.dispose();
  }

  void _back() => context.go(Routes.onboardingHomeownerDetails);

  List<String> get _districts {
    if (_selectedCity == null) return const [];
    for (final entry in OnboardingCatalog.citiesAndDistricts) {
      if (entry.city == _selectedCity) return entry.districts;
    }
    return const [];
  }

  void _selectCity(String city) {
    if (_selectedCity == city) return;
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _saveError = null;
    });
    ref
        .read(onboardingDraftProvider.notifier)
        .updateHomeownerLocation(city: city, clearDistrict: true);
  }

  void _selectDistrict(String district) {
    setState(() {
      _selectedDistrict = district;
      _saveError = null;
    });
    ref
        .read(onboardingDraftProvider.notifier)
        .updateHomeownerLocation(city: _selectedCity, district: district);
  }

  bool get _hasSupportedPair =>
      _selectedCity != null && _districts.contains(_selectedDistrict);

  Future<void> _complete() async {
    setState(() {
      _showErrors = true;
      _saveError = null;
    });
    if (_selectedCity == null) {
      FocusScope.of(context).requestFocus(_cityFocus);
      return;
    }
    if (!_hasSupportedPair) {
      FocusScope.of(context).requestFocus(_districtFocus);
      return;
    }

    final city = _selectedCity!;
    final district = _selectedDistrict!;
    setState(() => _busy = true);
    try {
      final controller = ref.read(onboardingControllerProvider.notifier);
      await controller.setHomeownerLocation(city: city, district: district);
      await controller.markComplete();
      if (!mounted) return;
      context.go(Routes.homeownerDiscover);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saveError = ErrorMapper.map(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeownerAsync = ref.watch(homeownerProfileProvider);
    final existing = homeownerAsync.value;
    final draft = ref.watch(onboardingDraftProvider);
    if (!_hydrated && !homeownerAsync.isLoading && existing != null) {
      if (draft.homeownerLocationEdited) {
        _selectedCity = draft.city;
        _selectedDistrict = draft.district;
      } else {
        _selectedCity = existing.city;
        _selectedDistrict = existing.district;
      }
      _hydrated = true;
    } else if (!_hydrated && !homeownerAsync.isLoading && existing == null) {
      _selectedCity = draft.city;
      _selectedDistrict = draft.district;
      _hydrated = true;
    }

    final stepBody = homeownerAsync.hasError
        ? BatshError(
            message: ErrorMapper.map(homeownerAsync.error!),
            onRetry: () => ref.invalidate(homeownerProfileProvider),
          )
        : homeownerAsync.isLoading
        ? const BatshSkeletonRegion(
            child: BatshListSkeleton(count: 2, height: 72),
          )
        : _form(context);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: BatshScaffold(
        title: context.l10n.locationTitle,
        animateEntrance: false,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingProgressHeader(
                step: 3,
                stepLabel: context.l10n.onboardingStepHomeownerLocation,
                onBack: _back,
              ),
              const SizedBox(height: BatshSpacing.lg),
              stepBody,
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.l10n.cityLabel,
        style: BatshTypography.labelMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: BatshSpacing.sm),
      Focus(
        focusNode: _cityFocus,
        child: Semantics(
          container: true,
          focusable: true,
          label: context.l10n.cityLabel,
          child: Wrap(
            spacing: BatshSpacing.sm,
            runSpacing: BatshSpacing.sm,
            children: OnboardingCatalog.citiesAndDistricts
                .map(
                  (entry) => BatshChip(
                    label: localizedOnboardingCityLabel(context, entry.city),
                    selected: _selectedCity == entry.city,
                    semanticLabel: localizedOnboardingCityLabel(
                      context,
                      entry.city,
                    ),
                    minimumHitHeight: true,
                    singleSelection: true,
                    showSelectionMark: true,
                    onTap: _busy ? null : () => _selectCity(entry.city),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      if (_showErrors && _selectedCity == null) ...[
        const SizedBox(height: BatshSpacing.sm),
        _InlineError(message: context.l10n.onboardingCityRequired),
      ],
      if (_selectedCity != null) ...[
        const SizedBox(height: BatshSpacing.lg),
        Text(
          context.l10n.districtLabel,
          style: BatshTypography.labelMd.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        Focus(
          focusNode: _districtFocus,
          child: Semantics(
            container: true,
            focusable: true,
            label: context.l10n.districtLabel,
            child: Wrap(
              spacing: BatshSpacing.sm,
              runSpacing: BatshSpacing.sm,
              children: _districts
                  .map(
                    (district) => BatshChip(
                      label: localizedOnboardingDistrictLabel(
                        context,
                        district,
                      ),
                      selected: _selectedDistrict == district,
                      semanticLabel: localizedOnboardingDistrictLabel(
                        context,
                        district,
                      ),
                      minimumHitHeight: true,
                      singleSelection: true,
                      showSelectionMark: true,
                      onTap: _busy ? null : () => _selectDistrict(district),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (_showErrors && !_hasSupportedPair) ...[
          const SizedBox(height: BatshSpacing.sm),
          _InlineError(message: context.l10n.onboardingDistrictRequired),
        ],
      ],
      if (_saveError != null) ...[
        const SizedBox(height: BatshSpacing.md),
        _InlineError(message: _saveError!),
      ],
      if (_busy) ...[
        const SizedBox(height: BatshSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            context.l10n.onboardingSaving,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
      const SizedBox(height: BatshSpacing.xl),
      BatshButton(
        label: context.l10n.done,
        onPressed: _busy ? null : _complete,
        isLoading: _busy,
        animate: false,
      ),
      const SizedBox(height: BatshSpacing.lg),
    ],
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: BatshTypography.bodySm.copyWith(color: context.colorScheme.error),
    ),
  );
}
