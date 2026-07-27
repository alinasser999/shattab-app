import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_motion.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';

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
    return Semantics(
      label: S.loading,
      child:
          Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: BatshColors.surfaceContainerHigh,
                  borderRadius: borderRadius ?? BatshRadius.brDefault,
                ),
              )
              .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
              .shimmer(
                duration: BatshMotion.slower,
                curve: BatshMotion.easeInOut,
                color: BatshColors.surfaceContainerLowest,
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
    return ListView.separated(
      padding: const EdgeInsets.all(BatshSpacing.gutter),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: BatshSpacing.md),
      itemBuilder: (_, i) =>
          BatshShimmerBox(
            height: height,
            borderRadius: BatshRadius.brLg,
          ).animate().fadeIn(
            duration: BatshMotion.normal,
            delay: BatshMotion.staggerClamped(i),
            curve: BatshMotion.easeOut,
          ),
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

class BatshGradientFallback extends StatelessWidget {
  const BatshGradientFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [BatshColors.primaryContainer, BatshColors.tertiaryContainer],
        ),
      ),
    );
  }
}
