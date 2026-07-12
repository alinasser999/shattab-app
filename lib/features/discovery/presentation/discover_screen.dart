import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_filter_sheet.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/contractor_card.dart';
import '../../../core/utils/error_mapper.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import '../domain/contractor_listing.dart';
import 'providers/discovery_providers.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  int get _activeFilterCount {
    final f = ref.read(discoveryFiltersControllerProvider);
    return (f.specialty != null ? 1 : 0) + (f.city != null ? 1 : 0);
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final filters = ref.read(discoveryFiltersControllerProvider);
    final initial = <String>{};
    if (filters.specialty != null) initial.add('specialty:${filters.specialty}');
    if (filters.city != null) initial.add('city:${filters.city}');

    final specialties = OnboardingCatalog.specialtiesCatalog.entries.map(
      (e) => FilterOption(value: 'specialty:${e.key}', label: e.value, icon: Icons.category_rounded),
    ).toList();
    final cities = OnboardingCatalog.citiesAndDistricts.map(
      (c) => FilterOption(value: 'city:${c.city}', label: c.city, icon: Icons.location_on_rounded),
    ).toList();

    final sections = [
      BatshFilterSheetSection(
        title: S.filterCategory,
        icon: Icons.category_rounded,
        singleSelect: true,
        options: specialties,
      ),
      BatshFilterSheetSection(
        title: S.filterCity,
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
      ctrl.setSpecialty(specialtyKey.isNotEmpty ? specialtyKey.replaceFirst('specialty:', '') : null);
      ctrl.setCity(cityKey.isNotEmpty ? cityKey.replaceFirst('city:', '') : null);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(discoveryFiltersControllerProvider);
    final contractorsAsync = ref.watch(discoverContractorsProvider);
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? {};

    return BatshScaffold(
      title: S.tabDiscover,
      padding: EdgeInsets.zero,
      body: contractorsAsync.when(
        loading: () => const _DiscoverSkeleton(),
        error: (e, _) => BatshError(
            message: ErrorMapper.map(e),
            onRetry: () => ref.invalidate(discoverContractorsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: BatshEmptyState(
                title: S.noContractorsTitle,
                message: S.noContractorsMessage,
                icon: Icons.search_off_outlined,
              ),
            );
          }

          // Featured shelf only when the catalog can fill both shelves —
          // otherwise it swallows everyone and "all contractors" reads (0).
          final featured = filters.isEmpty && list.length > 6
              ? (List.of(list)
                    ..sort((a, b) =>
                        b.displayRating.compareTo(a.displayRating)))
                  .take(5)
                  .toList()
              : <ContractorListing>[];
          // The "all" list drops whoever is already in the featured shelf so
          // the same contractor never appears twice on one screen.
          final featuredIds = featured.map((c) => c.id).toSet();
          final rest = featuredIds.isEmpty
              ? list
              : list.where((c) => !featuredIds.contains(c.id)).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(discoverContractorsProvider);
              await ref.read(discoverContractorsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.marginMobile,
                      BatshSpacing.sm,
                      BatshSpacing.marginMobile,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SearchBar(
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
                        const SizedBox(width: BatshSpacing.sm),
                        BatshFilterButton(
                          activeCount: _activeFilterCount,
                          onTap: () => _openFilterSheet(context),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filters.specialty != null || filters.city != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        BatshSpacing.marginMobile,
                        BatshSpacing.sm,
                        BatshSpacing.marginMobile,
                        0,
                      ),
                      child: SizedBox(
                        height: 30,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (filters.specialty != null)
                              Padding(
                                padding: const EdgeInsets.only(right: BatshSpacing.xs),
                                child: BatshActiveFilterChip(
                                  label: OnboardingCatalog.specialtiesCatalog[filters.specialty] ?? filters.specialty!,
                                  onRemove: () => ref.read(discoveryFiltersControllerProvider.notifier).setSpecialty(null),
                                ),
                              ),
                            if (filters.city != null)
                              Padding(
                                padding: const EdgeInsets.only(right: BatshSpacing.xs),
                                child: BatshActiveFilterChip(
                                  label: filters.city!,
                                  onRemove: () => ref.read(discoveryFiltersControllerProvider.notifier).setCity(null),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (featured.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        BatshSpacing.marginMobile,
                        BatshSpacing.lg,
                        BatshSpacing.marginMobile,
                        0,
                      ),
                      child: _SectionHeader(
                        title: S.featuredContractors,
                        onViewAll: null,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 280,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: BatshSpacing.marginMobile),
                        physics: const BouncingScrollPhysics(),
                        itemCount: featured.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: BatshSpacing.gutter),
                        itemBuilder: (_, i) => _FeaturedPremiumCard(
                          listing: featured[i],
                          onTap: () => context.push(
                              Routes.homeownerContractorProfilePath(
                                  featured[i].id)),
                        ).animate().fadeIn(
                          delay: BatshMotion.staggerClamped(i),
                          duration: BatshMotion.normal,
                          curve: Curves.easeOut,
                        ).slideY(
                          begin: 0.08,
                          end: 0,
                          curve: BatshMotion.easeOut,
                        ),
                      ),
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.marginMobile,
                      BatshSpacing.lg,
                      BatshSpacing.marginMobile,
                      0,
                    ),
                    child: _SectionHeader(
                      title: '${S.allContractors} (${rest.length})',
                      onViewAll: null,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    BatshSpacing.marginMobile,
                    BatshSpacing.sm,
                    BatshSpacing.marginMobile,
                    BatshSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final item = rest[i];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: BatshSpacing.md),
                          child: ContractorCard(
                            listing: item,
                            isSaved: savedIds.contains(item.id),
                            onToggleSave: () => runSignedIn(
                              context,
                              ref,
                              reason: S.signInToSave,
                              action: () => ref
                                  .read(savedControllerProvider.notifier)
                                  .toggle(item.id),
                            ),
                            onTap: () => context.push(
                                Routes.homeownerContractorProfilePath(
                                    item.id)),
                          )
                              .animate()
                              .fadeIn(
                                  delay: (60 * i.clamp(0, 8)).ms,
                                  duration: BatshMotion.normal,
                                  curve: Curves.easeOut)
                              .slideY(
                                  begin: 0.06,
                                  end: 0,
                                  curve: BatshMotion.easeOut),
                        );
                      },
                      childCount: rest.length,
                    ),
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
      decoration: BoxDecoration(
        color: BatshColors.cardBackground,
        borderRadius: BatshRadius.brXxl,
        boxShadow: BatshShadows.soft,
      ),
      child: Row(
        children: [
          const SizedBox(width: BatshSpacing.gutter),
          Icon(Icons.search_rounded,
              color: BatshColors.onSurfaceVariant, size: 22),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: S.searchHint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: BatshTypography.bodyMd,
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: widget.onClear,
              child: Padding(
                padding: const EdgeInsets.all(BatshSpacing.xs),
                child: Icon(Icons.close_rounded,
                    color: BatshColors.onSurfaceVariant, size: 20),
              ),
            ),
          const SizedBox(width: BatshSpacing.gutter),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.onViewAll,
  });

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: BatshColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(
          child: Text(title,
              style: BatshTypography.titleLg
                  .copyWith(fontWeight: FontWeight.w700)),
        ),
        if (onViewAll != null) ...[
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text(S.viewAll,
                    style: BatshTypography.labelMd.copyWith(
                        color: BatshColors.primary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_left_rounded,
                    color: BatshColors.primary, size: 18),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FeaturedPremiumCard extends StatelessWidget {
  const _FeaturedPremiumCard({
    required this.listing,
    required this.onTap,
  });

  final ContractorListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.isNotEmpty
        ? listing.businessName
        : listing.fullName;
    final topSpecialties = listing.specialties.take(2).toList();

    return SizedBox(
      width: 210,
      child: Material(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brLg,
              boxShadow: BatshShadows.elevated,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BatshRadius.brLg,
                  child: listing.coverPhotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: listing.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const ColoredBox(
                              color: BatshColors.surfaceContainer),
                          errorWidget: (_, _, _) => const _FeaturedFallback(),
                        )
                      : const _FeaturedFallback(),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // "موثوق" chip removed — no verification process backs it yet.
                Positioned(
                  top: BatshSpacing.sm,
                  left: BatshSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: BatshSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BatshRadius.brFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            listing.reviewCount == 0
                                ? Icons.auto_awesome
                                : Icons.star,
                            size: 12,
                            color: BatshColors.tertiaryFixed),
                        const SizedBox(width: 4),
                        Text(
                            listing.reviewCount == 0
                                ? S.newBadge
                                : listing.displayRating.toStringAsFixed(1),
                            style: BatshTypography.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: BatshSpacing.gutter,
                  right: BatshSpacing.gutter,
                  bottom: BatshSpacing.gutter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.titleMd.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: BatshSpacing.xs),
                      if (listing.headline != null) ...[
                        Text(
                          listing.headline!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                      if (topSpecialties.isNotEmpty) ...[
                        const SizedBox(height: BatshSpacing.sm),
                        Wrap(
                          spacing: BatshSpacing.xs,
                          children: [
                            for (final s in topSpecialties)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: BatshSpacing.sm, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BatshRadius.brFull,
                                ),
                                child: Text(
                                    OnboardingCatalog
                                            .specialtiesCatalog[s] ??
                                        s,
                                    style: BatshTypography.labelSm.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      ],
                    ],
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

class _FeaturedFallback extends StatelessWidget {
  const _FeaturedFallback();

  @override
  Widget build(BuildContext context) {
    return const BatshGradientFallback();
  }
}

class _DiscoverSkeleton extends StatelessWidget {
  const _DiscoverSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.marginMobile,
        BatshSpacing.sm,
        BatshSpacing.marginMobile,
        BatshSpacing.xl,
      ),
      children: [
        BatshShimmerBox(
          height: 52,
          borderRadius: BatshRadius.brXxl,
        ),
        const SizedBox(height: BatshSpacing.md),
        Row(
          children: [
            BatshShimmerBox(
              width: 90,
              height: 34,
              borderRadius: BatshRadius.brFull,
            ),
            const SizedBox(width: BatshSpacing.sm),
            BatshShimmerBox(
              width: 70,
              height: 34,
              borderRadius: BatshRadius.brFull,
            ),
            const SizedBox(width: BatshSpacing.sm),
            BatshShimmerBox(
              width: 80,
              height: 34,
              borderRadius: BatshRadius.brFull,
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.sm),
        Row(
          children: [
            BatshShimmerBox(
              width: 80,
              height: 34,
              borderRadius: BatshRadius.brFull,
            ),
            const SizedBox(width: BatshSpacing.sm),
            BatshShimmerBox(
              width: 100,
              height: 34,
              borderRadius: BatshRadius.brFull,
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.lg),
        Row(
          children: [
            BatshShimmerBox(
              width: 4,
              height: 18,
              borderRadius: BatshRadius.brXs,
            ),
            const SizedBox(width: BatshSpacing.sm),
            BatshShimmerBox(
              width: 120,
              height: 20,
              borderRadius: BatshRadius.brXs,
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.sm),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, _) =>
                const SizedBox(width: BatshSpacing.gutter),
            itemBuilder: (_, i) => BatshShimmerBox(
              width: 210,
              height: 280,
              borderRadius: BatshRadius.brLg,
            ).animate().fadeIn(
              duration: BatshMotion.normal,
              delay: BatshMotion.staggerClamped(i),
              curve: Curves.easeOut,
            ),
          ),
        ),
        const SizedBox(height: BatshSpacing.lg),
        Row(
          children: [
            BatshShimmerBox(
              width: 4,
              height: 18,
              borderRadius: BatshRadius.brXs,
            ),
            const SizedBox(width: BatshSpacing.sm),
            BatshShimmerBox(
              width: 100,
              height: 20,
              borderRadius: BatshRadius.brXs,
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.sm),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, _) =>
                const SizedBox(width: BatshSpacing.sm),
            itemBuilder: (_, i) => BatshShimmerBox(
              width: 210,
              height: 140,
              borderRadius: BatshRadius.brLg,
            ).animate().fadeIn(
              duration: BatshMotion.normal,
              delay: BatshMotion.staggerClamped(i + 3),
              curve: Curves.easeOut,
            ),
          ),
        ),
        const SizedBox(height: BatshSpacing.lg),
        Row(
          children: [
            BatshShimmerBox(
              width: 4,
              height: 18,
              borderRadius: BatshRadius.brXs,
            ),
            const SizedBox(width: BatshSpacing.sm),
            BatshShimmerBox(
              width: 140,
              height: 20,
              borderRadius: BatshRadius.brXs,
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.sm),
        for (var i = 0; i < 3; i++) ...[
          BatshShimmerBox(
            height: 232,
            borderRadius: BatshRadius.brLg,
          ).animate().fadeIn(
            duration: BatshMotion.normal,
            delay: BatshMotion.staggerClamped(i),
            curve: Curves.easeOut,
          ),
          const SizedBox(height: BatshSpacing.md),
        ],
      ],
    );
  }
}
