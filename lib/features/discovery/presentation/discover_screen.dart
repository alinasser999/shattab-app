import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/l10n/catalog_labels.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import 'widgets/discover_cards.dart';
import 'widgets/featured_professional_card.dart';
import 'widgets/discover_hero.dart';
import 'widgets/recent_work_rail.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_filter_sheet.dart';
import '../../../core/widgets/batsh_sheet.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/contractor_card.dart';
import '../../../core/utils/error_mapper.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import '../domain/contractor_listing.dart';
import '../domain/professional_curation.dart';
import 'providers/discovery_providers.dart';
import '../../../core/widgets/batsh_search_bar.dart';
import '../../../core/widgets/batsh_section_header.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';

/// Discover, composed as a magazine rather than as a feed.
///
/// The screen used to be four stacked lists — a search bar, a chip row, two
/// identical contractor rails and a column of the same card again — under an
/// app bar that named the tab the bottom nav had already named. Everything
/// looked equally important, so the eye had nowhere to land, and the
/// photography, the only thing that sells a renovation, was never bigger than
/// a thumbnail.
///
/// The order now descends in weight: a full-bleed [DiscoverHero] with the
/// search field on its edge, a glyph row for one-tap browse, exactly one
/// [FeaturedProfessionalCard] carrying the screen's only primary button, then
/// the work itself, then quieter nearby and ranked sections, then the full
/// catalogue. Nothing about the data, filters, or paging changes.
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

    if (_scrollCtrl.hasClients) {
      await _scrollCtrl.animateTo(
        0,
        duration: BatshMotion.normal,
        curve: BatshMotion.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Handed to the hero rather than placed beside it, so the field keeps its
  /// element — and therefore its focus and its keyboard — when the hero
  /// collapses the moment a query is typed.
  Widget _buildSearchRow() {
    return Directionality(
      // The reference composition keeps the search field wide on the left and
      // the filter action tucked on the right; the field itself remains RTL.
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: BatshSearchBar(
                hintText: context.l10n.searchHint,
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
            ),
          ),
          const SizedBox(width: BatshSpacing.xs),
          Directionality(
            textDirection: TextDirection.rtl,
            child: BatshFilterButton(
              activeCount: _activeFilterCount,
              onTap: () => _openFilterSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(discoveryFiltersControllerProvider);
    final contractorsAsync = ref.watch(discoverContractorsProvider);
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? {};

    return BatshScaffold(
      // No app bar. It carried a title the bottom nav already says, and a bar
      // above a full-bleed cover is a frame around a photograph.
      showAppBar: false,
      padding: EdgeInsets.zero,
      body: contractorsAsync.when(
        loading: () => const _DiscoverSkeleton(),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(discoverContractorsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: BatshEmptyState(
                title: context.l10n.noContractorsTitle,
                message: context.l10n.noContractorsMessage,
                icon: Icons.search_off_outlined,
                kind: filters.isEmpty
                    ? BatshEmptyStateKind.nothingYet
                    : BatshEmptyStateKind.noResults,
                action: OutlinedButton(
                  onPressed: () {
                    if (filters.isEmpty) {
                      ref.invalidate(discoverContractorsProvider);
                    } else {
                      _searchCtrl.clear();
                      ref
                          .read(discoveryFiltersControllerProvider.notifier)
                          .clear();
                    }
                  },
                  child: Text(
                    filters.isEmpty
                        ? context.l10n.tryAgain
                        : context.l10n.clearFilters,
                  ),
                ),
              ),
            );
          }

          const shelfPool = 20;
          final showShelves = filters.isEmpty;
          final pool = list.take(shelfPool);
          final featured = showShelves ? pickFeaturedProfessional(pool) : null;
          final topRated = showShelves
              ? rankTopRated(pool, limit: 5)
              : <ContractorListing>[];
          final topRatedList = featured == null
              ? topRated
              : topRated.where((c) => c.id != featured.id).toList();
          final myCity = ref.watch(homeownerProfileProvider).value?.city;
          final browseCity = filters.city ?? myCity;
          final nearYou =
              (showShelves && browseCity != null && browseCity.isNotEmpty)
              ? rankNearbyProfessionals(pool, browseCity)
              : <ContractorListing>[];
          final showNearYou = nearYou.isNotEmpty;
          final shelfIds = {
            if (featured != null) featured.id,
            ...topRated.map((c) => c.id),
          };
          final rest = shelfIds.isEmpty
              ? list
              : list.where((c) => !shelfIds.contains(c.id)).toList();

          void open(String id) =>
              context.push(Routes.homeownerContractorProfilePath(id));

          // Every section title sits on the same rhythm: a section-sized gap
          // above it, a sibling-sized one below. The header widget's own
          // padding is zeroed so the spacing is decided here, in one place.
          //
          // [major] is spent twice on this screen and no more: on the one
          // professional it argues for, and on the catalogue the whole tab
          // exists to open. The proximity and rating shelves stay standard —
          // they are the supporting cast, and saying so in type is what makes
          // the other two land.
          SliverToBoxAdapter header(
            String title, {
            BatshSectionEmphasis emphasis = BatshSectionEmphasis.standard,
            VoidCallback? onViewAll,
            Key? key,
          }) => SliverToBoxAdapter(
            key: key,
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
            onRefresh: () async {
              ref.invalidate(discoverContractorsProvider);
              await ref.read(discoverContractorsProvider.future);
            },
            child: CustomScrollView(
              key: const PageStorageKey<String>('homeowner-discover-scroll'),
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: DiscoverHero(
                    searchRow: _buildSearchRow(),
                    collapsed: !filters.isEmpty,
                    // Use the art-directed visual fallback for the cover. A
                    // professional's real cover still powers their card and
                    // public profile; this keeps the browse hero intentional
                    // when the catalog has no agreed campaign asset.
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
                if (filters.isEmpty) ...[
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
                // Only while browsing. Once a filter is on, the homeowner is
                // in a task — "a plumber in Giza" — and a rail of unrelated
                // finished work is something to scroll past on the way to the
                // list they asked for.
                if (filters.isEmpty)
                  SliverToBoxAdapter(
                    child: RecentWorkRail(fallbackContractorId: featured?.id),
                  ),
                if (showNearYou) ...[
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
                      delegate: SliverChildBuilderDelegate((context, i) {
                        // Near the end → pull the next page. Notifier guards
                        // against duplicate in-flight / exhausted fetches.
                        if (i >= rest.length - 3) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ref
                                .read(discoverContractorsProvider.notifier)
                                .loadMore();
                          });
                        }
                        final item = rest[i];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: BatshSpacing.lg,
                          ),
                          child: reveal(
                            ContractorCard(
                              listing: item,
                              isSaved: savedIds.contains(item.id),
                              onToggleSave: () => runSignedIn(
                                context,
                                ref,
                                reason: context.l10n.signInToSave,
                                action: () => ref
                                    .read(savedControllerProvider.notifier)
                                    .toggle(item.id),
                              ),
                              onTap: () => open(item.id),
                            ),
                            i,
                          ),
                        );
                      }, childCount: rest.length),
                    ),
                  ),
                ],
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
          height: 324,
          child: Stack(
            children: [
              const Positioned.fill(
                top: 0,
                left: 0,
                right: 0,
                child: BatshShimmerBox(
                  height: 324,
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
        const SizedBox(height: BatshSpacing.xxl),
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
              // The featured card's own silhouette, not a rectangle standing
              // in for it — the swap to content must not move anything.
              const FeaturedProfessionalCardSkeleton(),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.xxl),
        SizedBox(
          height: NearbyProfessionalCard.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.sectionH,
            ),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.md),
            itemBuilder: (_, _) => const BatshShimmerBox(
              width: NearbyProfessionalCard.width,
              height: NearbyProfessionalCard.height,
              borderRadius: BatshRadius.brImage,
            ),
          ),
        ),
      ],
    );
  }
}
