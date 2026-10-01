import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/l10n/catalog_labels.dart';
import '../../../core/router/routes.dart';
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
import '../../../core/widgets/batsh_pressable.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_search_bar.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../../core/widgets/shattab_experience_state.dart';
import '../../../core/widgets/shattab_pattern.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import '../data/discovery_repository.dart';
import '../domain/contractor_listing.dart';
import 'providers/discovery_providers.dart';

/// The homeowner catalogue. All cards are backed by the discovery query; a
/// missing image is represented honestly instead of being replaced by a stock
/// room photo.
class ProfessionalDirectoryScreen extends ConsumerStatefulWidget {
  const ProfessionalDirectoryScreen({super.key});

  @override
  ConsumerState<ProfessionalDirectoryScreen> createState() =>
      _ProfessionalDirectoryScreenState();
}

class _ProfessionalDirectoryScreenState
    extends ConsumerState<ProfessionalDirectoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  final Map<String, bool> _optimisticSaved = {};
  Object? _loadMoreError;
  bool _loadingMore = false;

  int get _activeFilterCount {
    final filters = ref.read(discoveryFiltersControllerProvider);
    return (filters.specialty == null ? 0 : 1) +
        (filters.city == null ? 0 : 1) +
        (filters.minimumRating == null ? 0 : 1);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.position.extentAfter < 480) {
        unawaited(_loadMore());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    final notifier = ref.read(discoverContractorsProvider.notifier);
    if (_loadingMore || !notifier.hasMore) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      await notifier.loadMore();
    } catch (error) {
      if (mounted) setState(() => _loadMoreError = error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(discoverContractorsProvider);
    await ref.read(discoverContractorsProvider.future);
  }

  Future<void> _toggleSave(
    String contractorId, {
    required bool currentlySaved,
  }) async {
    if (_optimisticSaved.containsKey(contractorId)) return;
    setState(() => _optimisticSaved[contractorId] = !currentlySaved);
    try {
      await ref.read(savedControllerProvider.notifier).toggle(contractorId);
      if (mounted) {
        setState(() => _optimisticSaved.remove(contractorId));
        BatshSnack.success(
          context,
          currentlySaved ? 'تمت إزالة المحترف من المحفوظات' : 'تم حفظ المحترف',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _optimisticSaved.remove(contractorId));
      BatshSnack.error(context, ErrorMapper.map(error));
    }
  }

  Future<void> _showFilters() async {
    final current = ref.read(discoveryFiltersControllerProvider);
    final result = await showModalBottomSheet<_FilterDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterDraftSheet(initial: current),
    );
    if (!mounted || result == null) return;
    final controller = ref.read(discoveryFiltersControllerProvider.notifier);
    controller.setSpecialty(result.specialty);
    controller.setCity(result.city);
    controller.setMinimumRating(result.minimumRating);
  }

  Future<void> _showSort() async {
    final current = ref.read(discoveryFiltersControllerProvider).sort;
    final result = await showModalBottomSheet<DiscoverySort>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(initial: current),
    );
    if (!mounted || result == null) return;
    ref.read(discoveryFiltersControllerProvider.notifier).setSort(result);
  }

  Future<void> _showLocation() async {
    final current = ref.read(discoveryFiltersControllerProvider).city;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSheet(initialCity: current),
    );
    if (!mounted || result == null) return;
    ref
        .read(discoveryFiltersControllerProvider.notifier)
        .setCity(result.isEmpty ? null : result);
  }

  void _clearAll() {
    _searchController.clear();
    ref.read(discoveryFiltersControllerProvider.notifier).clear();
  }

  void _setSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      ref.read(discoveryFiltersControllerProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(discoveryFiltersControllerProvider);
    final contractors = ref.watch(discoverContractorsProvider);
    final topRated = ref.watch(topRatedProfessionalsProvider);
    final sponsored = ref.watch(
      sponsoredProfessionalsProvider(filters.specialty, filters.city),
    );
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? <String>{};
    final location = filters.city ?? context.l10n.cityNewCairo;
    final hasQuery = filters.searchQuery?.isNotEmpty == true;

    return BatshScaffold(
      showAppBar: false,
      padding: EdgeInsets.zero,
      body: contractors.when(
        loading: () => const _DirectoryLoading(),
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
        data: (items) => _buildContent(
          context,
          items: items,
          filters: filters,
          location: location,
          hasQuery: hasQuery,
          savedIds: savedIds,
          sponsored: sponsored,
          topRated: topRated,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required List<ContractorListing> items,
    required DiscoveryFilters filters,
    required String location,
    required bool hasQuery,
    required Set<String> savedIds,
    required AsyncValue<List<ContractorListing>> sponsored,
    required AsyncValue<List<ContractorListing>> topRated,
  }) {
    if (items.isEmpty) {
      final filtered = !filters.isEmpty;
      return Column(
        children: [
          _DirectoryHeader(
            unreadCount: ref.watch(unreadNotificationsProvider),
            onNotifications: () => context.push(Routes.notifications),
            onSaved: () => context.push(Routes.homeownerSaved),
            queryMode: hasQuery,
            onExitQuery: hasQuery
                ? () {
                    _searchController.clear();
                    ref
                        .read(discoveryFiltersControllerProvider.notifier)
                        .setSearch(null);
                  }
                : null,
          ),
          Expanded(
            child: Padding(
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
                onAction: filtered
                    ? _clearAll
                    : () => ref.invalidate(discoverContractorsProvider),
                pattern: filtered
                    ? ShattabPatternKind.lattice
                    : ShattabPatternKind.arches,
              ),
            ),
          ),
        ],
      );
    }

    final sorted = [...items];
    if (filters.sort == DiscoverySort.projects) {
      sorted.sort((a, b) => b.projectsCompleted.compareTo(a.projectsCompleted));
    } else if (filters.sort == DiscoverySort.rating) {
      sorted.sort((a, b) => (b.rating ?? -1).compareTo(a.rating ?? -1));
    }

    final hasSponsored = !hasQuery && sponsored.value?.isNotEmpty == true;

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
              unreadCount: ref.watch(unreadNotificationsProvider),
              queryMode: hasQuery,
              onNotifications: () => context.push(Routes.notifications),
              onSaved: () => context.push(Routes.homeownerSaved),
              onExitQuery: hasQuery
                  ? () {
                      _searchController.clear();
                      ref
                          .read(discoveryFiltersControllerProvider.notifier)
                          .setSearch(null);
                    }
                  : null,
            ),
          ),
          SliverToBoxAdapter(
            child: _DirectoryControls(
              searchController: _searchController,
              onSearchChanged: _setSearch,
              onClearSearch: () {
                _searchController.clear();
                ref
                    .read(discoveryFiltersControllerProvider.notifier)
                    .setSearch(null);
              },
              activeFilterCount: _activeFilterCount,
              onFilter: _showFilters,
              sort: filters.sort,
              onSort: _showSort,
              showSearch: true,
              showSortAndFilter: false,
            ),
          ),
          if (!hasQuery) ...[
            SliverToBoxAdapter(
              child: _LocationSelector(
                location: location,
                onTap: _showLocation,
              ),
            ),
            SliverToBoxAdapter(
              child: _CategoryRail(
                selected: filters.specialty,
                onSelected: (key) => ref
                    .read(discoveryFiltersControllerProvider.notifier)
                    .setSpecialty(key),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: _ActiveCriteria(
              filters: filters,
              onClear: _clearAll,
              onRemoveSpecialty: () => ref
                  .read(discoveryFiltersControllerProvider.notifier)
                  .setSpecialty(null),
              onRemoveCity: () => ref
                  .read(discoveryFiltersControllerProvider.notifier)
                  .setCity(null),
              onRemoveRating: () => ref
                  .read(discoveryFiltersControllerProvider.notifier)
                  .setMinimumRating(null),
            ),
          ),
          if (hasSponsored) ...[
            SliverToBoxAdapter(
              child: _SectionHeading(title: 'محترفون في منطقتك'),
            ),
            SliverToBoxAdapter(
              child: _SponsoredShelf(
                listings: sponsored.value!,
                savedIds: savedIds,
                onInfo: () => _showSponsoredInfo(context),
                onOpen: (listing) => context.push(
                  Routes.homeownerContractorProfilePath(listing.id),
                ),
                onSave: (listing, currentlySaved) => runSignedIn(
                  context,
                  ref,
                  reason: context.l10n.signInToSave,
                  action: () =>
                      _toggleSave(listing.id, currentlySaved: currentlySaved),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: _SectionHeading(
              title: hasQuery ? 'نتائج البحث' : 'كل المحترفين',
              subtitle: hasQuery
                  ? context.l10n.professionalsAvailable(sorted.length)
                  : null,
            ),
          ),
          if (!hasQuery)
            SliverToBoxAdapter(
              child: _DirectoryControls(
                searchController: _searchController,
                onSearchChanged: _setSearch,
                onClearSearch: () {
                  _searchController.clear();
                  ref
                      .read(discoveryFiltersControllerProvider.notifier)
                      .setSearch(null);
                },
                activeFilterCount: _activeFilterCount,
                onFilter: _showFilters,
                sort: filters.sort,
                onSort: _showSort,
                showSearch: false,
                showSortAndFilter: true,
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.sectionH,
            ),
            sliver: SliverList.builder(
              itemCount: sorted.length,
              itemBuilder: (_, index) {
                final listing = sorted[index];
                final saved =
                    _optimisticSaved[listing.id] ??
                    savedIds.contains(listing.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
                  child: _ProfessionalCard(
                    listing: listing,
                    isSaved: saved,
                    onOpen: () => context.push(
                      Routes.homeownerContractorProfilePath(listing.id),
                    ),
                    onSave: () => runSignedIn(
                      context,
                      ref,
                      reason: context.l10n.signInToSave,
                      action: () => _toggleSave(
                        listing.id,
                        currentlySaved: savedIds.contains(listing.id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _DirectoryFooter(
              loading: _loadingMore,
              error: _loadMoreError,
              hasMore: ref.read(discoverContractorsProvider.notifier).hasMore,
              onLoadMore: _loadMore,
            ),
          ),
          if (!hasQuery)
            SliverToBoxAdapter(
              child: _TopRatedShelf(
                state: topRated,
                savedIds: savedIds,
                onOpen: (listing) => context.push(
                  Routes.homeownerContractorProfilePath(listing.id),
                ),
                onSave: (listing, currentlySaved) => runSignedIn(
                  context,
                  ref,
                  reason: context.l10n.signInToSave,
                  action: () =>
                      _toggleSave(listing.id, currentlySaved: currentlySaved),
                ),
                onViewAll: () =>
                    context.push(Routes.homeownerTopRatedProfessionals),
              ),
            ),
          SliverToBoxAdapter(
            child: _CreateProjectBanner(
              onTap: () => runSignedIn(
                context,
                ref,
                reason: 'سجّل دخولك لإضافة مشروعك',
                action: () => context.push(Routes.homeownerNewPost),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 92 + MediaQuery.of(context).padding.bottom),
          ),
        ],
      ),
    );
  }

  Future<void> _showSponsoredInfo(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InfoSheet(
        icon: Icons.campaign_outlined,
        title: 'إعلان ممول',
        body:
            'هذا الظهور الإضافي مدفوع من المحترف ليظهر في بداية القسم. الترويج يزيد الظهور فقط ولا يغيّر تقييمات العملاء أو ترتيب الجودة المكتسبة.',
        action: 'فهمت',
      ),
    );
  }
}

class _DirectoryHeader extends StatelessWidget {
  const _DirectoryHeader({
    required this.unreadCount,
    required this.onNotifications,
    required this.onSaved,
    this.queryMode = false,
    this.onExitQuery,
  });

  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onSaved;
  final bool queryMode;
  final VoidCallback? onExitQuery;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Container(
          height: 162 + topInset,
          color: scheme.surfaceContainerLowest,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: .9,
                  child: Image.asset(
                    'assets/images/professionals_header_architecture_v2.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topLeft,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 38,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: .34,
                    child: ShattabPattern(
                      kind: ShattabPatternKind.lattice,
                      color: scheme.primary,
                      strokeWidth: 1.15,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.surface.withValues(alpha: .02),
                        scheme.surface.withValues(alpha: .12),
                        scheme.surface.withValues(alpha: .9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, .62, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.sectionH,
              BatshSpacing.xs,
              BatshSpacing.sectionH,
              BatshSpacing.md,
            ),
            child: Column(
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    if (queryMode)
                      _HeaderAction(
                        icon: Icons.arrow_forward_rounded,
                        label: 'العودة للمحترفين',
                        onTap: onExitQuery ?? () {},
                      )
                    else ...[
                      _HeaderAction(
                        icon: Icons.notifications_none_rounded,
                        label: 'الإشعارات',
                        count: unreadCount,
                        onTap: onNotifications,
                      ),
                      const Spacer(),
                      _HeaderAction(
                        icon: Icons.bookmark_border_rounded,
                        label: 'المحفوظات',
                        onTap: onSaved,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: BatshSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    queryMode ? 'نتائج البحث' : 'اختار المحترف المناسب\nلبيتك',
                    textAlign: TextAlign.right,
                    style: BatshTypography.headlineMd.copyWith(
                      color: scheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(width: 58, height: 2, color: scheme.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: context.colorScheme.surface,
            borderRadius: BatshRadius.brMd,
            child: InkWell(
              onTap: onTap,
              borderRadius: BatshRadius.brMd,
              child: const SizedBox.square(dimension: 48),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Icon(icon, color: context.colorScheme.onSurface, size: 22),
            ),
          ),
          if (count > 0)
            PositionedDirectional(
              top: -3,
              end: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  borderRadius: BatshRadius.brFull,
                ),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DirectoryControls extends StatelessWidget {
  const _DirectoryControls({
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.activeFilterCount,
    required this.onFilter,
    required this.sort,
    required this.onSort,
    this.showSearch = true,
    this.showSortAndFilter = true,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final int activeFilterCount;
  final VoidCallback onFilter;
  final DiscoverySort sort;
  final VoidCallback onSort;
  final bool showSearch;
  final bool showSortAndFilter;

  String _sortLabel() => switch (sort) {
    DiscoverySort.rating => 'الأعلى تقييماً',
    DiscoverySort.projects => 'الأكثر مشاريع مكتملة',
    DiscoverySort.name => 'الافتراضي',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.marginMobile,
        BatshSpacing.xs,
        BatshSpacing.marginMobile,
        BatshSpacing.xs,
      ),
      child: Column(
        children: [
          if (showSearch)
            BatshSearchBar(
              controller: searchController,
              hintText: 'إبحث باسم المحترف أو التخصص ...',
              height: 44,
              borderRadius: BatshRadius.brSm,
              outlined: true,
              rowTextDirection: TextDirection.ltr,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              plainInput: true,
              onChanged: onSearchChanged,
              onClear: onClearSearch,
            ),
          if (showSearch && showSortAndFilter)
            const SizedBox(height: BatshSpacing.sm),
          if (showSortAndFilter)
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 184),
                    child: _ControlButton(
                      icon: Icons.swap_vert_rounded,
                      label: 'ترتيب: ${_sortLabel()}',
                      onTap: onSort,
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.sm),
                  _ControlButton(
                    icon: Icons.tune_rounded,
                    label: activeFilterCount == 0
                        ? 'فلتر'
                        : 'فلتر ($activeFilterCount)',
                    onTap: onFilter,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector({required this.location, required this.onTap});

  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.marginMobile,
        0,
        BatshSpacing.marginMobile,
        BatshSpacing.xxs,
      ),
      child: Semantics(
        button: true,
        label: 'منطقة المشروع: $location',
        child: Material(
          color: context.colorScheme.surface,
          borderRadius: BatshRadius.brMd,
          child: InkWell(
            onTap: onTap,
            borderRadius: BatshRadius.brMd,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BatshRadius.brMd,
                border: Border.all(color: context.colorScheme.outlineVariant),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: BatshSpacing.xs),
                  Expanded(
                    child: Text(location, style: BatshTypography.labelLg),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: context.colorScheme.surface,
        borderRadius: BatshRadius.brMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brMd,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brMd,
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: BatshIconSize.md),
                const SizedBox(width: BatshSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelMd,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  static const _keys = ['all', 'full_reno', 'design', 'kitchen'];

  double _tileWidth(String key) => switch (key) {
    'all' => 72,
    'full_reno' => 96,
    'design' => 92,
    'kitchen' => 82,
    _ => 88,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sectionH),
        itemCount: _keys.length,
        separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.xs),
        itemBuilder: (_, index) {
          final key = _keys[index];
          final isAll = key == 'all';
          final active = isAll ? selected == null : selected == key;
          final label = isAll ? 'الكل' : localizedSpecialtyLabel(context, key);
          return Semantics(
            button: true,
            selected: active,
            label: label,
            child: GestureDetector(
              onTap: () => onSelected(isAll ? null : key),
              child: AnimatedContainer(
                duration: BatshMotion.normal,
                width: _tileWidth(key),
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.xs,
                  vertical: BatshSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? context.colorScheme.primaryFixed
                      : context.colorScheme.surface,
                  borderRadius: BatshRadius.brMd,
                  border: Border.all(
                    color: active
                        ? context.colorScheme.primary
                        : context.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAll ? Icons.home_outlined : specialtyIcon(key),
                      size: 26,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelMd.copyWith(
                        color: active
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveCriteria extends StatelessWidget {
  const _ActiveCriteria({
    required this.filters,
    required this.onClear,
    required this.onRemoveSpecialty,
    required this.onRemoveCity,
    required this.onRemoveRating,
  });

  final DiscoveryFilters filters;
  final VoidCallback onClear;
  final VoidCallback onRemoveSpecialty;
  final VoidCallback onRemoveCity;
  final VoidCallback onRemoveRating;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) {
      return const SizedBox(height: BatshSpacing.xs);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sectionH,
        BatshSpacing.xs,
        BatshSpacing.sectionH,
        BatshSpacing.sm,
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: BatshSpacing.xs,
        runSpacing: BatshSpacing.xs,
        children: [
          if (filters.specialty != null)
            _CriteriaChip(
              label: localizedSpecialtyLabel(context, filters.specialty!),
              onRemove: onRemoveSpecialty,
            ),
          if (filters.city != null)
            _CriteriaChip(label: filters.city!, onRemove: onRemoveCity),
          if (filters.minimumRating != null)
            _CriteriaChip(
              label: 'تقييم ${filters.minimumRating!.toStringAsFixed(1)}+',
              onRemove: onRemoveRating,
            ),
          TextButton(onPressed: onClear, child: const Text('إعادة ضبط')),
        ],
      ),
    );
  }
}

class _CriteriaChip extends StatelessWidget {
  const _CriteriaChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label, style: BatshTypography.labelMd),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      backgroundColor: context.colorScheme.primaryFixed,
      side: BorderSide(
        color: context.colorScheme.primary.withValues(alpha: .3),
      ),
      shape: const StadiumBorder(),
    );
  }
}

class _SponsoredShelf extends StatelessWidget {
  const _SponsoredShelf({
    required this.listings,
    required this.savedIds,
    required this.onInfo,
    required this.onOpen,
    required this.onSave,
  });

  final List<ContractorListing> listings;
  final Set<String> savedIds;
  final VoidCallback onInfo;
  final ValueChanged<ContractorListing> onOpen;
  final void Function(ContractorListing listing, bool currentlySaved) onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: BatshSpacing.sm),
      padding: const EdgeInsets.only(bottom: BatshSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: context.colorScheme.primary.withValues(alpha: .12),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 236,
            child: ListView.separated(
              reverse: true,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.sectionH,
              ),
              itemCount: listings.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: BatshSpacing.sm),
              itemBuilder: (_, index) {
                final listing = listings[index];
                final saved = savedIds.contains(listing.id);
                return _SponsoredCard(
                  listing: listing,
                  isSaved: saved,
                  onTap: () => onOpen(listing),
                  onSave: () => onSave(listing, saved),
                  onInfo: onInfo,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: BatshSpacing.xxs),
            child: Center(child: _CarouselDots(count: listings.length)),
          ),
        ],
      ),
    );
  }
}

class _SponsoredCard extends StatelessWidget {
  const _SponsoredCard({
    required this.listing,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
    required this.onInfo,
  });

  final ContractorListing listing;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.trim().isNotEmpty
        ? listing.businessName.trim()
        : listing.fullName.trim();
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width * .84)
          .clamp(296.0, 332.0)
          .toDouble(),
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: 'إعلان ممول: $name',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BatshRadius.brMd,
            border: Border.all(color: context.colorScheme.outlineVariant),
            boxShadow: BatshShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: BatshRadius.brMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 132,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ListingImage(url: listing.coverPhotoUrl, name: name),
                      Positioned(
                        top: BatshSpacing.xs,
                        left: BatshSpacing.xs,
                        child: _PaidBadge(onTap: onInfo),
                      ),
                      Positioned(
                        top: BatshSpacing.xs,
                        right: BatshSpacing.xs,
                        child: _SaveButton(saved: isSaved, onTap: onSave),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.sm,
                      BatshSpacing.xs,
                      BatshSpacing.sm,
                      BatshSpacing.sm,
                    ),
                    child: Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 124,
                          height: 38,
                          child: FilledButton(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              textStyle: BatshTypography.labelMd,
                            ),
                            child: const Text('عرض الملف والأعمال'),
                          ),
                        ),
                        const SizedBox(width: BatshSpacing.sm),
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: _SponsoredDetails(
                              name: name,
                              listing: listing,
                            ),
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
      ),
    );
  }
}

class _SponsoredDetails extends StatelessWidget {
  const _SponsoredDetails({required this.name, required this.listing});

  final String name;
  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final specialty = listing.specialties.isEmpty
        ? null
        : localizedSpecialtyDisplayLabel(context, listing.specialties.first);
    final area = listing.serviceAreas.isEmpty
        ? null
        : listing.serviceAreas.first;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BatshTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
        ),
        if (specialty != null)
          Text(
            specialty,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.primary,
            ),
          ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: BatshSpacing.xs,
          children: [
            if (area != null)
              Text(
                area,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            if (listing.hasReviews)
              _Metric(
                icon: Icons.star_rounded,
                value: listing.reviewAvg.toStringAsFixed(1),
                color: context.colorScheme.tertiary,
              ),
            if (listing.projectsCompleted > 0)
              Text(
                '${listing.projectsCompleted} مشروع مكتمل',
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PaidBadge extends StatelessWidget {
  const _PaidBadge({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BatshRadius.brXs,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          'إعلان ممول',
          style: BatshTypography.labelSm.copyWith(
            color: context.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    if (onTap == null) return badge;
    return Semantics(
      button: true,
      label: 'عن الإعلان الممول',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brXs,
          child: badge,
        ),
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final visibleCount = count > 4 ? 4 : count;
    if (visibleCount < 2) return const SizedBox(height: BatshSpacing.xs);
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        for (var index = 0; index < visibleCount; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: BatshMotion.normal,
              width: index == 0 ? 10 : 8,
              height: index == 0 ? 10 : 8,
              decoration: BoxDecoration(
                color: index == 0
                    ? context.colorScheme.primary
                    : context.colorScheme.primaryFixedDim,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sectionH,
        0,
        BatshSpacing.sectionH,
        BatshSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.end,
                  style: BatshTypography.titleLg.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: BatshSpacing.xxs),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.end,
                    style: BatshTypography.labelMd.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Container(width: 34, height: 2, color: context.colorScheme.primary),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({
    required this.listing,
    required this.isSaved,
    required this.onOpen,
    required this.onSave,
  });

  final ContractorListing listing;
  final bool isSaved;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.trim().isNotEmpty
        ? listing.businessName.trim()
        : listing.fullName.trim();
    final specialty = listing.specialties.isEmpty
        ? 'محترف تشطيبات'
        : localizedSpecialtyDisplayLabel(context, listing.specialties.first);
    final city = listing.serviceAreas.isEmpty
        ? null
        : listing.serviceAreas.first;
    return BatshPressable(
      onTap: onOpen,
      semanticLabel: name,
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BatshRadius.brMd,
          border: Border.all(color: context.colorScheme.outlineVariant),
          boxShadow: BatshShadows.soft,
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            SizedBox(
              width: 126,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(BatshRadius.md),
                    ),
                    child: _ListingImage(
                      url: listing.coverPhotoUrl,
                      name: name,
                    ),
                  ),
                  Positioned(
                    top: BatshSpacing.xs,
                    left: BatshSpacing.xs,
                    child: _SaveButton(saved: isSaved, onTap: onSave),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  BatshSpacing.sm,
                  BatshSpacing.sm,
                  BatshSpacing.xs,
                  BatshSpacing.sm,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (listing.isSponsored)
                        const Padding(
                          padding: EdgeInsets.only(bottom: BatshSpacing.xxs),
                          child: _PaidBadge(),
                        ),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelLg.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.xxs),
                      Text(
                        specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.bodySm.copyWith(
                          color: context.colorScheme.primary,
                        ),
                      ),
                      if (city != null) ...[
                        const SizedBox(height: BatshSpacing.xxs),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 15),
                            const SizedBox(width: BatshSpacing.xxs),
                            Expanded(
                              child: Text(
                                city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BatshTypography.labelMd.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: BatshSpacing.xxs),
                      _ProfessionalMetrics(listing: listing),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: BatshSpacing.xs),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  borderRadius: BatshRadius.brSm,
                ),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalMetrics extends StatelessWidget {
  const _ProfessionalMetrics({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: BatshSpacing.xs,
      runSpacing: BatshSpacing.xxs,
      children: [
        if (listing.hasReviews) ...[
          _Metric(
            icon: Icons.star_rounded,
            value: listing.reviewAvg.toStringAsFixed(1),
            color: context.colorScheme.tertiary,
          ),
          Text(
            '(${listing.reviewCount})',
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ] else
          Text(
            'بدون تقييمات',
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        if (listing.projectsCompleted > 0)
          Text(
            '${listing.projectsCompleted} مشروع مكتمل',
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.color});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: BatshTypography.labelLg),
        const SizedBox(width: 2),
        Icon(icon, size: 17, color: color),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onTap});

  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surface.withValues(alpha: .96),
      borderRadius: BatshRadius.brSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brSm,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: saved
                ? context.colorScheme.primary
                : context.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _ImageFallback(name: name),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _ImageFallback(name: name),
      );
    }
    return _ImageFallback(name: name);
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colorScheme.surfaceContainerHigh,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: .08,
            child: ShattabPattern(
              kind: ShattabPatternKind.lattice,
              color: context.colorScheme.primary,
              strokeWidth: .8,
            ),
          ),
          Center(child: AvatarWithInitials(name: name, radius: 24)),
        ],
      ),
    );
  }
}

class _TopRatedShelf extends StatelessWidget {
  const _TopRatedShelf({
    required this.state,
    required this.savedIds,
    required this.onOpen,
    required this.onSave,
    required this.onViewAll,
  });

  final AsyncValue<List<ContractorListing>> state;
  final Set<String> savedIds;
  final ValueChanged<ContractorListing> onOpen;
  final void Function(ContractorListing listing, bool currentlySaved) onSave;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final items = state.value ?? const <ContractorListing>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 28,
          child: Opacity(
            opacity: .22,
            child: ShattabPattern(
              kind: ShattabPatternKind.lattice,
              color: context.colorScheme.primary,
              strokeWidth: 1,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.sectionH,
            0,
            BatshSpacing.sectionH,
            BatshSpacing.xxs,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 26),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                'الأعلى تقييماً',
                style: BatshTypography.titleLg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onViewAll, child: const Text('عرض الكل')),
            ],
          ),
        ),
        SizedBox(
          height: 148,
          child: ListView.separated(
            reverse: true,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.sm),
            itemBuilder: (_, index) {
              final listing = items[index];
              final saved = savedIds.contains(listing.id);
              return _TopRatedCard(
                listing: listing,
                isSaved: saved,
                onTap: () => onOpen(listing),
                onSave: () => onSave(listing, saved),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: BatshSpacing.xxs),
          child: Center(child: _CarouselDots(count: items.length)),
        ),
      ],
    );
  }
}

class _TopRatedCard extends StatelessWidget {
  const _TopRatedCard({
    required this.listing,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
  });

  final ContractorListing listing;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.trim().isNotEmpty
        ? listing.businessName.trim()
        : listing.fullName.trim();
    final specialty = listing.specialties.isEmpty
        ? null
        : localizedSpecialtyDisplayLabel(context, listing.specialties.first);
    final area = listing.serviceAreas.isEmpty
        ? null
        : listing.serviceAreas.first;
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width * .83)
          .clamp(296.0, 330.0)
          .toDouble(),
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: 'الأعلى تقييماً: $name',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BatshRadius.brMd,
            border: Border.all(color: context.colorScheme.outlineVariant),
            boxShadow: BatshShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: BatshRadius.brMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 78,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ListingImage(url: listing.coverPhotoUrl, name: name),
                      Positioned(
                        top: BatshSpacing.xs,
                        right: BatshSpacing.xs,
                        child: _SaveButton(saved: isSaved, onTap: onSave),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.sm,
                      vertical: BatshSpacing.xxs,
                    ),
                    child: Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 124,
                          height: 38,
                          child: FilledButton(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              textStyle: BatshTypography.labelMd,
                            ),
                            child: const Text('عرض الملف والأعمال'),
                          ),
                        ),
                        const SizedBox(width: BatshSpacing.sm),
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: BatshTypography.labelLg.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (specialty != null)
                                  Text(
                                    specialty,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: BatshTypography.labelMd.copyWith(
                                      color: context.colorScheme.primary,
                                    ),
                                  ),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: BatshSpacing.xs,
                                  children: [
                                    if (area != null)
                                      Text(
                                        area,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: BatshTypography.labelSm.copyWith(
                                          color: context
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    if (listing.hasReviews)
                                      _Metric(
                                        icon: Icons.star_rounded,
                                        value: listing.reviewAvg
                                            .toStringAsFixed(1),
                                        color: context.colorScheme.tertiary,
                                      )
                                    else
                                      Text(
                                        'بدون تقييمات',
                                        style: BatshTypography.labelSm.copyWith(
                                          color: context
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

class _DirectoryFooter extends StatelessWidget {
  const _DirectoryFooter({
    required this.loading,
    required this.error,
    required this.hasMore,
    required this.onLoadMore,
  });

  final bool loading;
  final Object? error;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(BatshSpacing.lg),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(BatshSpacing.lg),
        child: OutlinedButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('تعذر تحميل المزيد — إعادة المحاولة'),
        ),
      );
    }
    if (!hasMore) {
      return const SizedBox(height: BatshSpacing.sm);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sectionH,
        BatshSpacing.sm,
        BatshSpacing.sectionH,
        0,
      ),
      child: OutlinedButton(
        onPressed: onLoadMore,
        child: const Text('عرض المزيد من المحترفين'),
      ),
    );
  }
}

class _CreateProjectBanner extends StatelessWidget {
  const _CreateProjectBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sectionH,
        BatshSpacing.md,
        BatshSpacing.sectionH,
        BatshSpacing.sectionH,
      ),
      child: Semantics(
        container: true,
        label: 'ابدأ بفكرة، وكملها مع محترف',
        child: Container(
          height: 132,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLow,
            borderRadius: BatshRadius.brLg,
            border: Border.all(
              color: context.colorScheme.primary.withValues(alpha: .22),
            ),
            boxShadow: BatshShadows.soft,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: .34,
                child: Image.asset(
                  'assets/images/professionals_header_architecture_v2.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomLeft,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colorScheme.surfaceContainerLow.withValues(
                        alpha: .18,
                      ),
                      context.colorScheme.surfaceContainerLow.withValues(
                        alpha: .92,
                      ),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Opacity(
                opacity: .12,
                child: ShattabPattern(
                  kind: ShattabPatternKind.lattice,
                  color: context.colorScheme.primary,
                  strokeWidth: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.md,
                  vertical: BatshSpacing.sm,
                ),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Expanded(
                      child: Text(
                        'ابدأ بفكرة،\nوكملها مع محترف',
                        textAlign: TextAlign.right,
                        style: BatshTypography.titleLg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    SizedBox(
                      height: 44,
                      width: 116,
                      child: FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('أضف مشروعك'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: BatshTypography.labelMd,
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
    );
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BatshRadius.brFull,
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            CircleAvatar(
              radius: 32,
              backgroundColor: context.colorScheme.primaryFixed,
              child: Icon(icon, color: context.colorScheme.primary, size: 30),
            ),
            const SizedBox(height: BatshSpacing.md),
            Text(title, style: BatshTypography.headlineSm),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyLg.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(action),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDraft {
  const _FilterDraft({this.specialty, this.city, this.minimumRating});

  final String? specialty;
  final String? city;
  final double? minimumRating;
}

class _FilterDraftSheet extends StatefulWidget {
  const _FilterDraftSheet({required this.initial});

  final DiscoveryFilters initial;

  @override
  State<_FilterDraftSheet> createState() => _FilterDraftSheetState();
}

class _FilterDraftSheetState extends State<_FilterDraftSheet> {
  late String? specialty = widget.initial.specialty;
  late String? city = widget.initial.city;
  late double? rating = widget.initial.minimumRating;

  @override
  Widget build(BuildContext context) {
    const specialties = [
      'full_reno',
      'design',
      'kitchen',
      'paint',
      'electrical',
      'plumbing',
      'carpentry',
      'flooring',
      'bathroom',
    ];
    return _SheetFrame(
      title: 'الفلاتر',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('التخصص', style: BatshTypography.titleMd),
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.xs,
            runSpacing: BatshSpacing.xs,
            children: specialties
                .map(
                  (key) => _ChoiceChip(
                    label: localizedSpecialtyLabel(context, key),
                    selected: specialty == key,
                    onTap: () => setState(
                      () => specialty = specialty == key ? null : key,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: BatshSpacing.lg),
          Text('المنطقة', style: BatshTypography.titleMd),
          const SizedBox(height: BatshSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: city,
            isExpanded: true,
            decoration: const InputDecoration(
              hintText: 'كل المناطق',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('كل المناطق'),
              ),
              ...OnboardingCatalog.citiesAndDistricts.map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.city,
                  child: Text(entry.city),
                ),
              ),
            ],
            onChanged: (value) => setState(() => city = value),
          ),
          const SizedBox(height: BatshSpacing.lg),
          Text('التقييم', style: BatshTypography.titleMd),
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.xs,
            children: [
              for (final value in [4.0, 4.5])
                _ChoiceChip(
                  label: '${value.toStringAsFixed(1)} نجمة فأعلى',
                  selected: rating == value,
                  onTap: () =>
                      setState(() => rating = rating == value ? null : value),
                ),
            ],
          ),
          const SizedBox(height: BatshSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    specialty = null;
                    city = null;
                    rating = null;
                  }),
                  child: const Text('مسح الفلاتر'),
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _FilterDraft(
                      specialty: specialty,
                      city: city,
                      minimumRating: rating,
                    ),
                  ),
                  child: const Text('عرض النتائج'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortSheet extends StatefulWidget {
  const _SortSheet({required this.initial});

  final DiscoverySort initial;

  @override
  State<_SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<_SortSheet> {
  late DiscoverySort selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'ترتيب النتائج',
      child: Column(
        children: [
          _SortOption(
            title: 'الافتراضي',
            selected: selected == DiscoverySort.name,
            onTap: () => setState(() => selected = DiscoverySort.name),
          ),
          _SortOption(
            title: 'الأعلى تقييماً',
            selected: selected == DiscoverySort.rating,
            onTap: () => setState(() => selected = DiscoverySort.rating),
          ),
          _SortOption(
            title: 'الأكثر مشاريع مكتملة',
            selected: selected == DiscoverySort.projects,
            onTap: () => setState(() => selected = DiscoverySort.projects),
          ),
          const SizedBox(height: BatshSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('تأكيد'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<bool>(
      groupValue: selected,
      onChanged: (_) => onTap(),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        title: Text(title, textAlign: TextAlign.end),
        leading: const Radio<bool>(value: true),
      ),
    );
  }
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({required this.initialCity});

  final String? initialCity;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _search = TextEditingController();
  late String? selected = widget.initialCity;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final cities = OnboardingCatalog.citiesAndDistricts
        .where((entry) => query.isEmpty || entry.city.contains(query))
        .toList();
    return _SheetFrame(
      title: 'اختر منطقة المشروع',
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              hintText: 'ابحث عن منطقة ...',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Flexible(
            child: RadioGroup<String>(
              groupValue: selected,
              onChanged: (value) => setState(() => selected = value),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cities.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: BatshSpacing.xs),
                itemBuilder: (_, index) {
                  final entry = cities[index];
                  final isSelected = selected == entry.city;
                  return ListTile(
                    onTap: () => setState(() => selected = entry.city),
                    shape: RoundedRectangleBorder(
                      borderRadius: BatshRadius.brMd,
                      side: BorderSide(
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.colorScheme.outlineVariant,
                      ),
                    ),
                    title: Text(entry.city, textAlign: TextAlign.end),
                    trailing: Radio<String>(value: entry.city),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, selected ?? ''),
              child: const Text('تأكيد المنطقة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.lg,
          BatshSpacing.xs,
          BatshSpacing.lg,
          BatshSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(BatshRadius.xxl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BatshRadius.brFull,
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
            Row(
              children: [
                Text(title, style: BatshTypography.headlineSm),
                const Spacer(),
                IconButton(
                  tooltip: 'إغلاق',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: BatshSpacing.sm),
            Flexible(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      showCheckmark: true,
      selectedColor: context.colorScheme.primaryFixed,
      side: BorderSide(
        color: selected
            ? context.colorScheme.primary
            : context.colorScheme.outlineVariant,
      ),
    );
  }
}

class _DirectoryLoading extends StatelessWidget {
  const _DirectoryLoading();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 172)),
        SliverPadding(
          padding: const EdgeInsets.all(BatshSpacing.sectionH),
          sliver: SliverList.builder(
            itemCount: 6,
            itemBuilder: (_, _) => Padding(
              padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
              child: Container(
                height: 142,
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHigh,
                  borderRadius: BatshRadius.brMd,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
