import '../../../../core/widgets/professional_reference_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/professional_reference_theme.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
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

  void _focusAndReveal(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = focusNode.context;
      if (!mounted || targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.16,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
      );
    });
  }

  bool get _hasSupportedPair =>
      _selectedCity != null && _districts.contains(_selectedDistrict);

  Future<void> _complete() async {
    setState(() {
      _showErrors = true;
      _saveError = null;
    });
    if (_selectedCity == null) {
      _focusAndReveal(_cityFocus);
      return;
    }
    if (!_hasSupportedPair) {
      _focusAndReveal(_districtFocus);
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

    return Theme(
      data: ProfessionalReferenceTheme.scopedTheme(Theme.of(context)),
      child: Builder(
        builder: (referenceContext) {
          final stepBody = homeownerAsync.hasError
              ? BatshError(
                  message: ErrorMapper.map(homeownerAsync.error!),
                  onRetry: () => ref.invalidate(homeownerProfileProvider),
                )
              : homeownerAsync.isLoading
              ? const BatshSkeletonRegion(
                  child: BatshListSkeleton(count: 2, height: 72),
                )
              : _form(referenceContext);

          return PopScope<void>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: BatshScaffold(
              title: referenceContext.l10n.locationTitle,
              titleTextStyle: ProfessionalReferenceTheme.text(
                20,
                weight: FontWeight.w700,
              ),
              animateEntrance: false,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OnboardingProgressHeader(
                            step: 3,
                            stepLabel: referenceContext
                                .l10n
                                .onboardingStepHomeownerLocation,
                            onBack: _back,
                            referenceStyle: true,
                          ),
                          const SizedBox(height: BatshSpacing.lg),
                          stepBody,
                          const SizedBox(height: BatshSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                  ProfessionalReferencePrimaryButton(
                    footerSpacing: true,
                    label: referenceContext.l10n.done,
                    onPressed:
                        _busy ||
                            homeownerAsync.isLoading ||
                            homeownerAsync.hasError
                        ? null
                        : _complete,
                    isLoading: _busy,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _form(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.l10n.cityLabel,
        style: ProfessionalReferenceTheme.text(
          16,
          color: ProfessionalReferenceTheme.navy,
          weight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: BatshSpacing.xs),
      Text(
        context.l10n.homeownerLocationHint,
        style: ProfessionalReferenceTheme.text(
          16,
          color: ProfessionalReferenceTheme.muted,
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
            children: OnboardingCatalog.citiesAndDistricts.map((entry) {
              final label = localizedOnboardingCityLabel(context, entry.city);
              return _ReferenceChoiceButton(
                label: label,
                selected: _selectedCity == entry.city,
                onPressed: _busy ? null : () => _selectCity(entry.city),
              );
            }).toList(),
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
          style: ProfessionalReferenceTheme.text(
            16,
            color: ProfessionalReferenceTheme.navy,
            weight: FontWeight.w700,
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
              children: _districts.map((district) {
                final label = localizedOnboardingDistrictLabel(
                  context,
                  district,
                );
                return _ReferenceChoiceButton(
                  label: label,
                  selected: _selectedDistrict == district,
                  onPressed: _busy ? null : () => _selectDistrict(district),
                );
              }).toList(),
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
            style: ProfessionalReferenceTheme.text(
              16,
              color: ProfessionalReferenceTheme.muted,
            ),
          ),
        ),
      ],
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
      style: ProfessionalReferenceTheme.text(
        14,
        color: context.colorScheme.error,
        weight: FontWeight.w600,
      ),
    ),
  );
}

class _ReferenceChoiceButton extends StatelessWidget {
  const _ReferenceChoiceButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final selectedColor = ProfessionalReferenceTheme.action;
    return Semantics(
      button: onPressed != null,
      enabled: onPressed != null,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            foregroundColor: selected
                ? selectedColor
                : ProfessionalReferenceTheme.navy,
            backgroundColor: selected
                ? ProfessionalReferenceTheme.cream
                : Colors.white,
            side: BorderSide(
              color: selected
                  ? ProfessionalReferenceTheme.orange
                  : const Color(0xffd9dce3),
              width: selected ? 1.5 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: ProfessionalReferenceTheme.text(
                    16,
                    color: selected
                        ? selectedColor
                        : ProfessionalReferenceTheme.navy,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_rounded, size: 18, color: selectedColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
