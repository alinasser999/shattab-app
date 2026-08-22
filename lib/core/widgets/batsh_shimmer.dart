import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/batsh_motion.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshShimmerBox extends StatelessWidget {
  const BatshShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh,
        borderRadius: borderRadius ?? BatshRadius.brDefault,
      ),
    );

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: context.l10n.loading,
      child: reduceMotion
          ? box
          : box
                .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                .shimmer(
                  duration: BatshMotion.slower,
                  curve: BatshMotion.easeInOut,
                  color: context.colorScheme.surfaceContainerLowest,
                ),
    );
  }
}

/// Groups a loading surface into one announcement instead of making a screen
/// reader announce every individual placeholder.
class BatshSkeletonRegion extends StatelessWidget {
  const BatshSkeletonRegion({super.key, required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: label ?? context.l10n.loading,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// Notification rows keep their real shape while account data is loading.
class BatshNotificationSkeleton extends StatelessWidget {
  const BatshNotificationSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return BatshSkeletonRegion(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.gutter,
          BatshSpacing.sm,
          BatshSpacing.gutter,
          BatshSpacing.xxl,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: BatshSpacing.xs),
        itemBuilder: (_, index) {
          final tile = _NotificationSkeletonTile();
          if (reduceMotion) return tile;
          return tile
              .animate(delay: BatshMotion.staggerClamped(index))
              .fadeIn(duration: BatshMotion.normal, curve: BatshMotion.easeOut);
        },
      ),
    );
  }
}

class _NotificationSkeletonTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brCard,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                BatshShimmerBox(width: 160, height: 16),
                SizedBox(height: BatshSpacing.xs),
                BatshShimmerBox(width: double.infinity, height: 12),
                SizedBox(height: BatshSpacing.xs),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: BatshShimmerBox(width: 76, height: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: BatshSpacing.md),
          const BatshShimmerBox(
            width: 44,
            height: 44,
            borderRadius: BatshRadius.brMd,
          ),
        ],
      ),
    );
  }
}

/// A small content-shaped footer used while the next page is being fetched.
/// It avoids a spinner that visually disconnects from the list above it.
class BatshPaginationSkeleton extends StatelessWidget {
  const BatshPaginationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BatshSkeletonRegion(
      label: context.l10n.loadingMore,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: BatshSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BatshShimmerBox(width: 56, height: 10),
            SizedBox(width: BatshSpacing.sm),
            BatshShimmerBox(
              width: 28,
              height: 28,
              borderRadius: BatshRadius.brFull,
            ),
            SizedBox(width: BatshSpacing.sm),
            BatshShimmerBox(width: 72, height: 10),
          ],
        ),
      ),
    );
  }
}

class BatshListSkeleton extends StatelessWidget {
  const BatshListSkeleton({super.key, this.count = 5, this.height = 96});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ListView.separated(
      padding: const EdgeInsets.all(BatshSpacing.gutter),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: BatshSpacing.md),
      itemBuilder: (_, i) {
        final item = BatshShimmerBox(
          height: height,
          borderRadius: BatshRadius.brLg,
        );
        if (reduceMotion) return item;
        return item.animate().fadeIn(
          duration: BatshMotion.normal,
          delay: BatshMotion.staggerClamped(i),
          curve: BatshMotion.easeOut,
        );
      },
    );
  }
}

