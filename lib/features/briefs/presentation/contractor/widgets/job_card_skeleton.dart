import 'package:flutter/material.dart';

import '../../../../../core/theme/batsh_colors.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/widgets/batsh_shimmer.dart';

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
              BatshShimmerBox(width: 52, height: 22, borderRadius: BorderRadius.circular(20)),
              const Spacer(),
              BatshShimmerBox(width: 22, height: 22, borderRadius: BorderRadius.zero),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          const BatshShimmerBox(width: 140, height: 28),
          const SizedBox(height: BatshSpacing.sm),
          const BatshShimmerBox(width: double.infinity, height: 18),
          const SizedBox(height: BatshSpacing.xs),
          const BatshShimmerBox(width: 180, height: 16),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            children: [
              BatshShimmerBox(width: 60, height: 20, borderRadius: BorderRadius.circular(6)),
              const SizedBox(width: BatshSpacing.sm),
              BatshShimmerBox(width: 40, height: 20, borderRadius: BorderRadius.circular(6)),
              const Spacer(),
              const BatshShimmerBox(width: 40, height: 14),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          Row(
            children: [
              const BatshShimmerBox(width: 80, height: 14),
              const Spacer(),
              BatshShimmerBox(width: 70, height: 30, borderRadius: BorderRadius.circular(20)),
              const SizedBox(width: BatshSpacing.sm),
              BatshShimmerBox(width: 80, height: 30, borderRadius: BorderRadius.circular(20)),
            ],
          ),
        ],
      ),
    );
  }
}
