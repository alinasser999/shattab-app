import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/l10n/catalog_labels.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/support_contact.dart';
import '../../../core/widgets/avatar_with_initials.dart';
import '../../../core/widgets/batsh_filter_sheet.dart';
import '../../../core/widgets/batsh_pressable.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_search_bar.dart';
import '../../../core/widgets/batsh_sheet.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../../core/widgets/shattab_experience_state.dart';
import '../../../core/widgets/shattab_pattern.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import '../domain/contractor_listing.dart';
import 'providers/discovery_providers.dart';
import 'widgets/mockup_assets.dart';
import 'widgets/recent_work_rail.dart';

enum _DirectorySort { recommended, newest }

/// Homeowner-facing professional catalogue.
///
/// This is intentionally a catalogue rather than a second campaign homepage:
/// the first viewport puts search, proof and the profile action ahead of
/// decoration while the Shattab pattern language stays in the background.
class ProfessionalDirectoryScreen extends ConsumerStatefulWidget {
  const ProfessionalDirectoryScreen({super.key});

  @override
  ConsumerState<ProfessionalDirectoryScreen> createState() =>
      _ProfessionalDirectoryScreenState();
}

class _ProfessionalDirectoryScreenState
    extends ConsumerState<ProfessionalDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _optimisticSaved = <String, bool>{};
  Timer? _searchDebounce;
  bool _loadingMore = false;
  Object? _paginationError;
  _DirectorySort _sort = _DirectorySort.recommended;

  int get _activeFilterCount {
    final filters = ref.read(discoveryFiltersControllerProvider);
    return (filters.specialty == null ? 0 : 1) + (filters.city == null ? 0 : 1);
  }

  bool get _hasMore => ref.read(discoverContractorsProvider.notifier).hasMore;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 520) {
        unawaited(_loadMore());
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
    ref.invalidate(recentProjectsProvider);
    await ref.read(discoverContractorsProvider.future);
  }

  Future<void> _toggleSaved({
    required String contractorId,
    required bool currentlySaved,
  }) async {
    if (_optimisticSaved.containsKey(contractorId)) return;
    setState(() => _optimisticSaved[contractorId] = !currentlySaved);
    try {
      await ref.read(savedControllerProvider.notifier).toggle(contractorId);
      if (mounted) setState(() => _optimisticSaved.remove(contractorId));
    } catch (error) {
      if (!mounted) return;
      setState(() => _optimisticSaved.remove(contractorId));
      BatshSnack.error(context, ErrorMapper.map(error));
    }
  }

  Future<void> _openFilters(BuildContext context) async {
    final current = ref.read(discoveryFiltersControllerProvider);
    final initial = <String>{
      if (current.specialty != null) 'specialty:${current.specialty}',
      if (current.city != null) 'city:${current.city}',
    };
    final specialties = OnboardingCatalog.specialtiesCatalog.keys
        .map(
          (key) => FilterOption(
            value: 'specialty:$key',
            label: localizedSpecialtyLabel(context, key),
            icon: Icons.category_outlined,
          ),
        )
        .toList();
    final cities = OnboardingCatalog.citiesAndDistricts
        .map(
          (city) => FilterOption(
            value: 'city:${city.city}',
            label: city.city,
            icon: Icons.location_on_outlined,
          ),
        )
        .toList();

    final result = await BatshFilterSheet.show(
      context,
      initialSelected: initial,
      sections: [
        BatshFilterSheetSection(
          title: context.l10n.filterCategory,
          icon: Icons.category_outlined,
          singleSelect: true,
          options: specialties,
        ),
        BatshFilterSheetSection(
          title: context.l10n.filterCity,
          icon: Icons.location_on_outlined,
          singleSelect: true,
          options: cities,
        ),
      ],
    );
    if (!mounted || result == null) return;

    final controller = ref.read(discoveryFiltersControllerProvider.notifier);
    final specialty = result.firstWhere(
      (value) => value.startsWith('specialty:'),
      orElse: () => '',
    );
    final city = result.firstWhere(
      (value) => value.startsWith('city:'),
      orElse: () => '',
    );
    controller.setSpecialty(
      specialty.isEmpty ? null : specialty.replaceFirst('specialty:', ''),
    );
    controller.setCity(city.isEmpty ? null : city.replaceFirst('city:', ''));
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    final filters = ref.read(discoveryFiltersControllerProvider);
    final profileCity = ref.read(homeownerProfileProvider).value?.city;
    final selected = await BatshSheet.show<String>(
      context,
      contentPadding: EdgeInsets.zero,
      builder: (_) => _DirectoryLocationSheet(
        currentCity: filters.city ?? profileCity,
        profileCity: profileCity,
      ),
    );
    if (!mounted || selected == null) return;
    ref
        .read(discoveryFiltersControllerProvider.notifier)
        .setCity(selected.isEmpty ? null : selected);
  }

  List<ContractorListing> _sorted(List<ContractorListing> source) {
    final result = [...source];
    result.sort((a, b) {
      if (_sort == _DirectorySort.newest) {
        final aDate = a.memberSince ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.memberSince ?? DateTime.fromMillisecondsSinceEpoch(0);
        final byDate = bDate.compareTo(aDate);
        return byDate == 0 ? a.id.compareTo(b.id) : byDate;
      }
      final byRating = (b.rating ?? -1).compareTo(a.rating ?? -1);
      if (byRating != 0) return byRating;
      final byReviews = b.reviewCount.compareTo(a.reviewCount);
      if (byReviews != 0) return byReviews;
      final byProjects = b.projectsCompleted.compareTo(a.projectsCompleted);
      return byProjects == 0 ? a.id.compareTo(b.id) : -byProjects;
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(discoveryFiltersControllerProvider);
    final contractors = ref.watch(discoverContractorsProvider);
    final sponsored = ref.watch(
      sponsoredProfessionalsProvider(filters.specialty, filters.city),
    );
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? <String>{};
    final profileCity = ref.watch(homeownerProfileProvider).value?.city;
    final browseCity = filters.city ?? profileCity;

    return BatshScaffold(
      showAppBar: false,
      padding: EdgeInsets.zero,
      body: contractors.when(
        loading: () => const _DirectorySkeleton(),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(BatshSpacing.gutter),
          child: ShattabExperienceState(
            icon: Icons.cloud_off_outlined,
            title: context.l10n.unknownErrorRetry,
            message: ErrorMapper.map(error),
            actionLabel: context.l10n.tryAgain,
            onAction: () => ref.invalidate(discoverContractorsProvider),
            secondaryActionLabel: context.l10n.helpSupport,
            onSecondaryAction: () => openShattabSupport(context),
            pattern: ShattabPatternKind.contour,
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
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
                message: context.l10n.noContractorsMessage,
                actionLabel: filtered
                    ? context.l10n.clearFilters
                    : context.l10n.tryAgain,
                onAction: () {
                  if (filtered) {
                    _searchController.clear();
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

          final visible = _sorted(items);
          final hasSearch = filters.searchQuery?.trim().isNotEmpty == true;
          final showSponsored =
              !hasSearch && sponsored.value?.isNotEmpty == true;

          void openProfile(String id) =>
              context.push(Routes.homeownerContractorProfilePath(id));

          Widget reveal(Widget child, int index) {
            if (MediaQuery.disableAnimationsOf(context)) return child;
            return child
                .animate()
                .fadeIn(
                  delay: BatshMotion.staggerClamped(index),
                  duration: BatshMotion.normal,
                  curve: BatshMotion.easeOut,
                )
                .slideY(begin: 0.025, end: 0, curve: BatshMotion.easeOut);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: context.colorScheme.primary,
            child: CustomScrollView(
              key: const PageStorageKey<String>('homeowner-professionals'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _DirectoryHeader(
                    location: browseCity ?? context.l10n.cityNewCairo,
                    unreadCount: ref.watch(unreadNotificationsProvider),
                    onLocationTap: () => _openLocationPicker(context),
                    onNotificationTap: () => context.push(Routes.notifications),
                    onHomeTap: () => context.go(Routes.homeownerHome),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _DirectoryIntro(
                    search: BatshSearchBar(
                      controller: _searchController,
                      hintText: context.l10n.discoverSearchHint,
                      onChanged: (value) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 300),
                          () => ref
                              .read(discoveryFiltersControllerProvider.notifier)
                              .setSearch(value),
                        );
                      },
                      onClear: () {
                        _searchController.clear();
                        ref
                            .read(discoveryFiltersControllerProvider.notifier)
                            .setSearch(null);
                      },
                    ),
                    sort: _DirectorySortButton(
                      sort: _sort,
                      onChanged: (sort) => setState(() => _sort = sort),
                    ),
                    filter: BatshFilterButton(
                      activeCount: _activeFilterCount,
                      onTap: () => _openFilters(context),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _QuickFilterRow(
                    browseCity: browseCity,
                    activeCity: filters.city,
                    activeSpecialty: filters.specialty,
                    onClear: () {
                      _searchController.clear();
                      ref
                          .read(discoveryFiltersControllerProvider.notifier)
                          .clear();
                    },
                    onCity: () => ref
                        .read(discoveryFiltersControllerProvider.notifier)
                        .setCity(browseCity),
                    onSelectSpecialty: (id) => ref
                        .read(discoveryFiltersControllerProvider.notifier)
                        .setSpecialty(filters.specialty == id ? null : id),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.sectionH,
                      BatshSpacing.sm,
                      BatshSpacing.sectionH,
                      BatshSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.professionalsAvailable(visible.length),
                            style: BatshTypography.labelLg.copyWith(
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _openLocationPicker(context),
                          icon: const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                          ),
                          label: Text(context.l10n.changeBrowseLocationShort),
                          style: TextButton.styleFrom(
                            foregroundColor: context.colorScheme.primary,
                            minimumSize: const Size(44, 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: BatshSpacing.xs,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // A dark visual chapter between the controls and the
                // catalogue: real finished rooms from the community, so the
                // fold shows evidence rather than chrome. Suppressed while a
                // search is active — results outrank inspiration.
                if (!hasSearch)
                  const SliverToBoxAdapter(child: RecentWorkRail()),
                if (showSponsored)
                  SliverToBoxAdapter(
                    child: _SponsoredDirectorySection(
                      listings: sponsored.value!,
                      onTap: (listing) => openProfile(listing.id),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.sectionH,
                      BatshSpacing.lg,
                      BatshSpacing.sectionH,
                      BatshSpacing.sm,
                    ),
                    child: _DirectorySectionTitle(
                      title: context.l10n.trustedProfessionals,
                      subtitle: context.l10n.trustedProfessionalsHint,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    BatshSpacing.sectionH,
                    0,
                    BatshSpacing.sectionH,
                    BatshSpacing.xxl,
                  ),
                  sliver: SliverList.builder(
                    itemCount: visible.length + 1,
                    itemBuilder: (context, index) {
                      if (index == visible.length) {
                        return _DirectoryFooter(
                          loading: _loadingMore,
                          error: _paginationError,
                          hasMore: _hasMore,
                          onRetry: _loadMore,
                        );
                      }
                      final listing = visible[index];
                      final saved =
                          _optimisticSaved[listing.id] ??
                          savedIds.contains(listing.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: BatshSpacing.md),
                        child: reveal(
                          _DirectoryProfessionalCard(
                            listing: listing,
                            isSaved: saved,
                            onTap: () => openProfile(listing.id),
                            onToggleSave: () => runSignedIn(
                              context,
                              ref,
                              reason: context.l10n.signInToSave,
                              action: () => _toggleSaved(
                                contractorId: listing.id,
                                currentlySaved: savedIds.contains(listing.id),
                              ),
                            ),
                          ),
                          index,
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 104 + MediaQuery.of(context).padding.bottom,
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

class _DirectoryHeader extends StatelessWidget {
  const _DirectoryHeader({
    required this.location,
    required this.unreadCount,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onHomeTap,
  });

  final String location;
  final int unreadCount;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onHomeTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Stack(
      children: [
        SizedBox(
          height: 92,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 70,
                child: Opacity(
                  opacity: 0.11,
                  child: ShattabPattern(
                    kind: ShattabPatternKind.arches,
                    color: scheme.primary,
                    strokeWidth: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.sectionH,
            ),
            child: SizedBox(
              height: 92,
              child: Row(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(top: BatshSpacing.xs),
                      child: Row(
                        textDirection: TextDirection.ltr,
                        children: [
                          _DirectoryIconButton(
                            icon: Icons.home_outlined,
                            label: context.l10n.tabHome,
                            onTap: onHomeTap,
                          ),
                          const SizedBox(width: BatshSpacing.xs),
                          Flexible(
                            child: _DirectoryLocationButton(
                              location: location,
                              onTap: onLocationTap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(top: BatshSpacing.sm),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          context.l10n.discoverPageTitle,
                          style: BatshTypography.headlineSm.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: BatshSpacing.xs),
                        child: _DirectoryNotificationButton(
                          count: unreadCount,
                          onTap: onNotificationTap,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DirectoryIntro extends StatelessWidget {
  const _DirectoryIntro({
    required this.search,
    required this.sort,
    required this.filter,
  });

  final Widget search;
  final Widget sort;
  final Widget filter;

  @override
  Widget build(BuildContext context) {
    // Controls only, no preamble: the header above already says where you
    // are and the sections below carry the story. The old centered
    // title-plus-hint stack pushed the first professional ~350dp down the
    // screen, which read as an empty page wearing a search bar.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sectionH,
        BatshSpacing.xs,
        BatshSpacing.sectionH,
        0,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: BatshSpacing.sm),
            Row(
              children: [
                Expanded(child: sort),
                const SizedBox(width: BatshSpacing.sm),
                filter,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectorySortButton extends StatelessWidget {
  const _DirectorySortButton({required this.sort, required this.onChanged});

  final _DirectorySort sort;
  final ValueChanged<_DirectorySort> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = sort == _DirectorySort.recommended
        ? context.l10n.topRated
        : context.l10n.filterNewestFirst;
    return PopupMenuButton<_DirectorySort>(
      tooltip: context.l10n.filterSort,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _DirectorySort.recommended,
          child: Text(context.l10n.topRated),
        ),
        PopupMenuItem(
          value: _DirectorySort.newest,
          child: Text(context.l10n.filterNewestFirst),
        ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brMd,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: BatshIconSize.md,
              color: context.colorScheme.onSurfaceVariant,
            ),
            Flexible(
              child: Text(
                '${context.l10n.filterSort}: $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterRow extends StatelessWidget {
  const _QuickFilterRow({
    required this.browseCity,
    required this.activeCity,
    required this.activeSpecialty,
    required this.onClear,
    required this.onCity,
    required this.onSelectSpecialty,
  });

  final String? browseCity;
  final String? activeCity;
  final String? activeSpecialty;
  final VoidCallback onClear;
  final VoidCallback onCity;
  final ValueChanged<String> onSelectSpecialty;

  /// The trades homeowners actually search for, mirroring the home tab's
  /// category tiles so the two surfaces speak the same vocabulary. Tapping
  /// the active chip clears it — a filter you cannot undo from where you
  /// set it is a trap.
  static const _specialtyIds = [
    'full_reno',
    'design',
    'paint',
    'electrical',
    'plumbing',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sectionH),
        children: [
          _DirectoryChip(
            label: context.l10n.filterAll,
            selected: activeCity == null && activeSpecialty == null,
            onTap: onClear,
          ),
          const SizedBox(width: BatshSpacing.xs),
          _DirectoryChip(
            label: context.l10n.nearYou,
            icon: Icons.location_on_outlined,
            selected: activeCity != null,
            onTap: browseCity == null ? null : onCity,
          ),
          for (final id in _specialtyIds) ...[
            const SizedBox(width: BatshSpacing.xs),
            _DirectoryChip(
              label: localizedSpecialtyLabel(context, id),
              selected: activeSpecialty == id,
              onTap: () => onSelectSpecialty(id),
            ),
          ],
        ],
      ),
    );
  }
}

class _DirectoryChip extends StatelessWidget {
  const _DirectoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brFull,
          child: Container(
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brFull,
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.85),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: BatshTypography.labelMd.copyWith(
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: BatshSpacing.xs),
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectorySectionTitle extends StatelessWidget {
  const _DirectorySectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, color: scheme.secondary, size: 24),
          const SizedBox(width: BatshSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BatshTypography.headlineSm.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: BatshTypography.bodySm.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryProfessionalCard extends StatelessWidget {
  const _DirectoryProfessionalCard({
    required this.listing,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSave,
  });

  final ContractorListing listing;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  String get _name => listing.businessName.trim().isNotEmpty
      ? listing.businessName.trim()
      : listing.fullName.trim();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final specialty = listing.specialties.isEmpty
        ? listing.providerKind.label(context)
        : localizedSpecialtyLabel(context, listing.specialties.first);
    final area = listing.serviceAreas.isEmpty
        ? context.l10n.notSpecified
        : listing.serviceAreas.first;
    final image =
        listing.coverPhotoUrl ??
        mockupPortfolioImages[listing.id.hashCode.abs() %
            mockupPortfolioImages.length];

    return Semantics(
      container: true,
      label: '$_name. $specialty. $area. ${context.l10n.viewContractorProfile}',
      child: BatshPressable(
        onTap: onTap,
        pressedScale: 0.985,
        semanticLabel: _name,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brLg,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.74),
            ),
            boxShadow: BatshShadows.subtle,
          ),
          child: SizedBox(
            height: 138,
            child: ClipRRect(
              borderRadius: BatshRadius.brLg,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    Expanded(
                      flex: 42,
                      child: MockupImage(url: image, memCacheWidth: 520),
                    ),
                    Expanded(
                      flex: 58,
                      child: Stack(
                        children: [
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                BatshSpacing.sm,
                                BatshSpacing.xs,
                                BatshSpacing.sm,
                                BatshSpacing.xs,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 24,
                                    ),
                                    child: Row(
                                      children: [
                                        AvatarWithInitials(
                                          imageUrl: listing.logoUrl,
                                          name: _name,
                                          radius: 18,
                                        ),
                                        const SizedBox(width: BatshSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            _name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: BatshTypography.labelMd
                                                .copyWith(
                                                  color: scheme.onSurface,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$specialty • $area',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: BatshTypography.labelSm
                                              .copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                      if (listing.verified)
                                        Icon(
                                          Icons.verified_rounded,
                                          size: 16,
                                          color: scheme.secondary,
                                        ),
                                      const SizedBox(width: BatshSpacing.xxs),
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      if (listing.hasReviews) ...[
                                        Icon(
                                          Icons.star_rounded,
                                          size: 17,
                                          color: BatshColors.starGold,
                                        ),
                                        const SizedBox(width: BatshSpacing.xxs),
                                        Text(
                                          listing.reviewAvg.toStringAsFixed(1),
                                          style: BatshTypography.labelMd
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(width: BatshSpacing.xxs),
                                        Text(
                                          '(${listing.reviewCount})',
                                          style: BatshTypography.labelSm
                                              .copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ] else
                                        Text(
                                          context.l10n.newBadge,
                                          style: BatshTypography.labelSm
                                              .copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                      const Spacer(),
                                      if (listing.projectsCompleted > 0)
                                        Text(
                                          '${listing.projectsCompleted} ${context.l10n.completedProjectsShort}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: BatshTypography.labelSm
                                              .copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: BatshSpacing.xs),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: SizedBox(
                                      height: 32,
                                      child: FilledButton(
                                        onPressed: onTap,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: scheme.primary,
                                          foregroundColor: scheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: BatshSpacing.md,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BatshRadius.brMd,
                                          ),
                                        ),
                                        child: Text(
                                          context.l10n.viewContractorProfile,
                                          style: BatshTypography.labelMd
                                              .copyWith(
                                                color: scheme.onPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            top: 2,
                            end: 2,
                            child: IconButton(
                              onPressed: onToggleSave,
                              tooltip: isSaved
                                  ? context.l10n.unsaveTooltip
                                  : context.l10n.saveTooltip,
                              constraints: const BoxConstraints(
                                minWidth: BatshSpacing.minHitArea,
                                minHeight: BatshSpacing.minHitArea,
                              ),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 20,
                                color: isSaved
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SponsoredDirectorySection extends StatelessWidget {
  const _SponsoredDirectorySection({
    required this.listings,
    required this.onTap,
  });

  final List<ContractorListing> listings;
  final ValueChanged<ContractorListing> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: BatshSpacing.sectionH),
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.xs,
        BatshSpacing.xs,
        BatshSpacing.xs,
        BatshSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.055,
                child: ShattabPattern(
                  kind: ShattabPatternKind.terrazzo,
                  color: context.colorScheme.primary,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.sm,
                  vertical: BatshSpacing.xxs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 18,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: BatshSpacing.xxs),
                    Text(
                      context.l10n.paidPlacementLabel,
                      style: BatshTypography.labelMd.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      context.l10n.sponsoredProfessionals,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 142,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BatshSpacing.xxs,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: listings.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: BatshSpacing.xs),
                  itemBuilder: (_, index) => _SponsoredDirectoryCard(
                    listing: listings[index],
                    onTap: () => onTap(listings[index]),
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

class _SponsoredDirectoryCard extends StatelessWidget {
  const _SponsoredDirectoryCard({required this.listing, required this.onTap});

  final ContractorListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.trim().isNotEmpty
        ? listing.businessName.trim()
        : listing.fullName.trim();
    final image =
        listing.coverPhotoUrl ??
        mockupPortfolioImages[listing.id.hashCode.abs() %
            mockupPortfolioImages.length];
    final scheme = context.colorScheme;
    return SizedBox(
      width: 164,
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: '${context.l10n.paidPlacementLabel}: $name',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BatshRadius.brMd,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BatshRadius.brMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 62,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MockupImage(url: image, memCacheWidth: 360),
                      PositionedDirectional(
                        top: BatshSpacing.xxs,
                        start: BatshSpacing.xxs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BatshSpacing.xxs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BatshRadius.brXs,
                          ),
                          child: Text(
                            context.l10n.paidPlacementLabel,
                            style: BatshTypography.labelSm.copyWith(
                              color: scheme.onPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.xs,
                      vertical: BatshSpacing.xxs,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        children: [
                          AvatarWithInitials(
                            imageUrl: listing.logoUrl,
                            name: name,
                            radius: 15,
                          ),
                          const SizedBox(width: BatshSpacing.xxs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: BatshTypography.labelSm.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (listing.hasReviews)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 12,
                                        color: BatshColors.starGold,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        listing.reviewAvg.toStringAsFixed(1),
                                        style: BatshTypography.labelSm.copyWith(
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectoryNotificationButton extends StatelessWidget {
  const _DirectoryNotificationButton({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DirectoryIconButton(
      icon: Icons.notifications_none_rounded,
      label: context.l10n.notificationsTitle,
      onTap: onTap,
      badge: count,
    );
  }
}

class _DirectoryIconButton extends StatelessWidget {
  const _DirectoryIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: context.colorScheme.surfaceContainerLowest,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: BatshSpacing.minHitArea,
                height: BatshSpacing.minHitArea,
                child: Icon(
                  icon,
                  size: BatshIconSize.action,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (badge > 0)
            PositionedDirectional(
              top: -4,
              end: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  textDirection: TextDirection.ltr,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DirectoryLocationButton extends StatelessWidget {
  const _DirectoryLocationButton({required this.location, required this.onTap});

  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 140.0;
        final compact =
            availableWidth < 112 || MediaQuery.sizeOf(context).width <= 340;
        final buttonWidth = compact
            ? availableWidth.clamp(70.0, 84.0)
            : availableWidth.clamp(96.0, 140.0);

        return Semantics(
          button: true,
          label: '${context.l10n.filterCity}: $location',
          child: Tooltip(
            message: location,
            child: Material(
              color: context.colorScheme.surfaceContainerLowest,
              borderRadius: BatshRadius.brFull,
              child: InkWell(
                onTap: onTap,
                borderRadius: BatshRadius.brFull,
                child: Container(
                  width: buttonWidth,
                  constraints: const BoxConstraints(minHeight: 42),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? BatshSpacing.xs : BatshSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BatshRadius.brFull,
                    border: Border.all(
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  child: compact
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: context.colorScheme.primary,
                            ),
                            const SizedBox(width: BatshSpacing.xxs),
                            Flexible(
                              child: Text(
                                context.l10n.filterCity,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BatshTypography.labelSm.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 17,
                            ),
                            const SizedBox(width: BatshSpacing.xxs),
                            Flexible(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                style: BatshTypography.labelSm.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: BatshSpacing.xxs),
                            Icon(
                              Icons.location_on_outlined,
                              size: 17,
                              color: context.colorScheme.primary,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DirectoryLocationSheet extends StatelessWidget {
  const _DirectoryLocationSheet({this.currentCity, this.profileCity});

  final String? currentCity;
  final String? profileCity;

  @override
  Widget build(BuildContext context) {
    final cities = OnboardingCatalog.citiesAndDistricts;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                Icon(
                  Icons.location_on_outlined,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.changeLocation,
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                BatshSpacing.lg,
                BatshSpacing.sm,
                BatshSpacing.lg,
                BatshSpacing.lg,
              ),
              itemCount: cities.length + (profileCity == null ? 0 : 1),
              separatorBuilder: (_, _) =>
                  const SizedBox(height: BatshSpacing.xs),
              itemBuilder: (context, index) {
                if (profileCity != null && index == cities.length) {
                  return _DirectoryLocationOption(
                    label: context.l10n.useProfileLocation,
                    selected: currentCity == profileCity,
                    icon: Icons.home_outlined,
                    onTap: () => Navigator.of(context).pop(''),
                  );
                }
                final city = cities[index].city;
                return _DirectoryLocationOption(
                  label: city,
                  selected: currentCity == city,
                  onTap: () => Navigator.of(context).pop(city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryLocationOption extends StatelessWidget {
  const _DirectoryLocationOption({
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
    final scheme = context.colorScheme;
    return Material(
      color: selected ? scheme.primaryFixed : scheme.surfaceContainerLowest,
      borderRadius: BatshRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brMd,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BatshRadius.brMd,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(child: Text(label, style: BatshTypography.labelLg)),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectoryFooter extends StatelessWidget {
  const _DirectoryFooter({
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

class _DirectorySkeleton extends StatelessWidget {
  const _DirectorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sectionH,
        BatshSpacing.lg,
        BatshSpacing.sectionH,
        BatshSpacing.xxl,
      ),
      children: [
        const Align(
          alignment: AlignmentDirectional.center,
          child: BatshShimmerBox(width: 130, height: 26),
        ),
        const SizedBox(height: BatshSpacing.xl),
        const BatshShimmerBox(height: 52, borderRadius: BatshRadius.brFull),
        const SizedBox(height: BatshSpacing.sm),
        Row(
          children: const [
            Expanded(child: BatshShimmerBox(height: 42)),
            SizedBox(width: BatshSpacing.sm),
            BatshShimmerBox(width: 94, height: 42),
          ],
        ),
        const SizedBox(height: BatshSpacing.lg),
        const BatshShimmerBox(width: 150, height: 20),
        const SizedBox(height: BatshSpacing.md),
        for (var i = 0; i < 3; i++) ...[
          const BatshShimmerBox(height: 154, borderRadius: BatshRadius.brLg),
          if (i < 2) const SizedBox(height: BatshSpacing.md),
        ],
      ],
    );
  }
}
