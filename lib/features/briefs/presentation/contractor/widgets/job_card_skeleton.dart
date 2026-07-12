import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/batsh_colors.dart';
import '../../../../../core/theme/batsh_motion.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_spacing.dart';

class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.gutter),
      decoration: BoxDecoration(
        color: BatshColors.cardBackground,
        borderRadius: BorderRadius.circular(BatshRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(width: 52, height: 22, radius: 20),
              const Spacer(),
              _shimmerBox(width: 22, height: 22, radius: 0),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          _shimmerBox(width: 140, height: 28),
          const SizedBox(height: BatshSpacing.sm),
          _shimmerBox(width: double.infinity, height: 18),
          const SizedBox(height: BatshSpacing.xs),
          _shimmerBox(width: 180, height: 16),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            children: [
              _shimmerBox(width: 60, height: 20, radius: 6),
              const SizedBox(width: BatshSpacing.sm),
              _shimmerBox(width: 40, height: 20, radius: 6),
              const Spacer(),
              _shimmerBox(width: 40, height: 14),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          Row(
            children: [
              _shimmerBox(width: 80, height: 14),
              const Spacer(),
              _shimmerBox(width: 70, height: 30, radius: 20),
              const SizedBox(width: BatshSpacing.sm),
              _shimmerBox(width: 80, height: 30, radius: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).shimmer(
          duration: BatshMotion.slower,
          curve: BatshMotion.easeInOut,
          color: BatshColors.surfaceContainerLowest,
        );
  }
}
