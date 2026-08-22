import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import 'package:intl/intl.dart' as intl;

import '../../features/briefs/domain/brief.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../utils/image_url.dart';
import 'batsh_card.dart';
import '../theme/batsh_icon_size.dart';
import 'batsh_badge.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BriefCard extends StatelessWidget {
  const BriefCard({super.key, required this.brief, required this.onTap});

  final Brief brief;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = brief.photoUrls.isNotEmpty;
    final formatted = intl.DateFormat.yMMMd('ar').format(brief.createdAt);

    return BatshCard(
      onTap: onTap,
      padding: const EdgeInsets.all(BatshSpacing.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumb(url: hasPhoto ? brief.photoUrls.first : null),
          const SizedBox(width: BatshSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(status: brief.status, isPost: brief.isPost),
                    const Spacer(),
                    Text(
                      formatted,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  brief.workDescription,
                  style: BatshTypography.bodyMd,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: BatshSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: BatshIconSize.sm,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      brief.city,
                      style: BatshTypography.labelMd.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (brief.district != null) ...[
                      Text(
                        ' · ',
                        style: BatshTypography.labelMd.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          brief.district!,
                          style: BatshTypography.labelMd.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: BatshSpacing.xs),
                _NextStep(brief: brief),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (brief.stage) {
      BriefStage.open => (
        context.l10n.briefNextStepQuotes,
        Icons.request_quote_outlined,
        context.colorScheme.primary,
      ),
      BriefStage.hired => (
        context.l10n.briefNextStepFollowWork,
        Icons.handyman_outlined,
        context.colorScheme.primary,
      ),
      BriefStage.completionRequested => (
        context.l10n.briefNextStepConfirmWork,
        Icons.task_alt_outlined,
        context.colorScheme.tertiary,
      ),
      BriefStage.completed => (
        context.l10n.briefNextStepReview,
        Icons.star_outline_rounded,
        context.colorScheme.secondary,
      ),
    };
    final cancelled = brief.status == BriefStatus.cancelled;
    return Semantics(
      label: cancelled ? context.l10n.statusCancelled : label,
      child: Row(
        children: [
          Icon(
            cancelled ? Icons.block_outlined : icon,
            size: BatshIconSize.inline,
            color: cancelled ? context.colorScheme.onSurfaceVariant : color,
          ),
          const SizedBox(width: BatshSpacing.xxs),
          Expanded(
            child: Text(
              cancelled ? context.l10n.statusCancelled : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.labelSm.copyWith(
                color: cancelled ? context.colorScheme.onSurfaceVariant : color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.arrow_back_ios_rounded
                : Icons.arrow_forward_ios_rounded,
            size: BatshIconSize.xs,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BatshRadius.brMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: sizedImageUrl(url!, width: 320),
              fit: BoxFit.cover,
              memCacheWidth: 320,
            )
          : Center(
              child: Icon(
                Icons.image_outlined,
                color: context.colorScheme.onSurfaceVariant,
                size: BatshIconSize.lg,
              ),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isPost});
  final BriefStatus status;
  final bool isPost;

  @override
  Widget build(BuildContext context) {
    // Cancelled is over, not wrong, so it stays neutral: a list of cancelled
    // briefs should not read as a wall of errors. An open post is available
    // work; an open direct request was addressed to this contractor by name.
    final (label, tone) = switch (status) {
      BriefStatus.cancelled => (
        context.l10n.statusCancelled,
        BatshBadgeTone.neutral,
      ),
      BriefStatus.open =>
        isPost
            ? (context.l10n.statusOpen, BatshBadgeTone.success)
            : (context.l10n.statusDirect, BatshBadgeTone.brand),
    };
    return BatshBadge(label: label, tone: tone, compact: true);
  }
}
