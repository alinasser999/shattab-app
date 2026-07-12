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
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_filter_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../quotes/presentation/quote_sheet.dart';
import '../../../quotes/presentation/providers/quotes_providers.dart';
import '../../domain/brief.dart';
import '../providers/briefs_providers.dart';
import 'widgets/job_card.dart';
import 'widgets/job_card_skeleton.dart';

class JobOpportunitiesScreen extends ConsumerStatefulWidget {
  const JobOpportunitiesScreen({super.key});

  @override
  ConsumerState<JobOpportunitiesScreen> createState() =>
      _JobOpportunitiesScreenState();
}

class _JobOpportunitiesScreenState
    extends ConsumerState<JobOpportunitiesScreen> {
  final _scrollController = ScrollController();
  final Set<String> _activeFilters = {};

  static final _filterSections = [
    BatshFilterSheetSection(
      title: S.filterSort,
      icon: Icons.swap_vert_rounded,
      singleSelect: true,
          options: [
        FilterOption(value: S.filterNewestFirst, label: S.filterNewestFirst, icon: Icons.fiber_new_rounded),
        FilterOption(value: S.filterNearest, label: S.filterNearest, icon: Icons.near_me_rounded),
        FilterOption(value: S.filterHighestBudget, label: S.filterHighestBudget, icon: Icons.trending_up_rounded),
      ],
    ),
    BatshFilterSheetSection(
      title: S.filterCategory,
      icon: Icons.category_rounded,
      options: [
        FilterOption(value: S.filterPainting, label: S.filterPainting, icon: Icons.format_paint),
        FilterOption(value: S.filterElectrical, label: S.filterElectrical, icon: Icons.electrical_services),
        FilterOption(value: S.filterPlumbing, label: S.filterPlumbing, icon: Icons.plumbing),
        FilterOption(value: S.filterFinishing, label: S.filterFinishing, icon: Icons.build),
        FilterOption(value: S.filterBathrooms, label: S.filterBathrooms, icon: Icons.bathtub_outlined),
        FilterOption(value: S.filterKitchens, label: S.filterKitchens, icon: Icons.countertops_outlined),
      ],
    ),
    BatshFilterSheetSection(
      title: S.filterTime,
      icon: Icons.schedule_rounded,
      singleSelect: true,
      options: [
        FilterOption(value: S.filterToday, label: S.filterToday, icon: Icons.today),
        FilterOption(value: S.filterThisWeek, label: S.filterThisWeek, icon: Icons.date_range_rounded),
        FilterOption(value: S.filterThisMonth, label: S.filterThisMonth, icon: Icons.calendar_month_rounded),
      ],
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(contractorOpportunitiesProvider);
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
            SliverToBoxAdapter(child: _PremiumAppBar(greeting: greeting, name: name)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  BatshSpacing.gutter, 0, BatshSpacing.gutter, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _SearchBar(
                        onTap: () {
                          _scrollController.animateTo(
                            0, duration: BatshMotion.normal, curve: BatshMotion.easeOut);
                        },
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
                        onTap: () =>
                            context.push(Routes.contractorMyQuotes),
                        child: Container(
                          height: 48,
                          width: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BatshRadius.brFull,
                            boxShadow: BatshShadows.soft,
                          ),
                          child: Icon(Icons.receipt_long_outlined,
                              color: BatshColors.primary, size: 22),
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
                    BatshSpacing.gutter, BatshSpacing.sm, BatshSpacing.gutter, 0),
                  child: SizedBox(
                    height: 30,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _activeFilters.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.xs),
                      itemBuilder: (_, i) {
                        if (i < _activeFilters.length) {
                          final filter = _activeFilters.elementAt(i);
                          return BatshActiveFilterChip(
                            label: filter,
                            onRemove: () => setState(() => _activeFilters.remove(filter)),
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
                    BatshSpacing.gutter, BatshSpacing.md, BatshSpacing.gutter, BatshSpacing.gutter),
                  child: Column(
                    children: List.generate(4, (_) => Padding(
                      padding: EdgeInsets.only(bottom: BatshSpacing.md),
                      child: JobCardSkeleton(),
                    )),
                  ),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: BatshError(
                  message: ErrorMapper.map(e),
                  onRetry: () => ref.invalidate(contractorOpportunitiesProvider),
                ),
              ),
              data: (list) {
                final quotedIds = ref.watch(myQuotesProvider).maybeWhen(
                      data: (qs) => {for (final q in qs) q.briefId},
                      orElse: () => <String>{},
                    );
                final filtered = _filterJobs(list, _activeFilters);
                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyJobsState(
                      onRefresh: () => ref.invalidate(contractorOpportunitiesProvider),
                    ),
                  );
                }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
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
                      },
                      childCount: filtered.length,
                    ),
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
      setState(() => _activeFilters
        ..clear()
        ..addAll(result));
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return S.greetingMorning;
    if (hour < 17) return S.greetingAfternoon;
    return S.greetingEvening;
  }

  List<Brief> _filterJobs(List<Brief> jobs, Set<String> filters) {
    if (filters.isEmpty) return jobs;
    var filtered = jobs;

    final specialtyFilters = <String>{
      S.filterPainting, S.filterElectrical, S.filterPlumbing,
      S.filterFinishing, S.filterBathrooms, S.filterKitchens,
    }.intersection(filters);

    if (specialtyFilters.isNotEmpty) {
      filtered = filtered.where((j) =>
        j.targetSpecialties.any((s) {
          if (specialtyFilters.contains(S.filterPainting)) return s.contains('paint') || s.contains('دهان');
          if (specialtyFilters.contains(S.filterElectrical)) return s.contains('electrical') || s.contains('كهرب');
          if (specialtyFilters.contains(S.filterPlumbing)) return s.contains('plumbing') || s.contains('سباك');
          if (specialtyFilters.contains(S.filterFinishing)) return s.contains('full_reno') || s.contains('تشطيب');
          if (specialtyFilters.contains(S.filterBathrooms)) return s.contains('bathroom') || s.contains('حمام');
          if (specialtyFilters.contains(S.filterKitchens)) return s.contains('kitchen') || s.contains('مطب');
          return false;
        }),
      ).toList();
    }

    if (filters.contains(S.filterToday)) {
      filtered = filtered.where((j) =>
        j.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 24)))).toList();
    }
    if (filters.contains(S.filterThisWeek)) {
      filtered = filtered.where((j) =>
        j.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
    }
    if (filters.contains(S.filterThisMonth)) {
      filtered = filtered.where((j) =>
        j.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))).toList();
    }

    return filtered;
  }

  void _openQuote(BuildContext context, String briefId) {
    showQuoteSheet(context, briefId: briefId);
  }
}