class BatshProfileSkeleton extends StatelessWidget {
  const BatshProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          BatshShimmerBox(height: 200, borderRadius: BorderRadius.zero),
          Transform.translate(
            offset: const Offset(0, -48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.gutter,
              ),
              child: Column(
                children:
                    [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              BatshShimmerBox(
                                width: 104,
                                height: 104,
                                borderRadius: BatshRadius.brFull,
                              ),
                              const SizedBox(width: BatshSpacing.gutter),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 52),
                                    BatshShimmerBox(
                                      height: 20,
                                      width: double.infinity,
                                    ),
                                    const SizedBox(height: BatshSpacing.xs),
                                    BatshShimmerBox(height: 14, width: 140),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: BatshSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: BatshShimmerBox(
                                  height: 48,
                                  borderRadius: BatshRadius.brDefault,
                                ),
                              ),
                              const SizedBox(width: BatshSpacing.md),
                              Expanded(
                                child: BatshShimmerBox(
                                  height: 48,
                                  borderRadius: BatshRadius.brDefault,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: BatshSpacing.lg),
                          BatshShimmerBox(
                            height: 60,
                            borderRadius: BatshRadius.brLg,
                          ),
                          const SizedBox(height: BatshSpacing.md),
                          BatshShimmerBox(
                            height: 60,
                            borderRadius: BatshRadius.brLg,
                          ),
                          const SizedBox(height: BatshSpacing.md),
                          BatshShimmerBox(
                            height: 200,
                            borderRadius: BatshRadius.brLg,
                          ),
                        ]
                        .animate(interval: BatshMotion.staggerBase)
                        .fadeIn(
                          duration: BatshMotion.normal,
                          curve: BatshMotion.easeOut,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for a single comment row.
///
/// Mirrors the real row: a 32px avatar (radius 16) beside a name line and one
/// line of body.
class BatshCommentsSkeleton extends StatelessWidget {
  const BatshCommentsSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: BatshSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BatshShimmerBox(
                  width: 32,
                  height: 32,
                  borderRadius: BatshRadius.brFull,
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BatshShimmerBox(height: 12, width: 110),
                      const SizedBox(height: BatshSpacing.xs),
                      BatshShimmerBox(height: 12, width: double.infinity),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
            duration: BatshMotion.normal,
            delay: BatshMotion.staggerClamped(i),
            curve: BatshMotion.easeOut,
          ),
      ],
    );
  }
}

/// Placeholder for the explore post detail screen.
///
/// The dimensions here are copied from the real screen — a 44px author avatar
/// and a 300px media strip — rather than chosen to look good on their own. A
/// skeleton is a promise about the layout that is coming; if it guesses wrong,
/// the content jumps when it lands, and a jump is worse than the spinner this
/// replaced.
class BatshPostSkeleton extends StatelessWidget {
  const BatshPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BatshSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            [
                  Row(
                    children: [
                      BatshShimmerBox(
                        width: 44,
                        height: 44,
                        borderRadius: BatshRadius.brFull,
                      ),
                      const SizedBox(width: BatshSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BatshShimmerBox(height: 14, width: 150),
                            const SizedBox(height: BatshSpacing.xs),
                            BatshShimmerBox(height: 12, width: 90),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BatshSpacing.gutter),
                  BatshShimmerBox(height: 14, width: double.infinity),
                  const SizedBox(height: BatshSpacing.xs),
                  BatshShimmerBox(height: 14, width: 220),
                  const SizedBox(height: BatshSpacing.gutter),
                  BatshShimmerBox(
                    height: 300,
                    borderRadius: BatshRadius.brImage,
                  ),
                  const SizedBox(height: BatshSpacing.gutter),
                  BatshShimmerBox(height: 12, width: 120),
                  const SizedBox(height: BatshSpacing.md),
                  const BatshCommentsSkeleton(),
                ]
                .animate(interval: BatshMotion.staggerBase)
                .fadeIn(
                  duration: BatshMotion.normal,
                  curve: BatshMotion.easeOut,
                ),
      ),
    );
  }
}

/// Placeholder for an image-led detail screen: a tall cover, then a short
/// label, a title, and body copy. Matches the portfolio project layout, whose
/// cover occupies a 320px collapsing app bar.
class BatshHeroDetailSkeleton extends StatelessWidget {
  const BatshHeroDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BatshShimmerBox(height: 320, borderRadius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(BatshSpacing.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  [
                        BatshShimmerBox(height: 11, width: 80),
                        const SizedBox(height: BatshSpacing.sm),
                        BatshShimmerBox(height: 24, width: 240),
                        const SizedBox(height: BatshSpacing.md),
                        BatshShimmerBox(height: 13, width: 160),
                        const SizedBox(height: BatshSpacing.gutter),
                        BatshShimmerBox(height: 13, width: double.infinity),
                        const SizedBox(height: BatshSpacing.xs),
                        BatshShimmerBox(height: 13, width: double.infinity),
                        const SizedBox(height: BatshSpacing.xs),
                        BatshShimmerBox(height: 13, width: 200),
                      ]
                      .animate(interval: BatshMotion.staggerBase)
                      .fadeIn(
                        duration: BatshMotion.normal,
                        curve: BatshMotion.easeOut,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
