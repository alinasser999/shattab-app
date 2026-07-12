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
      child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerHigh,
        borderRadius: borderRadius ?? BatshRadius.brDefault,
      ),
    ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).shimmer(
          duration: BatshMotion.slower,
          curve: BatshMotion.easeInOut,
          color: BatshColors.surfaceContainerLowest,
        ));
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
      itemBuilder: (_, i) => BatshShimmerBox(
        height: height,
        borderRadius: BatshRadius.brLg,
      ).animate().fadeIn(
            duration: BatshMotion.normal,
            delay: BatshMotion.staggerClamped(i),
            curve: Curves.easeOut,
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
              padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
              child: Column(
                children: [
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
                                height: 20, width: double.infinity),
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
                              height: 48, borderRadius: BatshRadius.brDefault)),
                      const SizedBox(width: BatshSpacing.md),
                      Expanded(
                          child: BatshShimmerBox(
                              height: 48, borderRadius: BatshRadius.brDefault)),
                    ],
                  ),
                  const SizedBox(height: BatshSpacing.lg),
                  BatshShimmerBox(
                      height: 60, borderRadius: BatshRadius.brLg),
                  const SizedBox(height: BatshSpacing.md),
                  BatshShimmerBox(
                      height: 60, borderRadius: BatshRadius.brLg),
                  const SizedBox(height: BatshSpacing.md),
                  BatshShimmerBox(
                      height: 200, borderRadius: BatshRadius.brLg),
                ].animate(interval: BatshMotion.staggerBase).fadeIn(
                      duration: BatshMotion.normal,
                      curve: Curves.easeOut,
                    ),
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
          colors: [
            BatshColors.primaryContainer,
            BatshColors.tertiaryContainer,
          ],
        ),
      ),
    );
  }
}
