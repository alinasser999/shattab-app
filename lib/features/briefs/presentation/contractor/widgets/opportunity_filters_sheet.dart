import 'package:flutter/material.dart';

import '../../../../../core/l10n/l10n_extension.dart';
import '../../../../../core/theme/batsh_icon_size.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/theme/batsh_typography.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/batsh_sheet.dart';
import '../../../../onboarding/domain/onboarding_models.dart';
import '../../../domain/brief.dart';
import '../../../domain/opportunity_experience.dart';

Future<OpportunityFilters?> showOpportunityFiltersSheet(
  BuildContext context, {
  required OpportunityFilters initial,
  required List<Brief> opportunities,
  required ContractorProfile? contractor,
  required Set<String> appliedBriefIds,
}) {
  return BatshSheet.show<OpportunityFilters>(
    context,
    contentPadding: EdgeInsets.zero,
    useRootNavigator: true,
    builder: (_) => _OpportunityFiltersSheet(
      initial: initial,
      opportunities: opportunities,
      contractor: contractor,
      appliedBriefIds: appliedBriefIds,
    ),
  );
}

class _OpportunityFiltersSheet extends StatefulWidget {
  const _OpportunityFiltersSheet({
    required this.initial,
    required this.opportunities,
    required this.contractor,
    required this.appliedBriefIds,
  });

  final OpportunityFilters initial;
  final List<Brief> opportunities;
  final ContractorProfile? contractor;
  final Set<String> appliedBriefIds;

  @override
  State<_OpportunityFiltersSheet> createState() =>
      _OpportunityFiltersSheetState();
}

class _OpportunityFiltersSheetState extends State<_OpportunityFiltersSheet> {
  late OpportunityFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
  }

  int get _resultCount => widget.opportunities
      .where(
        (brief) => opportunityMatchesFilters(
          brief: brief,
          filters: _filters,
          contractor: widget.contractor,
          appliedBriefIds: widget.appliedBriefIds,
        ),
      )
      .length;

  @override
  Widget build(BuildContext context) {
    final cities = <String>{
      ...?widget.contractor?.serviceAreas,
      ...OnboardingCatalog.citiesAndDistricts.map((item) => item.city),
    }.take(6).toList();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.md,
              BatshSpacing.xs,
              BatshSpacing.md,
              BatshSpacing.sm,
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => _filters = const OpportunityFilters()),
                  child: Text(context.l10n.resetFilters),
                ),
                Expanded(
                  child: Text(
                    context.l10n.opportunityFiltersTitle,
                    textAlign: TextAlign.center,
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(BatshSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(
                    icon: Icons.location_on_outlined,
                    label: context.l10n.filterLocation,
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Wrap(
                    spacing: BatshSpacing.sm,
                    runSpacing: BatshSpacing.sm,
                    children: [
                      _Choice(
                        label: context.l10n.filterAllLocations,
                        selected: _filters.city == null,
                        onSelected: () =>
                            setState(() => _filters = _filters.withCity(null)),
                      ),
                      for (final city in cities)
                        _Choice(
                          label: city,
                          selected: _filters.city == city,
                          onSelected: () => setState(
                            () => _filters = _filters.withCity(city),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  _SupportNote(
                    icon: Icons.near_me_outlined,
                    text: context.l10n.distanceUnavailableHint,
                  ),
                  const SizedBox(height: BatshSpacing.lg),
                  _SectionTitle(
                    icon: Icons.handyman_outlined,
                    label: context.l10n.filterCategory,
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Wrap(
                    spacing: BatshSpacing.sm,
                    runSpacing: BatshSpacing.sm,
                    children: [
                      for (final entry
                          in OnboardingCatalog.specialtiesCatalog.entries)
                        _Choice(
                          label: entry.value,
                          selected: _filters.specialties.contains(entry.key),
                          onSelected: () {
                            final next = {..._filters.specialties};
                            if (!next.remove(entry.key)) next.add(entry.key);
                            setState(
                              () => _filters = _filters.copyWith(
                                specialties: next,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: BatshSpacing.lg),
                  _SectionTitle(
                    icon: Icons.schedule_outlined,
                    label: context.l10n.filterPublishedTime,
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Wrap(
                    spacing: BatshSpacing.sm,
                    runSpacing: BatshSpacing.sm,
                    children: [
                      _Choice(
                        label: context.l10n.filterAnyTime,
                        selected: _filters.recency == OpportunityRecency.any,
                        onSelected: () => _setRecency(OpportunityRecency.any),
                      ),
                      _Choice(
                        label: context.l10n.filterToday,
                        selected: _filters.recency == OpportunityRecency.today,
                        onSelected: () => _setRecency(OpportunityRecency.today),
                      ),
                      _Choice(
                        label: context.l10n.filterThisWeek,
                        selected:
                            _filters.recency == OpportunityRecency.thisWeek,
                        onSelected: () =>
                            _setRecency(OpportunityRecency.thisWeek),
                      ),
                      _Choice(
                        label: context.l10n.filterThisMonth,
                        selected:
                            _filters.recency == OpportunityRecency.thisMonth,
                        onSelected: () =>
                            _setRecency(OpportunityRecency.thisMonth),
                      ),
                    ],
                  ),
                  const SizedBox(height: BatshSpacing.lg),
                  _SectionTitle(
                    icon: Icons.verified_user_outlined,
                    label: context.l10n.opportunityQuality,
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  _ToggleRow(
                    label: context.l10n.filterHideApplied,
                    value: _filters.hideApplied,
                    onChanged: (value) => setState(
                      () => _filters = _filters.copyWith(hideApplied: value),
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  _SupportNote(
                    icon: Icons.info_outline,
                    text: context.l10n.competitionUnavailableHint,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.md,
              BatshSpacing.sm,
              BatshSpacing.md,
              BatshSpacing.md,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_filters),
                    child: Text(
                      context.l10n.showOpportunityCount(_resultCount),
                      style: BatshTypography.labelLg.copyWith(
                        color: context.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Text(
                  context.l10n.filtersApplyHint,
                  textAlign: TextAlign.center,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setRecency(OpportunityRecency value) {
    setState(() => _filters = _filters.copyWith(recency: value));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: BatshIconSize.sm),
          const SizedBox(width: BatshSpacing.sm),
          Text(
            label,
            style: BatshTypography.titleMd.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      labelStyle: BatshTypography.labelMd.copyWith(
        color: selected
            ? context.colorScheme.onPrimary
            : context.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: context.colorScheme.primary,
      backgroundColor: context.colorScheme.surface,
      side: BorderSide(
        color: selected
            ? context.colorScheme.primary
            : context.colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BatshRadius.md),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(BatshRadius.md),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        title: Text(label, style: BatshTypography.bodyMd),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
      ),
    );
  }
}

class _SupportNote extends StatelessWidget {
  const _SupportNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: BatshIconSize.xs,
          color: context.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: BatshSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
