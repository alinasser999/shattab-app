import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../features/briefs/domain/brief.dart';
import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../utils/image_url.dart';
import 'batsh_card.dart';

class BriefCard extends StatelessWidget {
  const BriefCard({
    super.key,
    required this.brief,
    required this.onTap,
  });

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
                    Text(formatted,
                        style: BatshTypography.labelSm.copyWith(
                            color: BatshColors.onSurfaceVariant)),
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
                    const Icon(Icons.place_outlined,
                        size: 14, color: BatshColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(brief.city,
                        style: BatshTypography.labelMd.copyWith(
                            color: BatshColors.onSurfaceVariant)),
                    if (brief.district != null) ...[
                      Text(' · ',
                          style: BatshTypography.labelMd.copyWith(
                              color: BatshColors.onSurfaceVariant)),
                      Expanded(
                        child: Text(brief.district!,
                            style: BatshTypography.labelMd.copyWith(
                                color: BatshColors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
        color: BatshColors.surfaceContainer,
        borderRadius: BatshRadius.brMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: sizedImageUrl(url!, width: 320),
              fit: BoxFit.cover,
              memCacheWidth: 320,
            )
          : const Center(
              child: Icon(Icons.image_outlined,
                  color: BatshColors.onSurfaceVariant, size: 28)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isPost});
  final BriefStatus status;
  final bool isPost;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      BriefStatus.cancelled => (
        S.statusCancelled,
        BatshColors.onSurfaceVariant,
        BatshColors.surfaceContainerHigh
      ),
      BriefStatus.open => isPost
          ? (S.statusOpen, BatshColors.tertiary, BatshColors.tertiaryFixed)
          : (S.statusDirect, BatshColors.primary, BatshColors.primaryFixed),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BatshRadius.brFull,
      ),
      child: Text(label,
          style: BatshTypography.labelSm
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
