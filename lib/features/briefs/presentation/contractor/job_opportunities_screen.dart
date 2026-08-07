import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_search_bar.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../../core/widgets/shattab_pattern.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../portfolio/presentation/providers/my_portfolio_providers.dart';
import '../../../quotes/presentation/providers/quotes_providers.dart';
import '../../domain/brief.dart';
import '../../domain/opportunity_experience.dart';
import '../providers/briefs_providers.dart';
import '../providers/opportunity_experience_provider.dart';
import 'widgets/job_card.dart';
import 'widgets/job_card_skeleton.dart';
import 'widgets/opportunity_filters_sheet.dart';
import 'widgets/opportunity_summary.dart';

const _opportunitiesBackgroundAsset =
    'assets/images/opportunities_page_background.jpg';
const _opportunitiesBackgroundAspectRatio = 592 / 476;
const _opportunitiesBackgroundMaxHeight = 476.0;

class JobOpportunitiesScreen extends ConsumerStatefulWidget {
  const JobOpportunitiesScreen({super.key});

  @override
  ConsumerState<JobOpportunitiesScreen> createState() =>
      _JobOpportunitiesScreenState();
}

class _JobOpportunitiesScreenState
    extends ConsumerState<JobOpportunitiesScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(opportunitySearchProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      ref.read(opportunitySearchProvider.notifier).setQuery(value);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(opportunitySearchProvider.notifier).clear();
  }

  void _maybeLoadMore(ScrollNotification notification, Object? loadMoreError) {
    if (notification.metrics.axis != Axis.vertical ||
        loadMoreError != null ||
        ref.read(opportunityPaginationProvider).isLoading) {
      return;
    }
    if (notification.metrics.extentAfter < 520) {
      unawaited(ref.read(contractorOpportunitiesProvider.notifier).loadMore());
    }
  }

  Future<void> _refresh() async {
    ref.read(opportunityPaginationProvider.notifier).complete();
    ref.invalidate(contractorOpportunitiesProvider);
    ref.invalidate(myQuotesProvider);
    await ref.read(contractorOpportunitiesProvider.future);
  }

  void _setFocus(OpportunityFocus focus) {
    ref.read(opportunityFiltersProvider.notifier).setFocus(focus);
  }

  void _setSort(OpportunitySort sort) {
    final filters = ref.read(opportunityFiltersProvider);
    ref
        .read(opportunityFiltersProvider.notifier)
        .setFilters(filters.copyWith(sort: sort));
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: BatshMotion.normal,
          curve: BatshMotion.easeOut,
        ),
      );
    }
  }

  void _clearAllFilters() {
    _clearQuery();
    ref.read(opportunityFiltersProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final opportunities = ref.watch(contractorOpportunitiesProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final contractor = ref.watch(contractorProfileProvider).value;
    final portfolio = ref.watch(myPortfolioProvider).value ?? const [];
    final quotes = ref.watch(myQuotesProvider).value ?? const [];
    final filters = ref.watch(opportunityFiltersProvider);
    final interactions = ref.watch(opportunityInteractionsProvider);
    final pagination = ref.watch(opportunityPaginationProvider);
    final isLoadingMore = pagination.isLoading;
    final loadMoreError = pagination.error;
    final appliedIds = {for (final quote in quotes) quote.briefId};
    final query = ref.watch(opportunitySearchProvider);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _OpportunitiesHeroBackground(),
            opportunities.when(
              loading: () => const _OpportunityFeedSkeleton(),
              error: (error, _) => BatshError(
                message: ErrorMapper.map(error),
                onRetry: () => ref.invalidate(contractorOpportunitiesProvider),
              ),
              data: (items) {
                final visible = items
                    .where(
                      (brief) => opportunityMatchesFilters(
                        brief: brief,
                        filters: filters,
                        contractor: contractor,
                        appliedBriefIds: appliedIds,
                      ),
                    )
                    .toList();
                final ordered = sortOpportunities(
                  opportunities: visible,
                  sort: filters.sort,
                  contractor: contractor,
                  portfolio: portfolio,
                );
                final metrics = calculateOpportunityFeedMetrics(
                  opportunities: ordered,
                  contractor: contractor,
                );
                final summaryMetrics = calculateOpportunityRadarMetrics(
                  opportunities: ordered,
                  contractor: contractor,
                );
                final latest = _latestDate(ordered);
                final hasFilters =
                    filters.hasAdvancedFilters ||
                    filters.focus != OpportunityFocus.all;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      _maybeLoadMore(notification, loadMoreError);
                      return false;
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _PageWidth(
                            child: _OpportunitiesHeader(
                              greeting: _greeting(context),
                              firstName: _firstName(profile?.fullName),
                              avatarName:
                                  profile?.fullName ?? context.l10n.appName,
                              avatarUrl: profile?.avatarUrl,
                              matchingCount: metrics.matchingCount,
                              latest: latest,
                              onAvatarTap: () =>
                                  context.go(Routes.contractorProfile),
                              onNotificationsTap: () =>
                                  context.push(Routes.notifications),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _PageWidth(
                            child: _OpportunityToolbar(
                              controller: _searchController,
                              filters: filters,
                              onChanged: _onQueryChanged,
                              onClearSearch: _clearQuery,
                              onOpenFilters: () => _openFilters(
                                items,
                                contractor,
                                appliedIds,
                                filters,
                              ),
                              onFocusChanged: _setFocus,
                              onSortChanged: _setSort,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _PageWidth(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                BatshSpacing.md,
                                BatshSpacing.sm,
                                BatshSpacing.md,
                                0,
                              ),
                              child: OpportunitySummary(
                                metrics: summaryMetrics,
                                preferencesCompletion:
                                    opportunityPreferenceCompletion(contractor),
                                animationKey: Object.hash(filters, query),
                                onPreferencesTap: () =>
                                    context.push(Routes.contractorEditProfile),
                                onMetricTap: _setFocus,
                              ),
                            ),
                          ),
                        ),
                        if (ordered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyOpportunities(
                              hasQuery: query.isNotEmpty,
                              hasFilters: hasFilters,
                              onClear: _clearAllFilters,
                              onEditPreferences: () =>
                                  context.push(Routes.contractorEditProfile),
                            ),
                          )
                        else ...[
                          SliverToBoxAdapter(
                            child: _PageWidth(
                              child: _SectionHeading(
                                title: context.l10n.recommendedForYou,
                                motif: ShattabMotif.finish,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _PageWidth(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BatshSpacing.md,
                                ),
                                child: OpportunityCard(
                                  brief: ordered.first,
                                  match: calculateOpportunityMatch(
                                    brief: ordered.first,
                                    contractor: contractor,
                                    portfolio: portfolio,
                                  ),
                                  recommended: true,
                                  applied: appliedIds.contains(
                                    ordered.first.id,
                                  ),
                                  saved: interactions.savedIds.contains(
                                    ordered.first.id,
                                  ),
                                  viewed: interactions.viewedIds.contains(
                                    ordered.first.id,
                                  ),
                                  onTap: () => _openDetails(ordered.first.id),
                                  onSave: () => _toggleSaved(ordered.first.id),
                                ),
                              ),
                            ),
                          ),
                          if (ordered.length > 1)
                            SliverToBoxAdapter(
                              child: _PageWidth(
                                child: _SectionHeading(
                                  title: context.l10n.moreMatchingOpportunities,
                                  motif: ShattabMotif.arch,
                                ),
                              ),
                            ),
                          if (ordered.length > 1)
                            SliverList.builder(
                              itemCount: ordered.length - 1,
                              itemBuilder: (context, index) {
                                final brief = ordered[index + 1];
                                final card = OpportunityCard(
                                  brief: brief,
                                  match: calculateOpportunityMatch(
                                    brief: brief,
                                    contractor: contractor,
                                    portfolio: portfolio,
                                  ),
                                  applied: appliedIds.contains(brief.id),
                                  saved: interactions.savedIds.contains(
                                    brief.id,
                                  ),
                                  viewed: interactions.viewedIds.contains(
                                    brief.id,
                                  ),
                                  onTap: () => _openDetails(brief.id),
                                  onSave: () => _toggleSaved(brief.id),
                                );
                                final padded = _PageWidth(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      BatshSpacing.md,
                                      0,
                                      BatshSpacing.md,
                                      BatshSpacing.sm,
                                    ),
                                    child: card,
                                  ),
                                );
                                return MediaQuery.disableAnimationsOf(context)
                                    ? padded
                                    : padded
                                          .animate()
                                          .fadeIn(
                                            duration: BatshMotion.normal,
                                            delay: BatshMotion.staggerClamped(
                                              index,
                                            ),
                                          )
                                          .slideY(begin: 0.04, end: 0);
                              },
                            ),
                          if (isLoadingMore)
                            const SliverToBoxAdapter(
                              child: _LoadMoreProgress(),
                            ),
                          if (loadMoreError != null)
                            SliverToBoxAdapter(
                              child: _LoadMoreError(
                                onRetry: () => ref
                                    .read(
                                      contractorOpportunitiesProvider.notifier,
                                    )
                                    .loadMore(),
                              ),
                            ),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 128)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilters(
    List<Brief> opportunities,
    ContractorProfile? contractor,
    Set<String> appliedIds,
    OpportunityFilters initial,
  ) async {
    final result = await showOpportunityFiltersSheet(
      context,
      initial: initial,
      opportunities: opportunities,
      contractor: contractor,
      appliedBriefIds: appliedIds,
    );
    if (result == null) return;
    ref.read(opportunityFiltersProvider.notifier).setFilters(result);
  }

  void _openDetails(String briefId) {
    ref.read(opportunityInteractionsProvider.notifier).markViewed(briefId);
    context.push(Routes.contractorPostDetailPath(briefId));
  }

  void _toggleSaved(String briefId) {
    final saved = ref
        .read(opportunityInteractionsProvider.notifier)
        .toggleSaved(briefId);
    BatshSnack.success(
      context,
      saved
          ? context.l10n.opportunitySaved
          : context.l10n.opportunityRemovedFromSaved,
    );
  }

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.l10n.greetingMorning;
    if (hour < 17) return context.l10n.greetingAfternoon;
    return context.l10n.greetingEvening;
  }

  String _firstName(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return '';
    final firstName = normalized.split(RegExp(r'\s+')).first;
    if ({'مقاول', 'contractor'}.contains(firstName.toLowerCase())) return '';
    return firstName;
  }
}

class _PageWidth extends StatelessWidget {
  const _PageWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class _OpportunitiesHeroBackground extends StatelessWidget {
  const _OpportunitiesHeroBackground();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final nativeHeight = width / _opportunitiesBackgroundAspectRatio;
    final isCapped = nativeHeight > _opportunitiesBackgroundMaxHeight;
    final height = isCapped ? _opportunitiesBackgroundMaxHeight : nativeHeight;

    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
      height: height,
      child: IgnorePointer(
        child: Image.asset(
          _opportunitiesBackgroundAsset,
          // The source artwork is 592 x 476. Keeping its native ratio on
          // phone widths prevents the arch and palm from being cropped.
          fit: isCapped ? BoxFit.cover : BoxFit.fill,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

class _OpportunitiesHeader extends StatelessWidget {
  const _OpportunitiesHeader({
    required this.greeting,
    required this.firstName,
    required this.avatarName,
    required this.avatarUrl,
    required this.matchingCount,
    required this.latest,
    required this.onAvatarTap,
    required this.onNotificationsTap,
  });

  final String greeting;
  final String firstName;
  final String avatarName;
  final String? avatarUrl;
  final int matchingCount;
  final DateTime? latest;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final heading = firstName.isEmpty
        ? greeting
        : context.l10n.greetingPersonalized(greeting, firstName);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(BatshRadius.xxl),
      ),
      child: SizedBox(
        height: 148,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.34,
                ),
              ),
            ),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                start: BatshSpacing.sm,
                top: BatshSpacing.xs,
                child: Semantics(
                  button: true,
                  label: context.l10n.tabProfile,
                  child: InkWell(
                    onTap: onAvatarTap,
                    borderRadius: BatshRadius.brFull,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colorScheme.outlineVariant,
                        ),
                      ),
                      child: AvatarWithInitials(
                        imageUrl: avatarUrl,
                        name: avatarName,
                        radius: 20,
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: BatshSpacing.xs,
                top: BatshSpacing.xs,
                child: IconButton(
                  onPressed: onNotificationsTap,
                  tooltip: context.l10n.notificationsTitle,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    64,
                    36,
                    64,
                    BatshSpacing.sm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        heading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: BatshTypography.titleMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        matchingCount == 0
                            ? context.l10n.searchForMatchingOpportunities
                            : context.l10n.matchingOpportunitiesHeader(
                                matchingCount,
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: BatshTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (latest != null) ...[
                        const SizedBox(height: BatshSpacing.xs),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: BatshIconSize.xs,
                              color: context.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                context.l10n.latestOpportunityTime(
                                  formatRelativeTime(latest!),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: BatshTypography.labelSm.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpportunityToolbar extends StatelessWidget {
  const _OpportunityToolbar({
    required this.controller,
    required this.filters,
    required this.onChanged,
    required this.onClearSearch,
    required this.onOpenFilters,
    required this.onFocusChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final OpportunityFilters filters;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilters;
  final ValueChanged<OpportunityFocus> onFocusChanged;
  final ValueChanged<OpportunitySort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: BatshSearchBar(
                  controller: controller,
                  onChanged: onChanged,
                  onClear: onClearSearch,
                  hintText: context.l10n.searchJobs,
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              Badge(
                isLabelVisible: filters.advancedFilterCount > 0,
                label: Text('${filters.advancedFilterCount}'),
                child: Semantics(
                  button: true,
                  label: context.l10n.opportunityFilterAction(
                    filters.advancedFilterCount,
                  ),
                  child: IconButton(
                    onPressed: onOpenFilters,
                    tooltip: context.l10n.opportunityFiltersTitle,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: context.colorScheme.surfaceContainerLow,
                      side: BorderSide(
                        color: context.colorScheme.outlineVariant,
                      ),
                    ),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: BatshSpacing.xs,
                  runSpacing: BatshSpacing.xs,
                  children: [
                    _FocusChip(
                      label: context.l10n.filterAll,
                      selected: filters.focus == OpportunityFocus.all,
                      onSelected: () => onFocusChanged(OpportunityFocus.all),
                    ),
                    _FocusChip(
                      label: context.l10n.filterNearYou,
                      selected: filters.focus == OpportunityFocus.nearby,
                      onSelected: () => onFocusChanged(OpportunityFocus.nearby),
                    ),
                    _FocusChip(
                      label: context.l10n.filterFresh,
                      selected: filters.focus == OpportunityFocus.fresh,
                      onSelected: () => onFocusChanged(OpportunityFocus.fresh),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<OpportunitySort>(
                tooltip: context.l10n.opportunitySortTitle,
                onSelected: onSortChanged,
                itemBuilder: (context) => [
                  CheckedPopupMenuItem(
                    value: OpportunitySort.recommended,
                    checked: filters.sort == OpportunitySort.recommended,
                    child: Text(context.l10n.opportunitySortRecommended),
                  ),
                  CheckedPopupMenuItem(
                    value: OpportunitySort.newest,
                    checked: filters.sort == OpportunitySort.newest,
                    child: Text(context.l10n.opportunitySortNewest),
                  ),
                ],
                child: Semantics(
                  button: true,
                  label: context.l10n.opportunitySortLabel(
                    filters.sort == OpportunitySort.recommended
                        ? context.l10n.opportunitySortRecommended
                        : context.l10n.opportunitySortNewest,
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerLow,
                      borderRadius: BatshRadius.brFull,
                    ),
                    child: const Icon(Icons.sort_rounded),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  const _FocusChip({
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
      labelStyle: BatshTypography.labelSm.copyWith(
        color: selected
            ? context.colorScheme.onPrimary
            : context.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: context.colorScheme.primary,
      backgroundColor: context.colorScheme.surfaceContainerLowest,
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

/// Kept for existing widget consumers; the live feed uses
/// [OpportunityRadarCard] as its primary summary surface.
@Deprecated('Use OpportunityRadarCard for the contractor feed.')
class OpportunitySummaryCard extends StatelessWidget {
  const OpportunitySummaryCard({
    super.key,
    required this.metrics,
    required this.preferencesCompletion,
    required this.onPreferencesTap,
  });

  final OpportunityFeedMetrics metrics;
  final int preferencesCompletion;
  final VoidCallback onPreferencesTap;

  @override
  Widget build(BuildContext context) {
    final needsSetup = preferencesCompletion < 100;
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brCard,
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: context.colorScheme.primary,
                size: BatshIconSize.sm,
              ),
              const SizedBox(width: BatshSpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.opportunitySummaryTitle,
                  style: BatshTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${metrics.matchingCount}',
                style: BatshTypography.titleLg.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  value: metrics.matchingCount,
                  label: context.l10n.opportunityCountLabel,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  value: metrics.freshCount,
                  label: context.l10n.opportunityFreshCount,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  value: metrics.areaCount,
                  label: context.l10n.opportunityAreaCount,
                ),
              ),
            ],
          ),
          if (needsSetup) ...[
            const SizedBox(height: BatshSpacing.md),
            Container(
              padding: const EdgeInsets.all(BatshSpacing.sm),
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BatshRadius.brMd,
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: BatshSpacing.sm,
                runSpacing: BatshSpacing.sm,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 210),
                    child: Text(
                      context.l10n.completeOpportunityPreferencesHint,
                      style: BatshTypography.labelMd.copyWith(height: 1.35),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onPreferencesTap,
                    child: Text(context.l10n.adjustOpportunityPreferences),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      child: Column(
        children: [
          Text(
            '$value',
            style: BatshTypography.titleLg.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.motif});

  final String title;
  final ShattabMotif motif;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.lg,
          BatshSpacing.md,
          BatshSpacing.sm,
        ),
        child: Row(
          children: [
            ShattabMotifIcon(
              motif: motif,
              color: context.colorScheme.primary,
              size: BatshIconSize.sm,
            ),
            const SizedBox(width: BatshSpacing.xs),
            Text(
              title,
              style: BatshTypography.titleMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOpportunities extends StatelessWidget {
  const _EmptyOpportunities({
    required this.hasQuery,
    required this.hasFilters,
    required this.onClear,
    required this.onEditPreferences,
  });

  final bool hasQuery;
  final bool hasFilters;
  final VoidCallback onClear;
  final VoidCallback onEditPreferences;

  @override
  Widget build(BuildContext context) {
    final narrowed = hasQuery || hasFilters;
    return _EmptyContent(
      title: narrowed
          ? context.l10n.noOpportunityMatches
          : context.l10n.noJobsTitle,
      message: narrowed
          ? context.l10n.noOpportunityMatchesHint
          : context.l10n.noJobsMessage,
      icon: narrowed ? Icons.filter_alt_off_rounded : Icons.work_outline,
      actionLabel: narrowed
          ? context.l10n.clearAllFilters
          : context.l10n.adjustOpportunityPreferences,
      onPressed: narrowed ? onClear : onEditPreferences,
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: BatshIconSize.xxl,
              color: context.colorScheme.primary,
            ),
            const SizedBox(height: BatshSpacing.md),
            Semantics(
              label: '$title $message',
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xs),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: BatshTypography.bodyMd.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.tune_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreProgress extends StatelessWidget {
  const _LoadMoreProgress();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.l10n.loadMoreProgress,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: BatshSpacing.md),
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.l10n.loadMoreError,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.md,
          BatshSpacing.md,
          BatshSpacing.sm,
        ),
        child: Container(
          padding: const EdgeInsets.all(BatshSpacing.md),
          decoration: BoxDecoration(
            color: context.colorScheme.errorContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(BatshRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.loadMoreError,
                  style: BatshTypography.labelMd,
                ),
              ),
              TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpportunityFeedSkeleton extends StatelessWidget {
  const _OpportunityFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        BatshSpacing.md,
        BatshSpacing.md,
        128,
      ),
      children: [
        Row(
          children: [
            const BatshShimmerBox(
              width: 48,
              height: 48,
              borderRadius: BatshRadius.brFull,
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  BatshShimmerBox(width: 150, height: 18),
                  SizedBox(height: BatshSpacing.xs),
                  BatshShimmerBox(width: 210, height: 14),
                ],
              ),
            ),
            const BatshShimmerBox(
              width: 44,
              height: 44,
              borderRadius: BatshRadius.brFull,
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.md),
        const BatshShimmerBox(
          width: double.infinity,
          height: 52,
          borderRadius: BatshRadius.brFull,
        ),
        const SizedBox(height: BatshSpacing.sm),
        const BatshShimmerBox(width: double.infinity, height: 42),
        const SizedBox(height: BatshSpacing.lg),
        const JobCardSkeleton(),
        const SizedBox(height: BatshSpacing.sm),
        const JobCardSkeleton(),
      ],
    );
  }
}

DateTime? _latestDate(List<Brief> opportunities) {
  if (opportunities.isEmpty) return null;
  return opportunities
      .map((brief) => brief.createdAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
}
