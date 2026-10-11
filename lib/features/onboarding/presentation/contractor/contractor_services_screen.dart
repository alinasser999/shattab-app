import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/catalog/specialty_catalog.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/professional_reference_theme.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/professional_reference_primitives.dart';
import '../../../../core/widgets/professional_reference_states.dart';
import '../../domain/onboarding_models.dart';
import '../providers/onboarding_draft_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_header.dart';
import '../widgets/specialty_picker.dart';

class ContractorServicesScreen extends ConsumerStatefulWidget {
  const ContractorServicesScreen({super.key});

  @override
  ConsumerState<ContractorServicesScreen> createState() =>
      _ContractorServicesScreenState();
}

class _ContractorServicesScreenState
    extends ConsumerState<ContractorServicesScreen> {
  List<String> _specialties = const [];
  Set<String> _areas = {};
  bool _hydrated = false;
  bool _busy = false;
  bool _showErrors = false;
  String? _saveError;
  final FocusNode _specialtyFocus = FocusNode(debugLabel: 'specialties');
  final FocusNode _serviceAreaFocus = FocusNode(debugLabel: 'service areas');

  @override
  void dispose() {
    _specialtyFocus.dispose();
    _serviceAreaFocus.dispose();
    super.dispose();
  }

  void _back() => context.go(Routes.onboardingContractorProfile);

  void _setSpecialties(List<String> value) {
    final normalized = List<String>.from(value);
    setState(() {
      _specialties = normalized;
      _saveError = null;
    });
    ref
        .read(onboardingDraftProvider.notifier)
        .updateContractorServices(
          specialties: normalized,
          serviceAreas: _areas,
        );
  }

  void _toggleArea(String city) {
    final next = Set<String>.from(_areas);
    if (!next.add(city)) next.remove(city);
    setState(() {
      _areas = next;
      _saveError = null;
    });
    ref
        .read(onboardingDraftProvider.notifier)
        .updateContractorServices(
          specialties: _specialties,
          serviceAreas: next,
        );
  }

  Future<void> _complete() async {
    setState(() {
      _showErrors = true;
      _saveError = null;
    });
    final roots = SpecialtyCatalog.rootKeys(_specialties);
    if (roots.isEmpty) {
      FocusScope.of(context).requestFocus(_specialtyFocus);
      return;
    }
    if (_areas.isEmpty) {
      FocusScope.of(context).requestFocus(_serviceAreaFocus);
      return;
    }

    final specialties = List<String>.from(_specialties);
    final areas = List<String>.from(_areas);
    setState(() => _busy = true);
    try {
      final controller = ref.read(onboardingControllerProvider.notifier);
      await controller.saveContractorServices(
        specialties: specialties,
        serviceAreas: areas,
      );
      await controller.markComplete();
      if (!mounted) return;
      context.go(Routes.contractorDashboard);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saveError = ErrorMapper.map(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractorAsync = ref.watch(contractorProfileProvider);
    final existing = contractorAsync.value;
    final draft = ref.watch(onboardingDraftProvider);
    if (!_hydrated && !contractorAsync.isLoading) {
      _specialties = draft.contractorServicesEdited
          ? List<String>.from(draft.specialties)
          : existing?.normalizedSpecialties ?? const [];
      _areas = draft.contractorServicesEdited
          ? Set<String>.from(draft.serviceAreas)
          : Set<String>.from(existing?.serviceAreas ?? const []);
      _hydrated = true;
    }

    final content = contractorAsync.hasError
        ? ProfessionalReferenceReadError(
            message: ErrorMapper.map(contractorAsync.error!),
            onRetry: () => ref.invalidate(contractorProfileProvider),
          )
        : contractorAsync.isLoading
        ? const BatshSkeletonRegion(
            child: BatshListSkeleton(count: 2, height: 72),
          )
        : _form(context);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Theme(
        data: ProfessionalReferenceTheme.scopedTheme(Theme.of(context)),
        child: BatshScaffold(
          title: context.l10n.specialtiesTitle,
          animateEntrance: false,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OnboardingProgressHeader(
                  step: 3,
                  stepLabel: context.l10n.onboardingStepContractorServices,
                  onBack: _back,
                  referenceStyle: true,
                ),
                const SizedBox(height: BatshSpacing.lg),
                ProfessionalReferenceWelcome(
                  title: context.l10n.specialtiesTitle,
                  message: context.l10n.specialtiesSubtitle,
                  motif: ProfessionalReferenceMotif.services,
                ),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Focus(
        focusNode: _specialtyFocus,
        child: Semantics(
          container: true,
          focusable: true,
          label: context.l10n.specialtiesTitle,
          child: SpecialtyPicker(
            initialSelection: _specialties,
            requirePrimary: true,
            showChildren: true,
            referenceStyle: true,
            onChanged: _setSpecialties,
          ),
        ),
      ),
      if (_showErrors && SpecialtyCatalog.rootKeys(_specialties).isEmpty) ...[
        const SizedBox(height: BatshSpacing.sm),
        _InlineError(message: context.l10n.onboardingSpecialtyRequired),
      ],
      const SizedBox(height: BatshSpacing.lg),
      Semantics(
        header: true,
        child: Text(
          context.l10n.serviceAreasTitle,
          style: ProfessionalReferenceTheme.text(22, weight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: BatshSpacing.sm),
      Text(
        context.l10n.serviceAreasSubtitle,
        style: ProfessionalReferenceTheme.text(
          16,
          color: ProfessionalReferenceTheme.muted,
        ),
      ),
      const SizedBox(height: BatshSpacing.md),
      Focus(
        focusNode: _serviceAreaFocus,
        child: Semantics(
          container: true,
          focusable: true,
          label: context.l10n.serviceAreasTitle,
          child: Wrap(
            spacing: BatshSpacing.sm,
            runSpacing: BatshSpacing.sm,
            children: OnboardingCatalog.citiesAndDistricts
                .map(
                  (entry) => ProfessionalReferenceChoice(
                    label: localizedOnboardingCityLabel(context, entry.city),
                    selected: _areas.contains(entry.city),
                    semanticLabel: localizedOnboardingCityLabel(
                      context,
                      entry.city,
                    ),
                    minimumHitHeight: true,
                    showSelectionMark: true,
                    onTap: _busy ? null : () => _toggleArea(entry.city),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      if (_showErrors && _areas.isEmpty) ...[
        const SizedBox(height: BatshSpacing.sm),
        _InlineError(message: context.l10n.onboardingServiceAreaRequired),
      ],
      if (_saveError != null) ...[
        const SizedBox(height: BatshSpacing.md),
        ProfessionalReferenceInlineStatus(
          message: '${context.l10n.onboardingSaveFailed} $_saveError',
          retryLabel: context.l10n.onboardingRetrySave,
          onRetry: _complete,
        ),
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
      const SizedBox(height: BatshSpacing.xl),
      ProfessionalReferencePrimaryButton(
        label: context.l10n.done,
        onPressed: _busy ? null : _complete,
        isLoading: _busy,
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
      style: ProfessionalReferenceTheme.text(
        16,
        color: Theme.of(context).colorScheme.error,
      ),
    ),
  );
}
