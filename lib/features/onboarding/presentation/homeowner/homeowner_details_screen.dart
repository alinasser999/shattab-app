import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/catalog/specialty_catalog.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_section_header.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../domain/onboarding_models.dart';
import '../providers/onboarding_draft_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_header.dart';

class HomeownerDetailsScreen extends ConsumerStatefulWidget {
  const HomeownerDetailsScreen({super.key});

  @override
  ConsumerState<HomeownerDetailsScreen> createState() =>
      _HomeownerDetailsScreenState();
}

class _HomeownerDetailsScreenState
    extends ConsumerState<HomeownerDetailsScreen> {
  ApartmentType? _aptType;
  Set<String> _interests = {};
  bool _busy = false;
  bool _hydrated = false;
  bool _showErrors = false;
  String? _saveError;
  final FocusNode _apartmentFocus = FocusNode(debugLabel: 'apartment type');
  final FocusNode _interestFocus = FocusNode(
    debugLabel: 'renovation interests',
  );

  static const Map<ApartmentType, IconData> _apartmentIcons = {
    ApartmentType.studio: Icons.weekend_outlined,
    ApartmentType.oneBedroom: Icons.bed_outlined,
    ApartmentType.twoBedroom: Icons.king_bed_outlined,
    ApartmentType.threeBedroomPlus: Icons.bedroom_parent_outlined,
    ApartmentType.duplex: Icons.stairs_outlined,
    ApartmentType.villa: Icons.villa_outlined,
    ApartmentType.penthouse: Icons.apartment_outlined,
  };

  @override
  void dispose() {
    _apartmentFocus.dispose();
    _interestFocus.dispose();
    super.dispose();
  }

  void _back() => context.go(Routes.onboardingRoleSelect);

  void _setApartmentType(ApartmentType value) {
    setState(() {
      _aptType = value;
      _saveError = null;
    });
    ref
        .read(onboardingDraftProvider.notifier)
        .updateHomeownerDetails(apartmentType: value, interests: _interests);
  }

  void _toggleInterest(String value) {
    final next = Set<String>.from(_interests);
    if (!next.add(value)) next.remove(value);
    setState(() {
      _interests = next;
      _saveError = null;
    });
    ref
        .read(onboardingDraftProvider.notifier)
        .updateHomeownerDetails(apartmentType: _aptType, interests: next);
  }

  Future<void> _next() async {
    setState(() {
      _showErrors = true;
      _saveError = null;
    });
    if (_aptType == null) {
      FocusScope.of(context).requestFocus(_apartmentFocus);
      return;
    }
    if (_interests.isEmpty) {
      FocusScope.of(context).requestFocus(_interestFocus);
      return;
    }

    final apartmentType = _aptType!;
    final interests = List<String>.from(_interests);
    setState(() => _busy = true);
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .saveHomeownerDetails(
            apartmentType: apartmentType,
            interests: interests,
          );
      if (!mounted) return;
      context.go(Routes.onboardingHomeownerLocation);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saveError = ErrorMapper.map(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _apartmentLabel(BuildContext context, ApartmentType value) =>
      switch (value) {
        ApartmentType.studio => context.l10n.apartmentStudio,
        ApartmentType.oneBedroom => context.l10n.apartmentOneBedroom,
        ApartmentType.twoBedroom => context.l10n.apartmentTwoBedroom,
        ApartmentType.threeBedroomPlus =>
          context.l10n.apartmentThreeBedroomPlus,
        ApartmentType.duplex => context.l10n.apartmentDuplex,
        ApartmentType.villa => context.l10n.apartmentVilla,
        ApartmentType.penthouse => context.l10n.apartmentPenthouse,
      };

  @override
  Widget build(BuildContext context) {
    final homeownerAsync = ref.watch(homeownerProfileProvider);
    final existing = homeownerAsync.value;
    final draft = ref.watch(onboardingDraftProvider);
    if (!_hydrated && !homeownerAsync.isLoading && existing != null) {
      _aptType = draft.homeownerDetailsEdited
          ? draft.apartmentType
          : existing.apartmentType;
      _interests = draft.homeownerDetailsEdited
          ? Set<String>.from(draft.renovationInterests)
          : SpecialtyCatalog.rootKeys(existing.renovationInterests).toSet();
      _hydrated = true;
    } else if (!_hydrated && !homeownerAsync.isLoading && existing == null) {
      _aptType = draft.apartmentType;
      _interests = Set<String>.from(draft.renovationInterests);
      _hydrated = true;
    }

    final stepBody = homeownerAsync.hasError
        ? BatshError(
            message: ErrorMapper.map(homeownerAsync.error!),
            onRetry: () => ref.invalidate(homeownerProfileProvider),
          )
        : homeownerAsync.isLoading
        ? const BatshSkeletonRegion(
            label: null,
            child: BatshListSkeleton(count: 2, height: 72),
          )
        : _form(context);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: BatshScaffold(
        title: context.l10n.yourData,
        animateEntrance: false,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingProgressHeader(
                step: 2,
                stepLabel: context.l10n.onboardingStepHomeownerDetails,
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
        context.l10n.homeownerDetailsHint,
        style: BatshTypography.bodyMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: BatshSpacing.md),
      BatshSectionHeader(title: context.l10n.apartmentType),
      const SizedBox(height: BatshSpacing.sm),
      Focus(
        focusNode: _apartmentFocus,
        child: Semantics(
          container: true,
          focusable: true,
          label: context.l10n.apartmentType,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: BatshSpacing.gutter,
            mainAxisSpacing: BatshSpacing.gutter,
            childAspectRatio: 1.1,
            children: ApartmentType.values.map((type) {
              final label = _apartmentLabel(context, type);
              final selected = _aptType == type;
              return Semantics(
                button: true,
                selected: selected,
                inMutuallyExclusiveGroup: true,
                label: label,
                child: ExcludeSemantics(
                  child: BatshCard(
                    selected: selected,
                    onTap: _busy ? null : () => _setApartmentType(type),
                    padding: const EdgeInsets.all(BatshSpacing.gutter),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _apartmentIcons[type],
                          size: BatshIconSize.lg,
                          color: selected
                              ? context.colorScheme.primary
                              : context.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: BatshSpacing.sm),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: BatshTypography.titleLg.copyWith(
                            color: selected
                                ? context.colorScheme.primary
                                : context.colorScheme.onSurface,
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: BatshIconSize.sm,
                            color: context.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      if (_showErrors && _aptType == null) ...[
        const SizedBox(height: BatshSpacing.sm),
        _InlineError(message: context.l10n.onboardingApartmentRequired),
      ],
      const SizedBox(height: BatshSpacing.lg),
      BatshSectionHeader(title: context.l10n.interestAreas),
      const SizedBox(height: BatshSpacing.sm),
      Focus(
        focusNode: _interestFocus,
        child: Semantics(
          container: true,
          focusable: true,
          label: context.l10n.interestAreas,
          child: Wrap(
            spacing: BatshSpacing.sm,
            runSpacing: BatshSpacing.sm,
            children: SpecialtyCatalog.roots
                .map(
                  (root) => BatshChip(
                    label: localizedSpecialtyLabel(context, root.key),
                    icon: specialtyIcon(root.key),
                    selected: _interests.contains(root.key),
                    semanticLabel: localizedSpecialtyLabel(context, root.key),
                    minimumHitHeight: true,
                    showSelectionMark: true,
                    onTap: _busy ? null : () => _toggleInterest(root.key),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      if (_showErrors && _interests.isEmpty) ...[
        const SizedBox(height: BatshSpacing.sm),
        _InlineError(message: context.l10n.onboardingInterestRequired),
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
        label: context.l10n.next,
        onPressed: _busy ? null : _next,
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
