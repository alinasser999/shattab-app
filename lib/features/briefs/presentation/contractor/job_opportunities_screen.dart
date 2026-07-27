import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_empty_state.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_filter_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../quotes/presentation/quote_sheet.dart';
import '../../../quotes/presentation/providers/quotes_providers.dart';
import '../../../discovery/presentation/widgets/avatar_with_initials.dart';
import '../../domain/brief.dart';
import '../../domain/job_feed_filters.dart';
import '../providers/briefs_providers.dart';
import 'widgets/job_card.dart';
import 'widgets/job_card_skeleton.dart';
import '../../../../core/theme/batsh_icon_size.dart';

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
  final Set<String> _activeFilters = {};

  /// The field updates on every keystroke; the query only reaches the server
  /// once typing settles.
  Timer? _debounce;

  /// Display label per stable filter key. Kept beside the sections so a new
  /// option can't be added without a label.
  static final Map<String, String> _filterLabels = {
    SpecialtyFilter.painting.key: S.filterPainting,
    SpecialtyFilter.electrical.key: S.filterElectrical,
    SpecialtyFilter.plumbing.key: S.filterPlumbing,
    SpecialtyFilter.finishing.key: S.filterFinishing,
    SpecialtyFilter.bathrooms.key: S.filterBathrooms,
    SpecialtyFilter.kitchens.key: S.filterKitchens,
    RecencyFilter.today.key: S.filterToday,
    RecencyFilter.thisWeek.key: S.filterThisWeek,
    RecencyFilter.thisMonth.key: S.filterThisMonth,
  };

  // The "الترتيب" section that used to sit on top is gone: "الأقرب" needs
  // coordinates the app never collects, "أعلى ميزانية" needs a budget column
  // `briefs` does not have, and "الأحدث" is already the query's order. Three
  // options, none of which did anything.
  static final _filterSections = [
    BatshFilterSheetSection(
      title: S.filterCategory,
      icon: Icons.category_rounded,
      options: [
        FilterOption(
          value: SpecialtyFilter.painting.key,
          label: S.filterPainting,
          icon: Icons.format_paint,
        ),
        FilterOption(
          value: SpecialtyFilter.electrical.key,
          label: S.filterElectrical,
          icon: Icons.electrical_services,
        ),
        FilterOption(
          value: SpecialtyFilter.plumbing.key,
          label: S.filterPlumbing,
          icon: Icons.plumbing,
        ),
        FilterOption(
          value: SpecialtyFilter.finishing.key,
          label: S.filterFinishing,
          icon: Icons.build,
        ),
        FilterOption(
          value: SpecialtyFilter.bathrooms.key,
          label: S.filterBathrooms,
          icon: Icons.bathtub_outlined,
        ),
        FilterOption(
          value: SpecialtyFilter.kitchens.key,
          label: S.filterKitchens,
          icon: Icons.countertops_outlined,
        ),
      ],
    ),
    BatshFilterSheetSection(
      title: S.filterTime,
      icon: Icons.schedule_rounded,
      singleSelect: true,
      options: [
        FilterOption(
          value: RecencyFilter.today.key,
          label: S.filterToday,
          icon: Icons.today,
        ),
        FilterOption(
          value: RecencyFilter.thisWeek.key,
          label: S.filterThisWeek,
          icon: Icons.date_range_rounded,
        ),
        FilterOption(
          value: RecencyFilter.thisMonth.key,
          label: S.filterThisMonth,
          icon: Icons.calendar_month_rounded,
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      // Pushed into the provider, not local state: the query is part of the
      // server query now, so a match on page 3 is found instead of only what
      // happens to be loaded.
      ref.read(opportunitySearchProvider.notifier).setQuery(value);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(opportunitySearchProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(contractorOpportunitiesProvider);
    final query = ref.watch(opportunitySearchProvider);
    final profile = ref.watch(currentProfileProvider);
    final name = profile.value?.fullName ?? '';
    final greeting = _greeting();

    return Scaffold(
      backgroundColor: BatshColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(contractorOpportunitiesProvider),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _PremiumAppBar(
                  greeting: greeting,
                  name: name,
                  avatarUrl: profile.value?.avatarUrl,
                  onTap: () => context.go(Routes.contractorProfile),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    BatshSpacing.gutter,
                    0,
                    BatshSpacing.gutter,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SearchBar(
                          controller: _searchController,
                          onChanged: _onQueryChanged,
                          onClear: _clearQuery,
                        ),
                      ),
                      const SizedBox(width: BatshSpacing.sm),
                      BatshFilterButton(
                        activeCount: _activeFilters.length,
                        onTap: () => _openFilterSheet(context),
                      ),
                      const SizedBox(width: BatshSpacing.sm),
                      Material(
                        color: BatshColors.cardBackground,
                        borderRadius: BatshRadius.brFull,
                        child: InkWell(
                          borderRadius: BatshRadius.brFull,
                          onTap: () => context.push(Routes.contractorMyQuotes),
                          child: Container(
                            height: 48,
                            width: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BatshRadius.brFull,
                              boxShadow: BatshShadows.soft,
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color: BatshColors.primary,
                              size: BatshIconSize.md,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_activeFilters.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      BatshSpacing.gutter,
                      BatshSpacing.sm,
                      BatshSpacing.gutter,
                      0,
                    ),
                    child: SizedBox(
                      height: 30,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _activeFilters.length + 1,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: BatshSpacing.xs),
                        itemBuilder: (_, i) {
                          if (i < _activeFilters.length) {
                            final filter = _activeFilters.elementAt(i);
                            return BatshActiveFilterChip(
                              // Chips are keyed on stable values now, so the
                              // label has to be resolved for display.
                              label: _filterLabels[filter] ?? filter,
                              onRemove: () =>
                                  setState(() => _activeFilters.remove(filter)),
                            );
                          }
                          return BatshActiveFilterChip(
                            label: S.clearAll,
                            onRemove: () => setState(_activeFilters.clear),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              async.when(
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      BatshSpacing.gutter,
                      BatshSpacing.md,
                      BatshSpacing.gutter,
                      BatshSpacing.gutter,
                    ),
                    child: Column(
                      children: List.generate(
                        4,
                        (_) => Padding(
                          padding: EdgeInsets.only(bottom: BatshSpacing.md),
                          child: JobCardSkeleton(),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: BatshError(
                    message: ErrorMapper.map(e),
                    onRetry: () =>
                        ref.invalidate(contractorOpportunitiesProvider),
                  ),
                ),
                data: (list) {
                  final quotedIds = ref
                      .watch(myQuotesProvider)
                      .maybeWhen(
                        data: (qs) => {for (final q in qs) q.briefId},
                        orElse: () => <String>{},
                      );
                  final filtered = _filterJobs(list, _activeFilters);
                  if (filtered.isEmpty) {
                    // "Nothing posted yet" and "nothing matched your words" need
                    // different exits: refresh in the first case, clear the
                    // search in the second.
                    return SliverFillRemaining(
                      child: query.isEmpty
                          ? BatshEmptyState(
                              title: S.noJobsTitle,
                              message: S.noJobsMessage,
                              icon: Icons.work_outline,
                              action: BatshButton(
                                label: S.tryAgain,
                                icon: Icons.refresh,
                                fullWidth: false,
                                onPressed: () => ref.invalidate(
                                  contractorOpportunitiesProvider,
                                ),
                              ),
                            )
                          // Jobs exist; the query hid them. Neutral, and the
                          // action undoes the search rather than offering work.
                          : BatshEmptyState(
                              kind: BatshEmptyStateKind.noResults,
                              title: S.noJobsMatchSearchTitle,
                              message: S.noJobsMatchSearchMessage,
                              icon: Icons.search_off_rounded,
                              action: BatshButton(
                                label: S.clearSearch,
                                icon: Icons.close_rounded,
                                fullWidth: false,
                                onPressed: _clearQuery,
                              ),
                            ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      // Near the end → pull the next page. The notifier
                      // guards against duplicate and exhausted fetches.
                      if (i >= filtered.length - 3) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref
                              .read(contractorOpportunitiesProvider.notifier)
                              .loadMore();
                        });
                      }
                      final brief = filtered[i];
                      final job = JobCardData.fromBrief(brief);
                      final reduced = MediaQuery.of(context).disableAnimations;
                      final card = PremiumJobCard(
                        job: job,
                        budgetLabel: null,
                        isUrgent: false,
                        alreadyQuoted: quotedIds.contains(brief.id),
                        onTap: () => context.push(
                          Routes.contractorPostDetailPath(brief.id),
                        ),
                        onQuote: () => _openQuote(context, brief.id),
                      );
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          BatshSpacing.gutter,
                          i == 0 ? BatshSpacing.md : 0,
                          BatshSpacing.gutter,
                          BatshSpacing.md,
                        ),
                        child: reduced
                            ? card
                            : card
                                  .animate()
                                  .fadeIn(
                                    duration: 350.ms,
                                    delay: BatshMotion.staggerClamped(i),
                                    curve: Curves.easeOutQuad,
                                  )
                                  .slideY(
                                    begin: 0.08,
                                    end: 0,
                                    duration: 350.ms,
                                    delay: BatshMotion.staggerClamped(i),
                                    curve: Curves.easeOutCubic,
                                  ),
                      );
                    }, childCount: filtered.length),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await BatshFilterSheet.show(
      context,
      sections: _filterSections,
      initialSelected: _activeFilters,
    );
    if (result != null) {
      setState(
        () => _activeFilters
          ..clear()
          ..addAll(result),
      );
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return S.greetingMorning;
    if (hour < 17) return S.greetingAfternoon;
    return S.greetingEvening;
  }

  // Free-text search now runs in the query (BriefsRepository.
  // fetchOpportunitiesForContractor). The client-side version could only match
  // rows already downloaded, which silently became wrong the moment the feed
  // was paginated.

  List<Brief> _filterJobs(List<Brief> jobs, Set<String> filters) {
    if (filters.isEmpty) return jobs;

    final specialties = SpecialtyFilter.selectedFrom(filters);
    final recency = RecencyFilter.fromKeys(filters);
    // One `now` for the whole pass, so a long list can't straddle the boundary.
    final now = DateTime.now();

    return jobs
        .where(
          (j) =>
              matchesSpecialtyFilters(j.targetSpecialties, specialties) &&
              matchesRecency(j.createdAt, recency, now),
        )
        .toList();
  }

  void _openQuote(BuildContext context, String briefId) {
    showQuoteSheet(context, briefId: briefId);
  }
}

// ─── Premium App Bar ────────────────────────────────────────────────────────

class _PremiumAppBar extends StatelessWidget {
  const _PremiumAppBar({
    required this.greeting,
    required this.name,
    this.avatarUrl,
    this.onTap,
  });
  final String greeting;
  final String name;

  /// Profile photo. Falls back to initials when absent, which is what the
  /// bubble always showed regardless of whether a photo existed.
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.gutter,
        BatshSpacing.md,
        BatshSpacing.gutter,
        BatshSpacing.md,
      ),
      child: Row(
        children: [
          // Tapping your own avatar to reach your profile is the convention
          // everywhere else, so the bubble is a target, not an ornament.
          GestureDetector(
            onTap: onTap,
            child: AvatarWithInitials(
              imageUrl: avatarUrl,
              name: name,
              radius: 22,
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting ${name.isNotEmpty ? name.split(' ')[0] : ''}',
                  style: BatshTypography.bodyMd.copyWith(
                    color: BatshColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  S.newJobs,
                  style: BatshTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // The notification bell and second search icon that used to sit here
          // were both no-ops (`onPressed: () {}`). Notifications land in M4;
          // search is the field directly below. A control that does nothing
          // costs more trust than the empty space costs polish.
        ],
      ),
    );
  }
}

// ─── Search Bar ──────────────────────────────────────────────────────────────

/// Real search input. It used to be a button whose only effect was scrolling
/// the list to the top, which read as search and did nothing of the kind.
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    // Repaint for the clear button appearing/disappearing.
    _listener = () => setState(() {});
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    return Container(
      height: 52,
      padding: const EdgeInsetsDirectional.only(
        start: BatshSpacing.gutter,
        end: BatshSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        boxShadow: BatshShadows.subtle,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: BatshIconSize.md,
            color: BatshColors.onSurfaceVariant,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: BatshTypography.bodyMd,
              decoration: InputDecoration(
                hintText: S.searchJobs,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: BatshTypography.bodyMd.copyWith(
                  color: BatshColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              tooltip: S.clearSearch,
              visualDensity: VisualDensity.compact,
              onPressed: widget.onClear,
              icon: Icon(
                Icons.close_rounded,
                size: BatshIconSize.md,
                color: BatshColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
