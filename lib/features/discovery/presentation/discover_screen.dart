import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_loading.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/contractor_card.dart';
import '../../../core/widgets/featured_contractors_strip.dart';
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

  @override
  void dispose() {
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.marginMobile,
              BatshSpacing.sm,
              BatshSpacing.marginMobile,
              0,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => ref
                  .read(discoveryFiltersControllerProvider.notifier)
                  .setSearch(v),
              decoration: InputDecoration(
                hintText: 'دور باسم المقاول أو الشركة…',
                prefixIcon: const Icon(Icons.search,
                    color: BatshColors.onSurfaceVariant),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(discoveryFiltersControllerProvider.notifier)
                              .setSearch(null);
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          _FilterRow(
            selected: filters.specialty,
            entries: OnboardingCatalog.specialtiesCatalog,
            allLabel: 'كل التخصصات',
            onSelect: (key) => ref
                .read(discoveryFiltersControllerProvider.notifier)
                .setSpecialty(key),
          ),
          const SizedBox(height: BatshSpacing.sm),
          _FilterRow(
            selected: filters.city,
            entries: {
              for (final c in OnboardingCatalog.citiesAndDistricts)
                c.city: c.city,
            },
            allLabel: 'كل المحافظات',
            onSelect: (key) => ref
                .read(discoveryFiltersControllerProvider.notifier)
                .setCity(key),
          ),
          const SizedBox(height: BatshSpacing.md),
          Expanded(
            child: contractorsAsync.when(
              loading: () => const BatshLoading(),
              error: (e, _) => BatshError(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(discoverContractorsProvider)),
              data: (list) {
                if (list.isEmpty) {
                  return const BatshEmptyState(
                    title: 'مفيش مقاولين بالشروط دي',
                    message: 'جرّب تغيّر التخصص أو المحافظة',
                    icon: Icons.search_off_outlined,
                  );
                }
                final featured = filters.isEmpty
                    ? (List.of(list)
                          ..sort((a, b) =>
                              b.computedRating.compareTo(a.computedRating)))
                        .take(5)
                        .toList()
                    : <ContractorListing>[];

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(discoverContractorsProvider),
                  child: ListView(
                    padding:
                        const EdgeInsets.only(bottom: BatshSpacing.xl),
                    children: [
                      if (featured.isNotEmpty) ...[
                        FeaturedContractorsStrip(
                          contractors: featured,
                          onTap: (c) => context.push(
                              Routes.homeownerContractorProfilePath(c.id)),
                        ),
                        const SizedBox(height: BatshSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: BatshSpacing.marginMobile),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: BatshColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: BatshSpacing.sm),
                              Text(
                                'كل المقاولين (${list.length})',
                                style: BatshTypography.titleLg.copyWith(
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: BatshSpacing.sm),
                      ],
                      for (final c in list) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: BatshSpacing.marginMobile),
                          child: ContractorCard(
                            listing: c,
                            isSaved: savedIds.contains(c.id),
                            onToggleSave: () => ref
                                .read(savedControllerProvider.notifier)
                                .toggle(c.id),
                            onTap: () => context.push(
                                Routes.homeownerContractorProfilePath(c.id)),
                          ),
                        ),
                        const SizedBox(height: BatshSpacing.md),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.entries,
    required this.allLabel,
    required this.onSelect,
  });

  final String? selected;
  final Map<String, String> entries;
  final String allLabel;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile),
        children: [
          _FilterChip(
            label: allLabel,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: BatshSpacing.sm),
          for (final e in entries.entries) ...[
            _FilterChip(
              label: e.value,
              selected: selected == e.key,
              onTap: () => onSelect(selected == e.key ? null : e.key),
            ),
            const SizedBox(width: BatshSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? BatshColors.primaryFixed
          : BatshColors.surfaceContainer,
      borderRadius: BatshRadius.brFull,
      child: InkWell(
        borderRadius: BatshRadius.brFull,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.gutter, vertical: BatshSpacing.sm),
          child: Text(label,
              style: BatshTypography.labelMd.copyWith(
                color: selected
                    ? BatshColors.primary
                    : BatshColors.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              )),
        ),
      ),
    );
  }
}
