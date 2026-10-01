import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/cache/media_cache.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/batsh_initial_plate.dart';
import '../../../../core/widgets/batsh_section_header.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../portfolio/data/portfolio_repository.dart';
import '../../../portfolio/domain/portfolio_project.dart';
import '../../../../core/utils/image_url.dart';

/// A dark visual chapter that keeps the discovery screen from becoming a
/// stack of identical cream cards. Real projects win; visual fallbacks keep a
/// new catalogue from looking unfinished while a professional builds a folio.
class RecentWorkRail extends ConsumerWidget {
  const RecentWorkRail({super.key, this.skip = 0, this.fallbackContractorId});

  final int skip;
  final String? fallbackContractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(recentProjectsProvider);
    return projects.when(
      error: (_, _) => const SizedBox.shrink(),
      loading: () => const _RailFrame.loading(),
      data: (all) {
        final actual = skip > 0 ? all.skip(skip).toList() : all;
        if (actual.isEmpty) return const SizedBox.shrink();
        final items = actual.map(_RailItem.fromProject).toList();
        return _RailFrame(items: items, fallbackContractorId: null);
      },
    );
  }
}

class _RailFrame extends StatelessWidget {
  const _RailFrame({required this.items, this.fallbackContractorId})
    : loading = false;

  const _RailFrame.loading()
    : items = const [],
      fallbackContractorId = null,
      loading = true;

  final List<_RailItem> items;
  final String? fallbackContractorId;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tileWidth = ((MediaQuery.sizeOf(context).width - 64) / 3).clamp(
      118.0,
      210.0,
    );
    return Container(
      margin: const EdgeInsets.only(top: BatshSpacing.sm),
      padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
      color: context.colorScheme.inverseSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.sectionH,
              0,
              BatshSpacing.sectionH,
              BatshSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: BatshSectionHeader(
                    title:
                        items.isNotEmpty &&
                            items.every((item) => item.isPlaceholder)
                        ? context.l10n.workInspirationTitle
                        : context.l10n.recentWorkTitle,
                    emphasis: BatshSectionEmphasis.major,
                    color: context.colorScheme.onInverseSurface,
                    padding: EdgeInsets.zero,
                  ),
                ),
                BatshButton(
                  style: BatshButtonStyle.ghost,
                  fullWidth: false,
                  animate: false,
                  onPressed: () => context.push(Routes.homeownerCompletedWork),
                  label: context.l10n.viewAll,
                  foregroundColor: context.colorScheme.onInverseSurface,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 166,
            child: loading
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.sectionH,
                    ),
                    itemCount: 3,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: BatshSpacing.sm),
                    itemBuilder: (_, _) => BatshShimmerBox(
                      width: tileWidth,
                      height: 166,
                      borderRadius: BatshRadius.brLg,
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.sectionH,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: BatshSpacing.sm),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return SizedBox(
                        width: tileWidth,
                        child: _WorkTile(
                          item: item,
                          fallbackContractorId: fallbackContractorId,
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

class _WorkTile extends StatelessWidget {
  const _WorkTile({required this.item, this.fallbackContractorId});

  final _RailItem item;
  final String? fallbackContractorId;

  @override
  Widget build(BuildContext context) {
    final onTap = item.projectId != null && item.contractorId != null
        ? () => context.push(
            Routes.homeownerProjectDetailPath(
              item.contractorId!,
              item.projectId!,
            ),
          )
        : fallbackContractorId == null
        ? null
        : () => context.push(
            Routes.homeownerContractorProfilePath(fallbackContractorId!),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BatshRadius.brLg,
        boxShadow: BatshShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BatshRadius.brLg,
        child: BatshPressable(
          onTap: onTap,
          semanticLabel: item.title,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isDisplayableImageUrl(item.url))
                CachedNetworkImage(
                  imageUrl: sizedImageUrl(item.url, width: 560),
                  cacheManager: mediaCacheManager,
                  fit: BoxFit.cover,
                  memCacheWidth: 560,
                  errorWidget: (_, _, _) => BatshInitialPlate(name: item.title),
                )
              else
                BatshInitialPlate(name: item.title),
              PositionedDirectional(
                start: BatshSpacing.sm,
                end: BatshSpacing.sm,
                bottom: BatshSpacing.sm,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelMd.copyWith(
                          color: context.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelSm.copyWith(
                          color: context.colorScheme.onPrimary.withValues(
                            alpha: 0.84,
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
    );
  }
}

class _RailItem {
  const _RailItem({
    required this.url,
    required this.title,
    required this.subtitle,
    this.projectId,
    this.contractorId,
    this.isPlaceholder = false,
  });

  factory _RailItem.fromProject(PortfolioProject project) => _RailItem(
    url: project.coverPhotoUrl,
    title: project.title,
    subtitle: project.location ?? project.category ?? '',
    projectId: project.id,
    contractorId: project.contractorId,
    isPlaceholder: false,
  );

  final String url;
  final String title;
  final String subtitle;
  final String? projectId;
  final String? contractorId;
  final bool isPlaceholder;
}
