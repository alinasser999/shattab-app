import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/analytics/app_analytics.dart';
import '../../../core/l10n/catalog_labels.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import 'widgets/discover_cards.dart';
import 'widgets/discover_hero.dart';
import '../../../core/widgets/batsh_filter_sheet.dart';
import '../../../core/widgets/batsh_sheet.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../../core/widgets/contractor_card.dart';
import '../../../core/widgets/shattab_experience_state.dart';
import '../../../core/widgets/shattab_pattern.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/support_contact.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import '../domain/contractor_listing.dart';
import '../domain/professional_curation.dart';
import 'providers/discovery_providers.dart';
import 'professional_directory_screen.dart';
import '../../../core/widgets/batsh_search_bar.dart';
import '../../../core/widgets/batsh_section_header.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import 'widgets/featured_professional_card.dart';
import 'widgets/recent_work_rail.dart';
import 'widgets/sponsored_professional_rail.dart';

enum _DiscoverSortMode { topRated, newest }

/// Homeowner-facing professional discovery catalogue.
///
/// The hero and category shortcuts make the purpose of this tab clear, then
/// the rest of the screen stays focused on one searchable, saveable catalogue.
/// A single list avoids asking people to decode several overlapping rankings
/// before they can compare the professionals they came to find.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  // Owned here rather than by the hero: the hero rebuilds whenever the filters
  // change, and a controller created in a build method would detach from the
  // scroll view mid-gesture.
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounce;
  bool _loadingMore = false;
  Object? _paginationError;
  _DiscoverSortMode _sortMode = _DiscoverSortMode.topRated;
  final Map<String, bool> _optimisticSaved = <String, bool>{};

  int get _activeFilterCount {
    final f = ref.read(discoveryFiltersControllerProvider);
    return (f.specialty != null ? 1 : 0) + (f.city != null ? 1 : 0);
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final filters = ref.read(discoveryFiltersControllerProvider);
    final initial = <String>{};
    if (filters.specialty != null) {
      initial.add('specialty:${filters.specialty}');
    }
    if (filters.city != null) {
      initial.add('city:${filters.city}');
    }

    final specialties = OnboardingCatalog.specialtiesCatalog.keys
        .map(
          (key) => FilterOption(
            value: 'specialty:$key',
            label: localizedSpecialtyLabel(context, key),
            icon: Icons.category_rounded,
          ),
        )
        .toList();
    final cities = OnboardingCatalog.citiesAndDistricts
        .map(
          (c) => FilterOption(
            value: 'city:${c.city}',
            label: c.city,
            icon: Icons.location_on_rounded,
          ),
        )
        .toList();

    final sections = [
      BatshFilterSheetSection(
        title: context.l10n.filterCategory,
        icon: Icons.category_rounded,
        singleSelect: true,
        options: specialties,
      ),
      BatshFilterSheetSection(
        title: context.l10n.filterCity,
        icon: Icons.location_on_rounded,
        singleSelect: true,
        options: cities,
      ),
    ];

    final result = await BatshFilterSheet.show(
      context,
      sections: sections,
      initialSelected: initial,
    );

    if (result != null) {
      final ctrl = ref.read(discoveryFiltersControllerProvider.notifier);
      final specialtyKey = result.firstWhere(
        (v) => v.startsWith('specialty:'),
        orElse: () => '',
      );
      final cityKey = result.firstWhere(
        (v) => v.startsWith('city:'),
        orElse: () => '',
      );
      ctrl.setSpecialty(
        specialtyKey.isNotEmpty
            ? specialtyKey.replaceFirst('specialty:', '')
            : null,
      );
      ctrl.setCity(
        cityKey.isNotEmpty ? cityKey.replaceFirst('city:', '') : null,
      );
    }
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    final filters = ref.read(discoveryFiltersControllerProvider);
    final profileCity = ref.read(homeownerProfileProvider).value?.city;
    final selected = await BatshSheet.show<String>(
      context,
      contentPadding: EdgeInsets.zero,
      builder: (_) => _LocationPickerSheet(
        currentCity: filters.city ?? profileCity,
        profileCity: profileCity,
      ),
    );

    if (!mounted || selected == null) return;

    ref
        .read(discoveryFiltersControllerProvider.notifier)
        .setCity(selected.isEmpty ? null : selected);
    unawaited(
      AppAnalytics.track(
        'discovery_location_changed',
        properties: {'has_city_filter': selected.isNotEmpty},
      ),
    );

    if (_scrollCtrl.hasClients) {
      await _scrollCtrl.animateTo(
        0,
        duration: BatshMotion.normal,
        curve: BatshMotion.easeOut,
      );
    }
  }

  bool get _hasMore => ref.read(discoverContractorsProvider.notifier).hasMore;

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
    });
    try {
      await ref.read(discoverContractorsProvider.notifier).loadMore();
    } catch (error) {
      if (mounted) setState(() => _paginationError = error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(discoverContractorsProvider);
    await ref.read(discoverContractorsProvider.future);
  }

  Future<void> _toggleSaved({
    required String contractorId,
    required bool currentlySaved,
  }) async {
    if (_optimisticSaved.containsKey(contractorId)) return;
    if (mounted) {
      setState(() => _optimisticSaved[contractorId] = !currentlySaved);
    }
    try {
      await ref.read(savedControllerProvider.notifier).toggle(contractorId);
      if (mounted) setState(() => _optimisticSaved.remove(contractorId));
    } catch (error) {
      if (!mounted) return;
      setState(() => _optimisticSaved.remove(contractorId));
      BatshSnack.error(context, ErrorMapper.map(error));
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.extentAfter < 520) _loadMore();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String? _discoveryReason(
    BuildContext context,
    ContractorListing listing,
    String? browseCity,
  ) {
    if (browseCity != null && listing.serviceAreas.contains(browseCity)) {
      return context.l10n.nearYouIn(browseCity);
    }
    if (listing.verified) return context.l10n.verifiedIdentity;
    if (listing.hasReviews) {
      return context.l10n.verifiedReviewFromCompletedJob;
    }
    if (listing.projectsCompleted > 0) {
      return '${listing.projectsCompleted} ${context.l10n.completedProjectsShort}';
    }
    return null;
  }

  /// Handed to the hero rather than placed beside it, so the field keeps its
  /// element — and therefore its focus and its keyboard — when the hero
  /// collapses the moment a query is typed.
  Widget _buildSearchRow() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BatshSearchBar(
            hintText: context.l10n.discoverSearchHint,
            controller: _searchCtrl,
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                ref
                    .read(discoveryFiltersControllerProvider.notifier)
                    .setSearch(v);
              });
            },
            onClear: () {
              _searchCtrl.clear();
              ref
                  .read(discoveryFiltersControllerProvider.notifier)
                  .setSearch(null);
            },
          ),
          const SizedBox(height: BatshSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _DiscoverSortButton(
                  mode: _sortMode,
                  onSelected: (mode) => setState(() => _sortMode = mode),
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              BatshFilterButton(
                activeCount: _activeFilterCount,
                onTap: () => _openFilterSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const ProfessionalDirectoryScreen();

  // Kept temporarily as a compatibility reference while the new catalogue
  // settles. It is not mounted by the route; the provider and interaction
  // contracts remain here for an easy rollback without losing the old flow.
  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
    final filters = ref.watch(discoveryFiltersControllerProvider);
    final contractorsAsync = ref.watch(discoverContractorsProvider);
    final sponsoredAsync = ref.watch(
      sponsoredProfessionalsProvider(filters.specialty, filters.city),
    );
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? {};

    return BatshScaffold(
      // No app bar. It carried a title the bottom nav already says, and a bar
      // above a full-bleed cover is a frame around a photograph.
      showAppBar: false,
      padding: EdgeInsets.zero,
      body: contractorsAsync.when(
        loading: () => const _DiscoverSkeleton(),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(BatshSpacing.gutter),
          child: ShattabExperienceState(
            icon: Icons.cloud_off_outlined,
            title: context.l10n.unknownErrorRetry,
            message: ErrorMapper.map(e),
            actionLabel: context.l10n.tryAgain,
            onAction: () => ref.invalidate(discoverContractorsProvider),
            secondaryActionLabel: context.l10n.helpSupport,
            onSecondaryAction: () => openShattabSupport(context),
            pattern: ShattabPatternKind.contour,
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            final filtered = !filters.isEmpty;
            return Padding(
              padding: const EdgeInsets.all(BatshSpacing.gutter),
              child: ShattabExperienceState(
                icon: filtered
                    ? Icons.filter_alt_off_outlined
                    : Icons.search_off_outlined,
                title: filtered
                    ? context.l10n.noResultsFound
                    : context.l10n.noContractorsTitle,
                message: filtered
                    ? context.l10n.noContractorsMessage
                    : context.l10n.noContractorsMessage,
                actionLabel: filtered
                    ? context.l10n.clearFilters
                    : context.l10n.tryAgain,
                onAction: () {
                  if (filtered) {
                    _searchCtrl.clear();
                    ref
                        .read(discoveryFiltersControllerProvider.notifier)
                        .clear();
                  } else {
                    ref.invalidate(discoverContractorsProvider);
                  }
                },
                pattern: filtered
                    ? ShattabPatternKind.lattice
                    : ShattabPatternKind.arches,
              ),
            );
          }

          final myCity = ref.watch(homeownerProfileProvider).value?.city;
          final browseCity = filters.city ?? myCity;
          final visibleList = [...list]
            ..sort((a, b) {
              if (_sortMode == _DiscoverSortMode.newest) {
                final aDate =
                    a.memberSince ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bDate =
                    b.memberSince ?? DateTime.fromMillisecondsSinceEpoch(0);
                final byDate = bDate.compareTo(aDate);
                return byDate != 0 ? byDate : a.id.compareTo(b.id);
              }

              final byRating = (b.rating ?? -1).compareTo(a.rating ?? -1);
              if (byRating != 0) return byRating;
              final byReviews = b.reviewCount.compareTo(a.reviewCount);
              if (byReviews != 0) return byReviews;
              final byProjects = b.projectsCompleted.compareTo(
                a.projectsCompleted,
              );
              return byProjects != 0 ? byProjects : a.id.compareTo(b.id);
            });

          final showShelves = filters.isEmpty;
          final pool = visibleList.take(20);
          final featured = showShelves ? pickFeaturedProfessional(pool) : null;
          final topRated = showShelves
              ? rankTopRated(pool, limit: 5)
              : <ContractorListing>[];
          final topRatedList = featured == null
              ? topRated
              : topRated.where((item) => item.id != featured.id).toList();
          final nearYou =
              (showShelves && browseCity != null && browseCity.isNotEmpty)
              ? rankNearbyProfessionals(pool, browseCity)
              : <ContractorListing>[];
          final shelfIds = {
            if (featured != null) featured.id,
            ...topRated.map((item) => item.id),
          };
          final rest = shelfIds.isEmpty
              ? visibleList
              : visibleList
                    .where((item) => !shelfIds.contains(item.id))
                    .toList();

          void open(String id) =>
              context.push(Routes.homeownerContractorProfilePath(id));

          SliverToBoxAdapter header(
            String title, {
            BatshSectionEmphasis emphasis = BatshSectionEmphasis.standard,
            VoidCallback? onViewAll,
          }) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BatshSpacing.sectionH,
                BatshSpacing.md,
                BatshSpacing.sectionH,
                BatshSpacing.xs,
              ),
              child: BatshSectionHeader(
                title: title,
                emphasis: emphasis,
                padding: EdgeInsets.zero,
                trailing: onViewAll == null
                    ? null
                    : TextButton(
                        onPressed: onViewAll,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: BatshSpacing.xs,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(context.l10n.viewAll),
                            const SizedBox(width: BatshSpacing.xxs),
                            const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );

          Widget reveal(Widget child, int index) {
            if (MediaQuery.disableAnimationsOf(context)) return child;
            return child
                .animate()
                .fadeIn(
                  delay: BatshMotion.staggerClamped(index),
                  duration: BatshMotion.normal,
                  curve: BatshMotion.easeOut,
                )
                .slideY(begin: 0.05, end: 0, curve: BatshMotion.easeOut);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              key: const PageStorageKey<String>('homeowner-discover-scroll'),
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: DiscoverHero(
                    searchRow: _buildSearchRow(),
                    collapsed: !filters.isEmpty,
                    coverUrl: null,
                    locationLabel: browseCity,
                    unreadCount: ref.watch(unreadNotificationsProvider),
                    onLocationTap: () => _openLocationPicker(context),
                    onNotificationTap: () => context.push(Routes.notifications),
                  ),
                ),
                if (filters.specialty != null || filters.city != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        BatshSpacing.sectionH,
                        BatshSpacing.md,
                        BatshSpacing.sectionH,
                        0,
                      ),
                      child: SizedBox(
                        height: 30,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (filters.specialty != null)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: BatshSpacing.xs,
                                ),
                                child: BatshActiveFilterChip(
                                  label: localizedSpecialtyLabel(
                                    context,
                                    filters.specialty!,
                                  ),
                                  onRemove: () => ref
                                      .read(
                                        discoveryFiltersControllerProvider
                                            .notifier,
                                      )
                                      .setSpecialty(null),
                                ),
                              ),
                            if (filters.city != null)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: BatshSpacing.xs,
                                ),
                                child: BatshActiveFilterChip(
                                  label: filters.city!,
                                  onRemove: () => ref
                                      .read(
                                        discoveryFiltersControllerProvider
                                            .notifier,
                                      )
                                      .setCity(null),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (showShelves) ...[
                  const SliverToBoxAdapter(
                    child: SizedBox(height: BatshSpacing.md),
                  ),
                  SliverToBoxAdapter(
                    child: CategoryStrip(
                      onSelect: (key) => ref
                          .read(discoveryFiltersControllerProvider.notifier)
                          .setSpecialty(key),
                      onMore: () => _openFilterSheet(context),
                    ),
                  ),
                ],
                if (filters.searchQuery?.trim().isEmpty != false &&
                    sponsoredAsync.hasValue &&
                    sponsoredAsync.value!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SponsoredProfessionalRail(
                      listings: sponsoredAsync.value!,
                      onTap: (listing) => open(listing.id),
                    ),
                  ),
                if (featured != null) ...[
                  header(
                    context.l10n.featuredProfessional,
                    emphasis: BatshSectionEmphasis.major,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.sectionH,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: reveal(
                        FeaturedProfessionalCard(
                          listing: featured,
                          onTap: () => open(featured.id),
                        ),
                        0,
                      ),
                    ),
                  ),
                ],
                if (showShelves)
                  SliverToBoxAdapter(
                    child: RecentWorkRail(fallbackContractorId: featured?.id),
                  ),
                if (nearYou.isNotEmpty) ...[
                  header(
                    context.l10n.nearYouIn(browseCity!),
                    onViewAll: () => context.push(
                      Routes.homeownerNearbyProfessionalsPath(browseCity),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: NearbyProfessionalCard.height,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: BatshSpacing.sectionH,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: nearYou.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: BatshSpacing.md),
                        itemBuilder: (_, index) => reveal(
                          NearbyProfessionalCard(
                            listing: nearYou[index],
                            onTap: () => open(nearYou[index].id),
                          ),
                          index,
                        ),
                      ),
                    ),
                  ),
                ],
                if (topRatedList.isNotEmpty) ...[
                  header(
                    context.l10n.topRated,
                    onViewAll: () =>
                        context.push(Routes.homeownerTopRatedProfessionals),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.sectionH,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLowest,
                          borderRadius: BatshRadius.brCard,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BatshSpacing.md,
                          ),
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < topRatedList.length;
                                index++
                              ) ...[
                                if (index > 0)
                                  Divider(
                                    height: 1,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                reveal(
                                  RankedProfessionalTile(
                                    rank: index + 1,
                                    listing: topRatedList[index],
                                    onTap: () => open(topRatedList[index].id),
                                  ),
                                  index,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (rest.isNotEmpty) ...[
                  header(
                    '${context.l10n.allProfessionals} (${rest.length})',
                    emphasis: BatshSectionEmphasis.major,
                    onViewAll: () =>
                        context.push(Routes.homeownerAllProfessionals),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.sectionH,
                      0,
                      BatshSpacing.sectionH,
                      BatshSpacing.xxl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == rest.length) {
                          return _DiscoverFooter(
                            loading: _loadingMore,
                            error: _paginationError,
                            hasMore: _hasMore,
                            onRetry: _loadMore,
                          );
                        }

                        if (index >= rest.length - 3) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _loadMore();
                          });
                        }

                        final item = rest[index];
                        final isSaved =
                            _optimisticSaved[item.id] ??
                            savedIds.contains(item.id);
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: BatshSpacing.lg,
                          ),
                          child: reveal(
                            ContractorCard(
                              listing: item,
                              isSaved: isSaved,
                              discoveryReason: _discoveryReason(
                                context,
                                item,
                                browseCity,
                              ),
                              onToggleSave: () => runSignedIn(
                                context,
                                ref,
                                reason: context.l10n.signInToSave,
                                action: () => _toggleSaved(
                                  contractorId: item.id,
                                  currentlySaved: savedIds.contains(item.id),
                                ),
                              ),
                              onTap: () => open(item.id),
                            ),
                            index,
                          ),
                        );
                      }, childCount: rest.length + 1),
                    ),
                  ),
                ] else
                  SliverToBoxAdapter(
                    child: _DiscoverFooter(
                      loading: _loadingMore,
                      error: _paginationError,
                      hasMore: _hasMore,
                      onRetry: _loadMore,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: BatshBottomNav.contentBottomInset(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DiscoverSortButton extends StatelessWidget {
  const _DiscoverSortButton({required this.mode, required this.onSelected});

  final _DiscoverSortMode mode;
  final ValueChanged<_DiscoverSortMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = mode == _DiscoverSortMode.topRated
        ? context.l10n.topRated
        : context.l10n.filterNewestFirst;
    return PopupMenuButton<_DiscoverSortMode>(
      tooltip: context.l10n.topRated,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _DiscoverSortMode.topRated,
          child: Text(context.l10n.topRated),
        ),
        PopupMenuItem(
          value: _DiscoverSortMode.newest,
          child: Text(context.l10n.filterNewestFirst),
        ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brFull,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: BatshIconSize.md,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: BatshSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPickerSheet extends StatelessWidget {
  const _LocationPickerSheet({this.currentCity, this.profileCity});

  final String? currentCity;
  final String? profileCity;

  @override
  Widget build(BuildContext context) {
    final cities = OnboardingCatalog.citiesAndDistricts;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.lg,
            BatshSpacing.md,
            BatshSpacing.lg,
            BatshSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: colorScheme.primary,
                  size: BatshIconSize.md,
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.changeLocation,
                      style: BatshTypography.titleLg.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.xxs),
                    Text(
                      context.l10n.changeLocationDescription,
                      style: BatshTypography.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.52,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.lg,
              BatshSpacing.sm,
              BatshSpacing.lg,
              BatshSpacing.sm,
            ),
            itemCount: cities.length,
            separatorBuilder: (_, _) => const SizedBox(height: BatshSpacing.xs),
            itemBuilder: (context, index) {
              final city = cities[index].city;
              return _LocationPickerOption(
                label: city,
                selected: currentCity == city,
                onTap: () => Navigator.of(context).pop(city),
              );
            },
          ),
        ),
        if (profileCity != null && profileCity!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.lg,
              BatshSpacing.sm,
              BatshSpacing.lg,
              BatshSpacing.lg,
            ),
            child: _LocationPickerOption(
              label: context.l10n.useProfileLocation,
              selected: currentCity == profileCity,
              icon: Icons.home_outlined,
              onTap: () => Navigator.of(context).pop(''),
            ),
          ),
      ],
    );
  }
}

