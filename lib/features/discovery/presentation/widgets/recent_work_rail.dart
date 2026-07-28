import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/widgets/batsh_initial_plate.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/batsh_section_header.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../portfolio/data/portfolio_repository.dart';
import '../../../portfolio/domain/portfolio_project.dart';

/// Finished work, not the people who did it.
///
/// Every other section on discover is contractor cards under a different sort,
/// so a homeowner browsing a renovation marketplace never actually saw a
/// renovation. This is the one rail that shows the product, and the one that
/// changes on its own as contractors post.
///
/// The whole rail disappears when there is nothing to show. An empty state
/// here would be a section header apologising for itself, and discover has
/// three other sections that stand without it.
class RecentWorkRail extends ConsumerWidget {
  const RecentWorkRail({super.key});

  /// Tall enough to read as photography rather than as thumbnails, short
  /// enough that the next section stays on screen and the rail still reads as
  /// one band within a scroll.
  static const double railHeight = 208;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(recentProjectsProvider);

    return projects.when(
      // A failed rail is not worth an error box on the primary browse screen;
      // the sections around it still work. Fail quiet.
      error: (_, _) => const SizedBox.shrink(),
      loading: () => const _RailFrame(child: _RailSkeleton()),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return _RailFrame(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.sectionH,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.sm),
            itemBuilder: (_, i) => _WorkTile(project: items[i]),
          ),
        );
      },
    );
  }
}

/// Section header plus the fixed-height band the rail scrolls inside.
class _RailFrame extends StatelessWidget {
  const _RailFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.sectionH,
            BatshSpacing.lg,
            BatshSpacing.sectionH,
            BatshSpacing.sm,
          ),
          child: BatshSectionHeader(title: context.l10n.recentWorkTitle),
        ),
        SizedBox(height: RecentWorkRail.railHeight, child: child),
      ],
    );
  }
}

/// One project: the cover photo, with the title over the foot of it.
///
/// Text on a photo needs a scrim, and a scrim greys the photograph, which is
/// why the contractor card stopped doing it. Here it earns its place: the tile
/// *is* the photo, so a caption underneath would either double the tile's
/// height or shrink the image to a thumbnail. The scrim is bottom-weighted and
/// only as deep as the title needs.
class _WorkTile extends StatelessWidget {
  const _WorkTile({required this.project});
  final PortfolioProject project;

  static const double width = 268;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        // Shadow outside the clip: a clipped Material clips its own shadow.
        decoration: BoxDecoration(
          borderRadius: BatshRadius.brLg,
          boxShadow: BatshShadows.soft,
        ),
        child: ClipRRect(
          borderRadius: BatshRadius.brLg,
          child: BatshPressable(
            semanticLabel: project.title,
            onTap: () => context.push(
              Routes.homeownerProjectDetailPath(
                project.contractorId,
                project.id,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: sizedImageUrl(project.coverPhotoUrl, width: 560),
                  fit: BoxFit.cover,
                  // Tile is 268dp wide; 2x covers high-DPI without decoding a
                  // full upload on the cheap Android hardware that is most of
                  // this market.
                  memCacheWidth: 560,
                  placeholder: (_, _) =>
                      ColoredBox(color: context.colorScheme.surfaceContainer),
                  errorWidget: (_, _, _) =>
                      BatshInitialPlate(name: project.title),
                ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Color(0xC2000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: BatshSpacing.sm,
                  end: BatshSpacing.sm,
                  bottom: BatshSpacing.sm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        project.title,
                        style: BatshTypography.labelLg.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (project.location != null &&
                          project.location!.isNotEmpty)
                        Text(
                          project.location!,
                          style: BatshTypography.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

/// Three tiles of shimmer at the real tile's width and radius, so the swap to
/// content does not shift the layout.
class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sectionH),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.sm),
      itemBuilder: (_, _) => const BatshShimmerBox(
        width: _WorkTile.width,
        height: RecentWorkRail.railHeight,
        borderRadius: BatshRadius.brLg,
      ),
    );
  }
}
