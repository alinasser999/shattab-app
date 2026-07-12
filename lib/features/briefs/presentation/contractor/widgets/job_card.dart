import 'package:flutter/material.dart';
import '../../../../../core/l10n/strings.dart';
import '../../../../../core/utils/time_format.dart';
import '../../../../../core/theme/batsh_colors.dart';
import '../../../../../core/theme/batsh_motion.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_shadows.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/theme/batsh_typography.dart';
import '../../../../onboarding/domain/onboarding_models.dart';
import '../../../domain/brief.dart';

class JobCardData {
  JobCardData.fromBrief(Brief brief)
      : id = brief.id,
        title = brief.workDescription,
        apartmentLabel =
            OnboardingCatalog.apartmentLabels[brief.apartmentType] ??
                brief.apartmentType.name,
        location = brief.district != null
            ? '${brief.city} · ${brief.district}'
            : brief.city,
        photoCount = brief.photoUrls.length,
        createdAt = brief.createdAt,
        coverPhotoUrl = brief.photoUrls.isNotEmpty ? brief.photoUrls.first : null,
        specialties = brief.targetSpecialties;

  final String id;
  final String title;
  final String apartmentLabel;
  final String location;
  final int photoCount;
  final DateTime createdAt;
  final String? coverPhotoUrl;
  final List<String> specialties;

  bool get hasPhoto => coverPhotoUrl != null;
  String get relativeTime => formatRelativeTime(createdAt);
}

class PremiumJobCard extends StatelessWidget {
  const PremiumJobCard({
    super.key,
    required this.job,
    required this.onTap,
    required this.onQuote,
    this.onBookmark,
    this.isBookmarked = false,
    this.isUrgent = false,
    this.budgetLabel,
    this.clientRating,
    this.alreadyQuoted = false,
  });

  final JobCardData job;
  final VoidCallback onTap;
  final VoidCallback onQuote;
  final VoidCallback? onBookmark;
  final bool isBookmarked;
  final bool isUrgent;
  final String? budgetLabel;
  final double? clientRating;

  /// True when the contractor has already sent a quote on this brief — the
  /// action chip becomes a passive "quote sent" marker (tap still edits).
  final bool alreadyQuoted;

  bool get _isNew =>
      DateTime.now().difference(job.createdAt).inHours < 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BatshColors.cardBackground,
        borderRadius: BorderRadius.circular(BatshRadius.xl),
        boxShadow: BatshShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(BatshSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopRow(
                  isNew: _isNew,
                  isUrgent: isUrgent,
                  isBookmarked: isBookmarked,
                  time: job.relativeTime,
                  onBookmark: onBookmark,
                ),
                const SizedBox(height: BatshSpacing.sm),
                if (budgetLabel != null) ...[
                  Text(
                    budgetLabel!,
                    style: BatshTypography.headlineMd.copyWith(
                      fontWeight: FontWeight.w800,
                      color: BatshColors.primary,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xs),
                ],
                Text(
                  job.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 15, color: BatshColors.onSurfaceVariant),
                    SizedBox(width: BatshSpacing.xxs),
                    Expanded(
                      child: Text(
                        job.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.bodySm.copyWith(
                          color: BatshColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(width: BatshSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: BatshSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: BatshColors.primaryFixed.withValues(alpha: 0.3),
                        borderRadius: BatshRadius.brFull,
                      ),
                      child: Text(
                        job.apartmentLabel,
                        style: BatshTypography.labelSm.copyWith(
                          color: BatshColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BatshSpacing.sm),
                _TrustRow(
                  clientRating: clientRating,
                  applicantCount: null,
                  photoCount: job.photoCount,
                ),
                const SizedBox(height: BatshSpacing.md),
                _BottomRow(
                  time: job.relativeTime,
                  onTap: onTap,
                  onQuote: onQuote,
                  alreadyQuoted: alreadyQuoted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.isNew,
    required this.isUrgent,
    required this.isBookmarked,
    required this.time,
    required this.onBookmark,
  });

  final bool isNew;
  final bool isUrgent;
  final bool isBookmarked;
  final String time;
  final VoidCallback? onBookmark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isNew)
          _Badge(
            label: S.newBadge,
            bgColor: BatshColors.secondaryContainer,
            textColor: BatshColors.onSecondaryContainer,
          ),
        if (isNew && isUrgent) const SizedBox(width: BatshSpacing.xs),
        if (isUrgent)
          _Badge(
            label: S.urgentBadge,
            bgColor: BatshColors.tertiaryContainer,
            textColor: BatshColors.onTertiaryContainer,
          ),
        const Spacer(),
        if (onBookmark != null)
          GestureDetector(
            onTap: onBookmark,
            child: AnimatedSwitcher(
              duration: BatshMotion.fast,
              child: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                key: ValueKey(isBookmarked),
                size: 22,
                color: isBookmarked
                    ? BatshColors.primary
                    : BatshColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BatshRadius.brFull,
      ),
      child: Text(
        label,
        style: BatshTypography.labelSm.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({
    this.clientRating,
    this.applicantCount,
    required this.photoCount,
  });

  final double? clientRating;
  final int? applicantCount;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // "موثوق" client chip removed — no verification process backs it yet.
        if (clientRating != null) ...[
          const SizedBox(width: BatshSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clientRating!.toStringAsFixed(1),
                style: BatshTypography.labelSm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BatshColors.onSurface,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.star, size: 13, color: BatshColors.tertiary),
            ],
          ),
        ],
        if (applicantCount != null) ...[
          const Spacer(),
          Icon(Icons.people_outline,
              size: 14, color: BatshColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '$applicantCount',
            style: BatshTypography.labelSm.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
        ],
        if (photoCount > 0) ...[
          const SizedBox(width: BatshSpacing.sm),
          Icon(Icons.photo_camera_outlined,
              size: 14, color: BatshColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '$photoCount',
            style: BatshTypography.labelSm.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow({
    required this.time,
    required this.onTap,
    required this.onQuote,
    this.alreadyQuoted = false,
  });

  final String time;
  final VoidCallback onTap;
  final VoidCallback onQuote;
  final bool alreadyQuoted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.access_time,
            size: 13, color: BatshColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          time,
          style: BatshTypography.labelSm.copyWith(
            color: BatshColors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        _ActionChip(
          label: S.postDetailTitle,
          onTap: onTap,
        ),
        const SizedBox(width: BatshSpacing.sm),
        if (alreadyQuoted)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  size: 15, color: BatshColors.success),
              const SizedBox(width: 4),
              Text(
                S.quoteSentShort,
                style: BatshTypography.labelSm.copyWith(
                  color: BatshColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          _ActionChip(
            label: S.sendQuoteButton,
            onTap: onQuote,
            isPrimary: true,
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? BatshColors.primary : Colors.transparent,
      borderRadius: BatshRadius.brFull,
      child: InkWell(
        borderRadius: BatshRadius.brFull,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BatshRadius.brFull,
            border: isPrimary
                ? null
                : Border.all(color: BatshColors.outlineVariant),
          ),
          child: Text(
            label,
            style: BatshTypography.labelSm.copyWith(
              color: isPrimary ? BatshColors.onPrimary : BatshColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