class _LocationPickerOption extends StatelessWidget {
  const _LocationPickerOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon = Icons.location_city_outlined,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = selected
        ? colorScheme.primary.withValues(alpha: 0.45)
        : colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? colorScheme.primaryFixed
            : colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brMd,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.md,
              vertical: BatshSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brMd,
              border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: BatshIconSize.md,
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.start,
                    style: BatshTypography.labelLg.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colorScheme.primary : colorScheme.outline,
                  size: BatshIconSize.md,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverFooter extends StatelessWidget {
  const _DiscoverFooter({
    required this.loading,
    required this.error,
    required this.hasMore,
    required this.onRetry,
  });

  final bool loading;
  final Object? error;
  final bool hasMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const BatshPaginationSkeleton();
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.tryAgain),
        ),
      );
    }
    return Semantics(
      label: hasMore ? context.l10n.loadingMore : context.l10n.allProfessionals,
      child: const SizedBox(height: BatshSpacing.md),
    );
  }
}

/// The same composition in grey, so the swap to content shifts nothing.
class _DiscoverSkeleton extends StatelessWidget {
  const _DiscoverSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // Hero: the cover, with the search pill hanging off its edge.
        SizedBox(
          height: 286,
          child: Stack(
            children: [
              const Positioned.fill(
                top: 0,
                left: 0,
                right: 0,
                child: BatshShimmerBox(
                  height: 286,
                  borderRadius: BatshRadius.brXs,
                ),
              ),
              PositionedDirectional(
                start: BatshSpacing.sectionH,
                end: BatshSpacing.sectionH,
                bottom: BatshSpacing.sm,
                child: const BatshShimmerBox(
                  height: 52,
                  borderRadius: BatshRadius.brFull,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.lg),
        SizedBox(
          height: CategoryStrip.heightFor(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.sectionH,
            ),
            itemCount: 6,
            separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.sm),
            itemBuilder: (_, _) => const BatshShimmerBox(
              width: 60,
              height: 60,
              borderRadius: BatshRadius.brFull,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.sectionH,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BatshShimmerBox(
                width: 120,
                height: 20,
                borderRadius: BatshRadius.brXs,
              ),
              const SizedBox(height: BatshSpacing.md),
              for (var i = 0; i < 3; i++) ...[
                const _DiscoverListingSkeleton(),
                if (i < 2) const SizedBox(height: BatshSpacing.lg),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscoverListingSkeleton extends StatelessWidget {
  const _DiscoverListingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brCard,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BatshShimmerBox(
            height: 190,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(BatshRadius.card),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(BatshSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                BatshShimmerBox(width: 160, height: 16),
                SizedBox(height: BatshSpacing.sm),
                BatshShimmerBox(width: double.infinity, height: 12),
                SizedBox(height: BatshSpacing.xs),
                BatshShimmerBox(width: 110, height: 12),
                SizedBox(height: BatshSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: BatshShimmerBox(width: 96, height: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
