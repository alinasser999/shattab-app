import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/l10n/strings.dart';
import '../../../../../core/utils/time_format.dart';
import '../../../../../core/theme/batsh_colors.dart';
import '../../../../../core/theme/batsh_motion.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_shadows.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/theme/batsh_typography.dart';
import '../../../../../core/utils/image_url.dart';
import '../../../../onboarding/domain/onboarding_models.dart';
import '../../../domain/brief.dart';
import '../../../../../core/theme/batsh_icon_size.dart';

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

/// Image-forward job card: hero photo with floating status badges, then
/// title, meta, and a primary/secondary CTA pair. Public API unchanged so
/// the opportunities screen wiring stays intact.
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
  /// primary CTA becomes a passive "quote sent" marker (tap still edits).
  final bool alreadyQuoted;

  bool get _isNew => DateTime.now().difference(job.createdAt).inHours < 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BatshColors.cardBackground,
        borderRadius: BatshRadius.brCard,
        boxShadow: BatshShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(
                job: job,
                isNew: _isNew,
                isUrgent: isUrgent,
                isBookmarked: isBookmarked,
                onBookmark: onBookmark,
                budgetLabel: budgetLabel,
              ),
              Padding(
                padding: const EdgeInsets.all(BatshSpacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.titleMd.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.sm),
                    _MetaRow(job: job, clientRating: clientRating),
                    const SizedBox(height: BatshSpacing.md),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: BatshColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: BatshSpacing.md),
                    _CtaRow(
                      onTap: onTap,
                      onQuote: onQuote,
                      alreadyQuoted: alreadyQuoted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero image ──────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({
    required this.job,
    required this.isNew,
    required this.isUrgent,
    required this.isBookmarked,
    required this.onBookmark,
    required this.budgetLabel,
  });

  final JobCardData job;
  final bool isNew;
  final bool isUrgent;
  final bool isBookmarked;
  final VoidCallback? onBookmark;
  final String? budgetLabel;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (job.hasPhoto)
            CachedNetworkImage(
              imageUrl: sizedImageUrl(job.coverPhotoUrl!, width: 800),
              fit: BoxFit.cover,
              // Cap the decode size. Uploads are ~1600px wide; decoding that
              // full-res for a card this size costs several times the memory it
              // needs, and this list is the app's longest scroll on the
              // cheapest Android hardware in the market.
              memCacheWidth: 1000,
              placeholder: (_, _) => const _HeroPlaceholder(loading: true),
              errorWidget: (_, _, _) => const _HeroPlaceholder(),
            )
          else
            const _HeroPlaceholder(),
          // Bottom scrim so overlaid chips stay legible on bright photos.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Color(0x33000000), Color(0x00000000)],
              ),
            ),
          ),
          // Status badges — top-start (right in RTL).
          PositionedDirectional(
            top: BatshSpacing.sm,
            start: BatshSpacing.sm,
            child: Row(
              children: [
                if (isNew)
                  const _Badge(
                    resolveNew: true,
                    bgColor: BatshColors.secondary,
                    textColor: Colors.white,
                  ),
                if (isNew && isUrgent) const SizedBox(width: BatshSpacing.xs),
                if (isUrgent)
                  const _Badge(
                    resolveUrgent: true,
                    bgColor: BatshColors.tertiary,
                    textColor: Colors.white,
                  ),
              ],
            ),
          ),
          // Bookmark — top-end (left in RTL).
          if (onBookmark != null)
            PositionedDirectional(
              top: BatshSpacing.xs,
              end: BatshSpacing.xs,
              child: _BookmarkButton(
                isBookmarked: isBookmarked,
                onTap: onBookmark!,
              ),
            ),
          // Budget — bottom-start pill when present.
          if (budgetLabel != null)
            PositionedDirectional(
              bottom: BatshSpacing.sm,
              start: BatshSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: BatshSpacing.sm, vertical: 5),
                decoration: BoxDecoration(
                  color: BatshColors.primary,
                  borderRadius: BatshRadius.brFull,
                ),
                child: Text(
                  budgetLabel!,
                  style: BatshTypography.labelMd.copyWith(
                    color: BatshColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({this.loading = false});
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            BatshColors.primaryFixed.withValues(alpha: 0.55),
            BatshColors.surfaceContainer,
          ],
        ),
      ),
      child: loading
          ? const SizedBox.shrink()
          : Center(
              child: Icon(
                Icons.home_work_outlined,
                size: BatshIconSize.xl,
                color: BatshColors.primary.withValues(alpha: 0.35),
              ),
            ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({required this.isBookmarked, required this.onTap});
  final bool isBookmarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: AnimatedSwitcher(
            duration: BatshMotion.fast,
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              key: ValueKey(isBookmarked),
              size: BatshIconSize.md,
              color: isBookmarked
                  ? BatshColors.primary
                  : BatshColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.bgColor,
    required this.textColor,
    this.resolveNew = false,
    this.resolveUrgent = false,
  });

  final Color bgColor;
  final Color textColor;
  final bool resolveNew;
  final bool resolveUrgent;

  @override
  Widget build(BuildContext context) {
    final text = resolveNew ? S.newBadge : (resolveUrgent ? S.urgentBadge : '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BatshRadius.brFull,
      ),
      child: Text(
        text,
        style: BatshTypography.labelSm.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Meta row ────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.job, this.clientRating});
  final JobCardData job;
  final double? clientRating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.place_outlined,
            size: BatshIconSize.sm, color: BatshColors.onSurfaceVariant),
        const SizedBox(width: BatshSpacing.xxs),
        Flexible(
          child: Text(
            job.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.bodySm.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: BatshSpacing.sm),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: BatshSpacing.sm, vertical: 3),
          decoration: BoxDecoration(
            color: BatshColors.primaryFixed.withValues(alpha: 0.3),
            borderRadius: BatshRadius.brFull,
          ),
          child: Text(
            job.apartmentLabel,
            style: BatshTypography.labelSm.copyWith(
              color: BatshColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        if (clientRating != null) ...[
          Icon(Icons.star, size: BatshIconSize.sm, color: BatshColors.tertiary),
          const SizedBox(width: BatshSpacing.xxs),
          Text(
            clientRating!.toStringAsFixed(1),
            style: BatshTypography.labelSm.copyWith(
              color: BatshColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ] else ...[
          Icon(Icons.access_time,
              size: BatshIconSize.sm, color: BatshColors.onSurfaceVariant),
          const SizedBox(width: BatshSpacing.xxs),
          Text(
            job.relativeTime,
            style: BatshTypography.labelSm.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── CTA row ─────────────────────────────────────────────────────────────────

class _CtaRow extends StatelessWidget {
  const _CtaRow({
    required this.onTap,
    required this.onQuote,
    required this.alreadyQuoted,
  });

  final VoidCallback onTap;
  final VoidCallback onQuote;
  final bool alreadyQuoted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CtaButton(
            label: S.postDetailTitle,
            onTap: onTap,
            filled: false,
          ),
        ),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(
          child: alreadyQuoted
              ? _CtaButton(
                  label: S.quoteSentShort,
                  icon: Icons.check_circle,
                  onTap: onQuote,
                  filled: true,
                  bgColor: BatshColors.successContainer,
                  fgColor: BatshColors.onSecondaryContainer,
                )
              : _CtaButton(
                  label: S.sendQuoteButton,
                  onTap: onQuote,
                  filled: true,
                ),
        ),
      ],
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.onTap,
    required this.filled,
    this.icon,
    this.bgColor,
    this.fgColor,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;
  final Color? bgColor;
  final Color? fgColor;

  @override
  Widget build(BuildContext context) {
    final fg = fgColor ??
        (filled ? BatshColors.onPrimary : BatshColors.onSurface);
    return Material(
      color: filled ? (bgColor ?? BatshColors.primary) : Colors.transparent,
      borderRadius: BatshRadius.brDefault,
      child: InkWell(
        borderRadius: BatshRadius.brDefault,
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BatshRadius.brDefault,
            border: filled
                ? null
                : Border.all(
                    color: BatshColors.outline.withValues(alpha: 0.5),
                    width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: BatshIconSize.sm, color: fg),
                const SizedBox(width: BatshSpacing.xs),
              ],
              Text(
                label,
                style: BatshTypography.labelLg.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
