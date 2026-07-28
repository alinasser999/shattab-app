import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/batsh_colors.dart';
import '../../../../../core/theme/batsh_motion.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_spacing.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BatshRadius.brCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image block.
          AspectRatio(
            aspectRatio: 16 / 10,
            child: _shimmerBox(
              context,
              width: double.infinity,
              height: double.infinity,
              radius: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(BatshSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(context, width: double.infinity, height: 18),
                const SizedBox(height: BatshSpacing.xs),
                _shimmerBox(context, width: 180, height: 18),
                const SizedBox(height: BatshSpacing.md),
                Row(
                  children: [
                    _shimmerBox(context, width: 90, height: 14),
                    const SizedBox(width: BatshSpacing.sm),
                    _shimmerBox(context, width: 56, height: 20, radius: 999),
                    const Spacer(),
                    _shimmerBox(context, width: 40, height: 14),
                  ],
                ),
                const SizedBox(height: BatshSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _shimmerBox(
                        context,
                        width: double.infinity,
                        height: 46,
                        radius: 16,
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    Expanded(
                      child: _shimmerBox(
                        context,
                        width: double.infinity,
                        height: 46,
                        radius: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(
    BuildContext context, {
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(radius),
          ),
        )
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .shimmer(
          duration: BatshMotion.slower,
          curve: BatshMotion.easeInOut,
          color: context.colorScheme.surfaceContainerLowest,
        );
  }
}