// ─── Premium App Bar ────────────────────────────────────────────────────────

class _PremiumAppBar extends StatelessWidget {
  const _PremiumAppBar({required this.greeting, required this.name});
  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.gutter, BatshSpacing.md, BatshSpacing.gutter, BatshSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BatshColors.primaryFixed.withValues(alpha: 0.4),
              borderRadius: BatshRadius.brFull,
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name.characters.first : '',
              style: BatshTypography.titleMd.copyWith(
                color: BatshColors.primary,
                fontWeight: FontWeight.w700,
              ),
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
                  style: BatshTypography.titleMd.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          _IconButton(Icons.notifications_outlined, color: BatshColors.onSurfaceVariant),
          const SizedBox(width: BatshSpacing.sm),
          _IconButton(Icons.search, color: BatshColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton(this.icon, {required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLow,
        borderRadius: BatshRadius.brFull,
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, size: 22, color: color),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

// ─── Search Bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BatshColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          decoration: BoxDecoration(
            color: BatshColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(26),
            boxShadow: BatshShadows.subtle,
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 22, color: BatshColors.onSurfaceVariant),
              const SizedBox(width: BatshSpacing.sm),
              Text(
                S.searchJobs,
                style: BatshTypography.bodyMd.copyWith(
                  color: BatshColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyJobsState extends StatelessWidget {
  const _EmptyJobsState({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: BatshColors.primaryFixed.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.work_outline,
                size: 40, color: BatshColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: BatshSpacing.lg),
          Text(
            S.noJobsTitle,
            style: BatshTypography.titleLg.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            S.noJobsMessage,
            textAlign: TextAlign.center,
            style: BatshTypography.bodyMd.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          BatshButton(
            label: S.tryAgain,
            icon: Icons.refresh,
            fullWidth: false,
            onPressed: onRefresh,
          ),
          const Spacer(),
          const SizedBox(height: BatshSpacing.xl),
        ],
      ),
    );
  }
}
