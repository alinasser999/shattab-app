import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_empty_state.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_pattern_background.dart';
import '../../../../core/widgets/batsh_search_bar.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../../core/widgets/batsh_chip.dart';
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
import 'widgets/job_card_skeleton.dart';
import 'widgets/opportunity_filters_sheet.dart';
import 'widgets/opportunity_summary.dart';
import 'widgets/opportunity_reference_cards.dart';

const _opportunitiesBackgroundAsset =
    'assets/images/work_opportunities_hero_cairo.jpg';
const _opportunitiesBackgroundAspectRatio = 1280 / 426;
const _opportunitiesBackgroundMaxHeight = 426.0;

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
  final _allOpportunitiesKey = GlobalKey();
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
    ref.invalidate(myQuotesWithBriefsProvider);
    await ref.read(contractorOpportunitiesProvider.future);
  }

  void _setFocus(OpportunityFocus focus) {
    if (focus == OpportunityFocus.all) {
      ref.read(opportunityFiltersProvider.notifier).reset();
      return;
    }
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

  void _scrollToAll() {
    final target = _allOpportunitiesKey.currentContext;
    if (target == null) return;
    unawaited(
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : BatshMotion.normal,
        curve: BatshMotion.easeOut,
        alignment: 0.02,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opportunities = ref.watch(contractorOpportunitiesProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final contractor = ref.watch(contractorProfileProvider).value;
    final portfolio = ref.watch(myPortfolioProvider).value ?? const [];
    final quoteRowsAsync = ref.watch(myQuotesWithBriefsProvider);
    final quotes =
        quoteRowsAsync.asData?.value
            ?.map((row) => row.quote)
            .toList(growable: false) ??
        const [];
    final filters = ref.watch(opportunityFiltersProvider);
    final interactions = ref.watch(opportunityInteractionsProvider);
    final pagination = ref.watch(opportunityPaginationProvider);
    final isLoadingMore = pagination.isLoading;
    final loadMoreError = pagination.error;
    final appliedIds = {for (final quote in quotes) quote.briefId};
    final query = ref.watch(opportunitySearchProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(
                child: BatshPatternBackground(child: SizedBox.expand()),
              ),
              const _OpportunitiesHeroBackground(),
              SafeArea(
                bottom: false,
                child: opportunities.when(
                  loading: () => const _OpportunityFeedSkeleton(),
                  error: (error, _) => BatshError(
                    message: ErrorMapper.map(error),
                    onRetry: () =>
                        ref.invalidate(contractorOpportunitiesProvider),
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
                    final recommended = sortOpportunities(
                      opportunities: visible,
                      sort: OpportunitySort.recommended,
                      contractor: contractor,
                      portfolio: portfolio,
                    );
                    final fresh = ordered.where(_isFreshOpportunity).toList();
                    final inAreas = ordered
                        .where(
                          (brief) =>
                              contractor?.serviceAreas.contains(brief.city) ??
                              false,
                        )
                        .toList();
                    final summaryMetrics = calculateOpportunityRadarMetrics(
                      opportunities: ordered,
                      contractor: contractor,
                    );
                    final hasFilters =
                        filters.hasAdvancedFilters ||
                        filters.focus != OpportunityFocus.all;
                    final quoteRows = [...?quoteRowsAsync.asData?.value]
                      ..sort(
                        (a, b) =>
                            b.quote.createdAt.compareTo(a.quote.createdAt),
                      );

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
                                  matchingCount: ordered.length,
                                  onAvatarTap: () =>
                                      context.go(Routes.contractorProfile),
                                  onNotificationsTap: () =>
                                      context.push(Routes.notifications),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _PageWidth(
                                child: Transform.translate(
                                  offset: const Offset(0, -18),
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
                                    onSortChanged: _setSort,
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _QuickFilterRow(
                                filters: filters,
                                onFocus: _setFocus,
                                onSpecialty: () => _openFilters(
                                  items,
                                  contractor,
                                  appliedIds,
                                  filters,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _PageWidth(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    BatshSpacing.md,
                                    BatshSpacing.xs,
                                    BatshSpacing.md,
                                    0,
                                  ),
                                  child: OpportunitySummary(
                                    metrics: summaryMetrics,
                                    preferencesCompletion:
                                        opportunityPreferenceCompletion(
                                          contractor,
                                        ),
                                    animationKey: Object.hash(filters, query),
                                    onPreferencesTap: () => context.push(
                                      Routes.contractorEditProfile,
                                    ),
                                    onMetricTap: _setFocus,
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: OpportunityReferenceSectionHeading(
                                title: context.l10n.workFeaturedOpportunity,
                                subtitle: context.l10n.recommendedForYou,
                                icon: Icons.workspace_premium_outlined,
                                onSeeAll: _scrollToAll,
                              ),
                            ),
                            if (recommended.isNotEmpty)
                              SliverToBoxAdapter(
                                child: OpportunityReferenceFeaturedCard(
                                  brief: recommended.first,
                                  saved: interactions.savedIds.contains(
                                    recommended.first.id,
                                  ),
                                  onTap: () =>
                                      _openDetails(recommended.first.id),
                                  onSave: () => unawaited(
                                    _toggleSaved(recommended.first.id),
                                  ),
                                ),
                              )
                            else
                              SliverToBoxAdapter(
                                child: OpportunityReferenceEmptyRail(
                                  label: context.l10n.noOpportunityMatches,
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: OpportunityReferenceSectionHeading(
                                title: context.l10n.workNewToday,
                                subtitle: context.l10n.radarFresh,
                                icon: Icons.schedule_rounded,
                                onSeeAll: _scrollToAll,
                              ),
                            ),
                            if (fresh.isNotEmpty)
                              _OpportunityHorizontalRail(
                                opportunities: fresh,
                                savedIds: interactions.savedIds,
                                onTap: _openDetails,
                                onSave: (id) => unawaited(_toggleSaved(id)),
                                freshLayout: true,
                              )
                            else
                              SliverToBoxAdapter(
                                child: OpportunityReferenceEmptyRail(
                                  label: context.l10n.workNewToday,
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: OpportunityReferenceSectionHeading(
                                title: context.l10n.workRecentQuotes,
                                subtitle: context.l10n.myQuotesTitle,
                                icon: Icons.receipt_long_outlined,
                                onSeeAll: () =>
                                    context.push(Routes.contractorMyQuotes),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BatshSpacing.md,
                                ),
                                child: quoteRowsAsync.hasError
                                    ? BatshError(
                                        message: ErrorMapper.map(
                                          quoteRowsAsync.error!,
                                        ),
                                        onRetry: () => ref.invalidate(
                                          myQuotesWithBriefsProvider,
                                        ),
                                      )
                                    : quoteRows.isEmpty
                                    ? _RecentQuotesEmpty(
                                        loading: quoteRowsAsync.isLoading,
                                        onTap: () => context.push(
                                          Routes.contractorMyQuotes,
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          for (final row in quoteRows.take(3))
                                            OpportunityReferenceQuoteRow(
                                              quote: row.quote,
                                              brief: row.brief,
                                              onTap: () => context.push(
                                                Routes.contractorPostDetailPath(
                                                  row.quote.briefId,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: OpportunityReferenceSectionHeading(
                                title: context.l10n.workSuitableForYou,
                                subtitle: context.l10n.newOpportunitiesForYou,
                                icon: Icons.track_changes_rounded,
                                onSeeAll: _scrollToAll,
                              ),
                            ),
                            if (recommended.isNotEmpty)
                              _OpportunityHorizontalRail(
                                opportunities: recommended,
                                savedIds: interactions.savedIds,
                                onTap: _openDetails,
                                onSave: (id) => unawaited(_toggleSaved(id)),
                              )
                            else
                              SliverToBoxAdapter(
                                child: OpportunityReferenceEmptyRail(
                                  label: context.l10n.workSuitableForYou,
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: OpportunityReferenceSectionHeading(
                                title: context.l10n.workInYourAreas,
                                subtitle: context.l10n.radarInYourAreas,
                                icon: Icons.location_on_outlined,
                                onSeeAll: _scrollToAll,
                              ),
                            ),
                            if (inAreas.isNotEmpty)
                              _OpportunityHorizontalRail(
                                opportunities: inAreas,
                                savedIds: interactions.savedIds,
                                onTap: _openDetails,
                                onSave: (id) => unawaited(_toggleSaved(id)),
                              )
                            else
                              SliverToBoxAdapter(
                                child: OpportunityReferenceEmptyRail(
                                  label: context.l10n.workInYourAreas,
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: KeyedSubtree(
                                key: _allOpportunitiesKey,
                                child: OpportunityReferenceSectionHeading(
                                  title: context.l10n.workAllOpportunities,
                                  subtitle:
                                      context.l10n.workAllAvailableSubtitle,
                                  icon: Icons.article_outlined,
                                  onSeeAll: _scrollToAll,
                                  showSeeAll: false,
                                ),
                              ),
                            ),
                            if (ordered.isEmpty)
                              SliverToBoxAdapter(
                                child: _EmptyOpportunities(
                                  hasQuery: query.isNotEmpty,
                                  hasFilters: hasFilters,
                                  onClear: _clearAllFilters,
                                  onEditPreferences: () => context.push(
                                    Routes.contractorEditProfile,
                                  ),
                                ),
                              )
                            else
                              SliverList.builder(
                                itemCount: ordered.length,
                                itemBuilder: (context, index) {
                                  final brief = ordered[index];
                                  return _PageWidth(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: BatshSpacing.md,
                                      ),
                                      child: OpportunityReferenceListRow(
                                        brief: brief,
                                        match: calculateOpportunityMatch(
                                          brief: brief,
                                          contractor: contractor,
                                          portfolio: portfolio,
                                        ),
                                        onTap: () => _openDetails(brief.id),
                                      ),
                                    ),
                                  );
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
                                        contractorOpportunitiesProvider
                                            .notifier,
                                      )
                                      .loadMore(),
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: OpportunityAdviceBanner(
                                onTap: () =>
                                    context.push(Routes.contractorEditProfile),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: const SizedBox(height: BatshSpacing.md),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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

  Future<void> _toggleSaved(String briefId) async {
    try {
      final saved = await ref
          .read(opportunityInteractionsProvider.notifier)
          .toggleSaved(briefId);
      if (!mounted) return;
      BatshSnack.success(
        context,
        saved
            ? context.l10n.opportunitySaved
            : context.l10n.opportunityRemovedFromSaved,
      );
    } catch (error) {
      if (!mounted) return;
      BatshSnack.error(context, ErrorMapper.map(error));
    }
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _opportunitiesBackgroundAsset,
              // Photo 3 is 1280 × 426; its native ratio keeps the skyline intact.
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x3D32140E),
                    Color(0x292F140D),
                    Color(0x0A2F140D),
                  ],
                  stops: [0, .62, 1],
                ),
              ),
            ),
          ],
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
    required this.onAvatarTap,
    required this.onNotificationsTap,
  });

  final String greeting;
  final String firstName;
  final String avatarName;
  final String? avatarUrl;
  final int matchingCount;
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
        height: 100,
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
                        radius: 22,
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
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    64,
                    28,
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

class _QuickFilterRow extends StatelessWidget {
  const _QuickFilterRow({
    required this.filters,
    required this.onFocus,
    required this.onSpecialty,
  });

  final OpportunityFilters filters;
  final ValueChanged<OpportunityFocus> onFocus;
  final VoidCallback onSpecialty;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      start: BatshSpacing.md,
      end: BatshSpacing.md,
      bottom: BatshSpacing.xs,
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          BatshChip(
            label: context.l10n.filterAll,
            icon: Icons.expand_more_rounded,
            selected:
                filters.focus == OpportunityFocus.all &&
                !filters.hasAdvancedFilters,
            compact: true,
            minimumHitHeight: true,
            singleSelection: true,
            onTap: () => onFocus(OpportunityFocus.all),
          ),
          const SizedBox(width: BatshSpacing.xs),
          BatshChip(
            label: context.l10n.filterNearYou,
            icon: Icons.location_on_outlined,
            selected: filters.focus == OpportunityFocus.nearby,
            compact: true,
            minimumHitHeight: true,
            singleSelection: true,
            onTap: () => onFocus(OpportunityFocus.nearby),
          ),
          const SizedBox(width: BatshSpacing.xs),
          BatshChip(
            label: context.l10n.filterFresh,
            icon: Icons.bolt_rounded,
            selected: filters.focus == OpportunityFocus.fresh,
            compact: true,
            minimumHitHeight: true,
            singleSelection: true,
            onTap: () => onFocus(OpportunityFocus.fresh),
          ),
          const SizedBox(width: BatshSpacing.xs),
          BatshChip(
            label: context.l10n.workSpecialtyFilter,
            icon: Icons.handyman_outlined,
            selected: filters.specialties.isNotEmpty,
            compact: true,
            minimumHitHeight: true,
            onTap: onSpecialty,
          ),
        ],
      ),
    ),
  );
}

class _OpportunityHorizontalRail extends StatelessWidget {
  const _OpportunityHorizontalRail({
    required this.opportunities,
    required this.savedIds,
    required this.onTap,
    required this.onSave,
    this.freshLayout = false,
  });

  final List<Brief> opportunities;
  final Set<String> savedIds;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onSave;
  final bool freshLayout;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: SizedBox(
      height: freshLayout ? 82 : 194,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final brief in opportunities) ...[
              if (freshLayout)
                OpportunityReferenceFreshCard(
                  brief: brief,
                  saved: savedIds.contains(brief.id),
                  onTap: () => onTap(brief.id),
                  onSave: () => onSave(brief.id),
                )
              else
                OpportunityReferenceRailCard(
                  brief: brief,
                  saved: savedIds.contains(brief.id),
                  onTap: () => onTap(brief.id),
                  onSave: () => onSave(brief.id),
                ),
              const SizedBox(width: BatshSpacing.xs),
            ],
          ],
        ),
      ),
    ),
  );
}

class _RecentQuotesEmpty extends StatelessWidget {
  const _RecentQuotesEmpty({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => loading
      ? const BatshShimmerBox(
          width: double.infinity,
          height: 62,
          borderRadius: BatshRadius.brMd,
        )
      : Container(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
          constraints: const BoxConstraints(minHeight: 62),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brMd,
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.workNoRecentQuotes,
                  style: BatshTypography.bodySm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(onPressed: onTap, child: Text(context.l10n.viewAll)),
            ],
          ),
        );
}

class _OpportunityToolbar extends StatelessWidget {
  const _OpportunityToolbar({
    required this.controller,
    required this.filters,
    required this.onChanged,
    required this.onClearSearch,
    required this.onOpenFilters,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final OpportunityFilters filters;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilters;
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
              const SizedBox(width: BatshSpacing.xs),
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
    return BatshEmptyState(
      title: narrowed
          ? context.l10n.noOpportunityMatches
          : context.l10n.noJobsTitle,
      message: narrowed
          ? context.l10n.noOpportunityMatchesHint
          : context.l10n.noJobsMessage,
      icon: narrowed ? Icons.filter_alt_off_rounded : Icons.work_outline,
      kind: narrowed
          ? BatshEmptyStateKind.noResults
          : BatshEmptyStateKind.nothingYet,
      action: OutlinedButton.icon(
        onPressed: narrowed ? onClear : onEditPreferences,
        icon: Icon(
          narrowed ? Icons.filter_alt_off_rounded : Icons.tune_rounded,
        ),
        label: Text(
          narrowed
              ? context.l10n.clearAllFilters
              : context.l10n.adjustOpportunityPreferences,
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(BatshSpacing.minHitArea),
        ),
      ),
    );
  }
}

class _LoadMoreProgress extends StatelessWidget {
  const _LoadMoreProgress();

  @override
  Widget build(BuildContext context) {
    return const BatshPaginationSkeleton();
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

bool _isFreshOpportunity(Brief brief) {
  final age = DateTime.now().difference(brief.createdAt);
  return !age.isNegative && age <= const Duration(hours: 24);
}
