import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../domain/review.dart';
import 'providers/reviews_providers.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_sheet.dart';

/// Opens the list of reviews left for a contractor.
///
/// The rating average was previously the only review surface anywhere in the
/// app: `reviewsForContractorProvider` existed but nothing rendered it, so a
/// homeowner saw "4.6" with no way to find out why. A number you cannot audit
/// is a weaker trust signal than three sentences you can read.
Future<void> showReviewsSheet(BuildContext context, String contractorId) {
  return BatshSheet.show<void>(
    context,
    contentPadding: EdgeInsets.zero,
    builder: (_) => _ReviewsSheet(contractorId: contractorId),
  );
}

class _ReviewsSheet extends ConsumerWidget {
  const _ReviewsSheet({required this.contractorId});

  final String contractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reviewsForContractorProvider(contractorId));

    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.reviewsSheetTitle, style: BatshTypography.titleLg),
          const SizedBox(height: BatshSpacing.md),
          Expanded(
            child: async.when(
              loading: () => const BatshListSkeleton(count: 4),
              error: (e, _) => BatshError(
                message: ErrorMapper.map(e),
                onRetry: () =>
                    ref.invalidate(reviewsForContractorProvider(contractorId)),
              ),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return BatshEmptyState(
                    title: S.noReviewsYet,
                    message: S.noReviewsYetSub,
                    icon: Icons.rate_review_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    BatshSpacing.gutter,
                    0,
                    BatshSpacing.gutter,
                    BatshSpacing.xl,
                  ),
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: BatshSpacing.lg),
                  itemBuilder: (_, i) => _ReviewRow(review: reviews[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One review. `Review` carries no reviewer name — there is no join for it and
/// homeowner names are not public — so the row leads with the rating and lets
/// the comment speak.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 5; i++)
              Icon(
                i < review.rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: BatshIconSize.sm,
                color: i < review.rating
                    ? BatshColors.tertiary
                    : BatshColors.outlineVariant,
              ),
            const Spacer(),
            Text(
              formatRelativeTime(review.createdAt),
              style: BatshTypography.labelSm.copyWith(
                color: BatshColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
          const SizedBox(height: BatshSpacing.sm),
          Text(review.comment!.trim(), style: BatshTypography.bodyMd),
        ],
      ],
    );
  }
}
