import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/batsh_motion.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';

class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(BatshRadius.xl),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _SkeletonBox(width: 120, height: 14),
              const Spacer(),
              _SkeletonBox(
                width: 44,
                height: 44,
                radius: 999,
                color: context.colorScheme.surfaceContainerHigh,
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 90, height: 13),
                    SizedBox(height: BatshSpacing.sm),
                    _SkeletonBox(width: double.infinity, height: 20),
                    SizedBox(height: BatshSpacing.xs),
                    _SkeletonBox(width: 150, height: 20),
                    SizedBox(height: BatshSpacing.md),
                    _SkeletonBox(width: 160, height: 14),
                  ],
                ),
              ),
              const SizedBox(width: BatshSpacing.md),
              _SkeletonBox(width: 96, height: 104),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          const Row(
            children: [
              _SkeletonBox(width: 88, height: 28, radius: 999),
              SizedBox(width: BatshSpacing.sm),
              _SkeletonBox(width: 112, height: 28, radius: 999),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          const _SkeletonBox(width: double.infinity, height: 48, radius: 14),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
    this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color ?? context.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(radius),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(
          duration: BatshMotion.slower,
          curve: BatshMotion.easeInOut,
          color: context.colorScheme.surfaceContainerLowest,
        );
  }
}
