import '../../../../core/widgets/professional_reference_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/catalog/specialty_catalog.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/professional_reference_theme.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
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

  Future<void> _next() async {
    setState(() {
      _showErrors = true;
      _saveError = null;
    });
    if (_aptType == null) {
      _focusAndReveal(_apartmentFocus);
      return;
    }
    if (_interests.isEmpty) {
      _focusAndReveal(_interestFocus);
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
                  label: null,
                  child: BatshListSkeleton(count: 2, height: 72),
                )
              : _form(referenceContext);

          return PopScope<void>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: BatshScaffold(
              title: referenceContext.l10n.yourData,
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
                            step: 2,
                            stepLabel: referenceContext
                                .l10n
                                .onboardingStepHomeownerDetails,
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
                    label: referenceContext.l10n.next,
                    onPressed:
                        _busy ||
                            homeownerAsync.isLoading ||
                            homeownerAsync.hasError
                        ? null
                        : _next,
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

  Widget _apartmentOption(BuildContext context, ApartmentType type) {
    final label = _apartmentLabel(context, type);
    final selected = _aptType == type;
    return Semantics(
      button: !_busy,
      enabled: !_busy,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: _busy ? null : () => _setApartmentType(type),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 124),
          child: BatshCard(
            selected: selected,
            highlightColor: selected ? ProfessionalReferenceTheme.cream : null,
            onTap: _busy ? null : () => _setApartmentType(type),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _apartmentIcons[type],
                  size: BatshIconSize.lg,
                  color: selected
                      ? ProfessionalReferenceTheme.orange
                      : ProfessionalReferenceTheme.muted,
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: ProfessionalReferenceTheme.text(
                    18,
                    weight: FontWeight.w700,
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: BatshIconSize.sm,
                    color: ProfessionalReferenceTheme.action,
                  ),
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
      Text(
        context.l10n.homeownerDetailsHint,
        style: ProfessionalReferenceTheme.text(
          16,
          color: ProfessionalReferenceTheme.muted,
        ),
      ),
      const SizedBox(height: BatshSpacing.md),
      _ReferenceSectionHeader(title: context.l10n.apartmentType),
      const SizedBox(height: BatshSpacing.sm),
      Focus(
        focusNode: _apartmentFocus,
        child: Semantics(
          container: true,
          focusable: true,
          label: context.l10n.apartmentType,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth < 320 &&
                      MediaQuery.textScalerOf(context).scale(1) > 1.1
                  ? 1
                  : 2;
              return Wrap(
                spacing: BatshSpacing.gutter,
                runSpacing: BatshSpacing.gutter,
                children: [
                  for (final type in ApartmentType.values)
                    SizedBox(
                      width:
                          (constraints.maxWidth -
                              BatshSpacing.gutter * (columns - 1)) /
                          columns,
                      child: _apartmentOption(context, type),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      if (_showErrors && _aptType == null) ...[
        const SizedBox(height: BatshSpacing.sm),
        _InlineError(message: context.l10n.onboardingApartmentRequired),
      ],
      const SizedBox(height: BatshSpacing.lg),
      _ReferenceSectionHeader(title: context.l10n.interestAreas),
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
            children: SpecialtyCatalog.roots.map((root) {
              final label = localizedSpecialtyLabel(context, root.key);
              return _ReferenceChoiceButton(
                label: label,
                icon: specialtyIcon(root.key),
                selected: _interests.contains(root.key),
                onPressed: _busy ? null : () => _toggleInterest(root.key),
              );
            }).toList(),
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

class _ReferenceSectionHeader extends StatelessWidget {
  const _ReferenceSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      title,
      style: ProfessionalReferenceTheme.text(20, weight: FontWeight.w700),
    ),
  );
}

class _ReferenceChoiceButton extends StatelessWidget {
  const _ReferenceChoiceButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ProfessionalReferenceTheme.text(
      16,
      color: selected
          ? ProfessionalReferenceTheme.action
          : ProfessionalReferenceTheme.navy,
      weight: selected ? FontWeight.w700 : FontWeight.w500,
    );
    return Semantics(
      button: onPressed != null,
      enabled: onPressed != null,
      selected: selected,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            foregroundColor: selected
                ? ProfessionalReferenceTheme.action
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
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? ProfessionalReferenceTheme.action
                      : ProfessionalReferenceTheme.muted,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(label, style: style, textAlign: TextAlign.center),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_rounded, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
