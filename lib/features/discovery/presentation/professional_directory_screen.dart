import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/l10n/catalog_labels.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import '../../portfolio/presentation/providers/portfolio_providers.dart';
import '../data/discovery_repository.dart';
import '../domain/contractor_listing.dart';
import '../domain/professional_reference_fixture.dart';
import 'providers/discovery_providers.dart';
import 'widgets/professional_reference_components.dart';

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
  String? _localSearchInput;
  final Map<String, bool> _optimisticSaved = {};
  Object? _loadMoreError;
  bool _loadingMore = false;

  int get _activeFilterCount {
    final filters = ref.read(discoveryFiltersControllerProvider);
    return (filters.specialty == null ? 0 : 1) +
        (filters.city == null ? 0 : 1) +
        (filters.minimumRating == null ? 0 : 1);
  }

  String? _normalizeSearchQuery(String? query) {
    final normalized = query?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  void initState() {
    super.initState();
    _searchController.text =
        ref.read(discoveryFiltersControllerProvider).searchQuery ?? '';
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
    _debounce?.cancel();
    _debounce = null;
    _localSearchInput = null;
    _searchController.clear();
    ref.read(discoveryFiltersControllerProvider.notifier).clear();
  }

  void _setSearch(String value) {
    _debounce?.cancel();
    _localSearchInput = value;
    final timer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted || _searchController.text != value) return;
      _debounce = null;
      ref.read(discoveryFiltersControllerProvider.notifier).setSearch(value);
    });
    _debounce = timer;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DiscoveryFilters>(discoveryFiltersControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.searchQuery == next.searchQuery) return;

      final localSearchInput = _localSearchInput;
      if (localSearchInput != null &&
          _normalizeSearchQuery(localSearchInput) ==
              _normalizeSearchQuery(next.searchQuery)) {
        // The provider query already represents the current field input. Keep
        // the user's exact text and cursor, including input not represented by
        // trim, whether the update came from this debounce or another control.
        return;
      }

      _debounce?.cancel();
      _debounce = null;
      _localSearchInput = null;
      final nextSearch = next.searchQuery ?? '';
      if (_searchController.text == nextSearch) return;
      _searchController.value = TextEditingValue(
        text: nextSearch,
        selection: TextSelection.collapsed(offset: nextSearch.length),
      );
    });
    final filters = ref.watch(discoveryFiltersControllerProvider);
    final contractors = ref.watch(discoverContractorsProvider);
    final sponsored = ref.watch(
      sponsoredProfessionalsProvider(filters.specialty, filters.city),
    );
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? <String>{};
    final hasQuery = filters.searchQuery?.isNotEmpty == true;
    final ids = <String>{};
    final items =
        <ContractorListing>[
              if (!hasQuery) ...?sponsored.value,
              ...?contractors.value,
            ]
            .where(
              (item) =>
                  (filters.sort != DiscoverySort.rating || item.hasReviews) &&
                  (filters.minimumRating == null ||
                      (item.rating != null &&
                          item.rating! >= filters.minimumRating!)) &&
                  ids.add(item.id),
            )
            .toList();
    final count = professionalReferenceEnabled && filters.isEmpty
        ? 124
        : items.length;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: referenceOrange,
          child: CustomScrollView(
            key: const PageStorageKey<String>('homeowner-professionals'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _ReferenceDirectoryHeader(
                  location: filters.city ?? context.l10n.cityNewCairo,
                  onLocation: _showLocation,
                  onFilters: _showFilters,
                  activeFilterCount: _activeFilterCount,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xfff4f4f8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.search,
                          size: 19,
                          color: Color(0xff24262c),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _setSearch,
                            style: referenceText(11.5),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: context.l10n.referenceSearchHint,
                              hintStyle: referenceText(
                                11.5,
                                color: referenceMuted,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.only(bottom: 8),
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 30,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(
                                    discoveryFiltersControllerProvider.notifier,
                                  )
                                  .setSearch(null);
                            },
                            icon: const Icon(
                              Icons.close,
                              color: referenceMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _ReferenceCategoryRail(
                    selected: filters.specialty,
                    onSelected: (key) => ref
                        .read(discoveryFiltersControllerProvider.notifier)
                        .setSpecialty(key),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    height: 34,
                    child: Row(
                      children: [
                        Text(
                          !professionalReferenceEnabled &&
                                  ref
                                      .read(
                                        discoverContractorsProvider.notifier,
                                      )
                                      .hasMore
                              ? context.l10n
                                    .referenceDisplayedProfessionalsCount(count)
                              : context.l10n.referenceProfessionalsCount(count),
                          style: referenceText(11.5),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _showSort,
                          child: SizedBox(
                            height: 34,
                            child: Row(
                              children: [
                                Text(
                                  context.l10n.referenceSort,
                                  style: referenceText(
                                    10.5,
                                    color: referenceMuted,
                                  ),
                                ),
                                Text(
                                  switch (filters.sort) {
                                    DiscoverySort.name =>
                                      hasQuery
                                          ? context.l10n.referenceRelevant
                                          : context.l10n.referenceCompatible,
                                    DiscoverySort.rating =>
                                      context.l10n.topRated,
                                    DiscoverySort.projects =>
                                      context.l10n.referenceMostProjects,
                                  },
                                  style: referenceText(
                                    10.5,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.expand_more,
                                  size: 16,
                                  color: referenceNavy,
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
              if (contractors.hasError && items.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.unknownErrorRetry,
                            style: referenceText(11, color: referenceMuted),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(discoverContractorsProvider),
                          child: Text(context.l10n.tryAgain),
                        ),
                      ],
                    ),
                  ),
                ),
              if (contractors.isLoading && items.isEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: Center(
                      child: CircularProgressIndicator(color: referenceOrange),
                    ),
                  ),
                )
              else if (contractors.hasError && items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          ErrorMapper.map(contractors.error!),
                          style: referenceText(14),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(discoverContractorsProvider),
                          child: Text(context.l10n.tryAgain),
                        ),
                      ],
                    ),
                  ),
                )
              else if (items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          context.l10n.noResultsFound,
                          style: referenceText(14),
                        ),
                        TextButton(
                          onPressed: _clearAll,
                          child: Text(context.l10n.clearFilters),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final listing = items[index];
                      return Consumer(
                        key: ValueKey(listing.id),
                        builder: (context, cardRef, _) {
                          final saved =
                              _optimisticSaved[listing.id] ??
                              savedIds.contains(listing.id);
                          final projects =
                              cardRef
                                  .watch(
                                    portfolioForContractorProvider(listing.id),
                                  )
                                  .value ??
                              const [];
                          final photos =
                              professionalReferenceEnabled &&
                                  listing.id ==
                                      ProfessionalReferenceFixture.noorId
                              ? ProfessionalReferenceFixture.galleryMediaForId(
                                      listing.id,
                                    )
                                    .map(
                                      (url) =>
                                          url ==
                                              ProfessionalReferenceFixture
                                                  .livingRoomImage
                                          ? 'assets/images/professional_reference_living_card.png'
                                          : url,
                                    )
                                    .toList()
                              : <String>{
                                      if (referenceMediaAllowed(
                                        listing.coverPhotoUrl,
                                      ))
                                        listing.coverPhotoUrl!,
                                      ...projects
                                          .expand(
                                            (p) => [
                                              p.coverPhotoUrl,
                                              ...p.photoUrls,
                                            ],
                                          )
                                          .where(referenceMediaAllowed),
                                    }
                                    .map(
                                      (url) =>
                                          professionalReferenceEnabled &&
                                              ProfessionalReferenceFixture.isFixtureId(
                                                listing.id,
                                              ) &&
                                              url ==
                                                  ProfessionalReferenceFixture
                                                      .bathroomImage
                                          ? 'assets/images/professional_reference_bathroom_card.png'
                                          : url,
                                    )
                                    .toList();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: ReferenceProfessionalCard(
                              listing: listing,
                              saved: saved,
                              photos: photos,
                              onOpen: () => context.push(
                                Routes.homeownerContractorProfilePath(
                                  listing.id,
                                ),
                              ),
                              onSave: () {
                                if (professionalReferenceEnabled &&
                                    ProfessionalReferenceFixture.isFixtureId(
                                      listing.id,
                                    )) {
                                  unawaited(
                                    _toggleSave(
                                      listing.id,
                                      currentlySaved: saved,
                                    ),
                                  );
                                } else {
                                  runSignedIn(
                                    context,
                                    ref,
                                    reason: context.l10n.signInToSave,
                                    action: () => _toggleSave(
                                      listing.id,
                                      currentlySaved: saved,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(color: referenceOrange),
                    ),
                  ),
                ),
              if (_loadMoreError != null)
                SliverToBoxAdapter(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: Text(context.l10n.tryAgain),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceDirectoryHeader extends StatelessWidget {
  const _ReferenceDirectoryHeader({
    required this.location,
    required this.onLocation,
    required this.onFilters,
    required this.activeFilterCount,
  });
  final String location;
  final VoidCallback onLocation, onFilters;
  final int activeFilterCount;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 47,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 18,
          top: 8,
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    'شطّب',
                    style: referenceText(
                      24,
                      color: referenceOrange,
                      weight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    'S H A T B',
                    style: referenceText(
                      7.5,
                      color: referenceOrange,
                      weight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.home_rounded, color: referenceOrange, size: 22),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.referenceProfessionalsTitle,
              style: referenceText(16, weight: FontWeight.w800),
            ),
            InkWell(
              onTap: onLocation,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: referenceMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      location,
                      style: referenceText(10, color: referenceMuted),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.expand_more,
                      size: 13,
                      color: referenceNavy,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 5,
          child: Stack(
            children: [
              ReferenceIconButton(
                icon: Icons.tune,
                label: 'الفلاتر',
                onTap: onFilters,
                size: 20,
                color: const Color(0xff44454e),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: referenceOrange,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$activeFilterCount',
                      style: referenceText(8, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReferenceCategoryRail extends StatelessWidget {
  const _ReferenceCategoryRail({
    required this.selected,
    required this.onSelected,
  });
  final String? selected;
  final ValueChanged<String?> onSelected;
  @override
  Widget build(BuildContext context) {
    const keys = <String?>[
      null,
      'design',
      'plumbing',
      'electrical',
      'full_reno',
      'kitchen',
    ];
    final labels = [
      context.l10n.referenceAll,
      context.l10n.referenceInteriorDesign,
      context.l10n.referencePlumbing,
      context.l10n.referenceElectricity,
      context.l10n.referenceFinishing,
      context.l10n.referenceKitchen,
    ];
    const icons = [
      Icons.grid_view_outlined,
      Icons.chair_outlined,
      Icons.plumbing_outlined,
      Icons.bolt_outlined,
      Icons.format_paint_outlined,
      Icons.kitchen_outlined,
    ];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: keys.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = keys[i] == selected;
            return Semantics(
              button: true,
              selected: active,
              label: labels[i],
              excludeSemantics: true,
              onTap: () => onSelected(keys[i]),
              child: InkWell(
                onTap: () => onSelected(keys[i]),
                borderRadius: BorderRadius.circular(9),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 40,
                    width: i == 0
                        ? 43
                        : i == 1
                        ? 64
                        : 48,
                    decoration: BoxDecoration(
                      color: active ? referenceOrange : Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xfffbf2ed)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffbd9671).withValues(alpha: .06),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[i],
                          size: 18,
                          color: active ? Colors.white : referenceOrange,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          labels[i],
                          style: referenceText(
                            10,
                            color: active ? Colors.white : referenceNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
    return Semantics(
      label: title,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: RadioGroup<bool>(
          groupValue: selected,
          onChanged: (_) => onTap(),
          child: ListTile(
            onTap: onTap,
            contentPadding: EdgeInsets.zero,
            title: Text(title, textAlign: TextAlign.end),
            leading: const Radio<bool>(value: true),
          ),
        ),
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
      scrollContent: false,
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
                primary: false,
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
  const _SheetFrame({
    required this.title,
    required this.child,
    this.scrollContent = true,
  });

  final String title;
  final Widget child;
  final bool scrollContent;

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
        child: Material(
          color: Colors.transparent,
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
              Flexible(
                child: scrollContent
                    ? SingleChildScrollView(child: child)
                    : child,
              ),
            ],
          ),
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
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: FilterChip(
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
        ),
      ),
    );
  }
}
