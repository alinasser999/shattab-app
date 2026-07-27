import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../features/discovery/domain/contractor_listing.dart';
import '../l10n/strings.dart';
import '../../features/onboarding/domain/onboarding_models.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../utils/image_url.dart';
import 'batsh_pressable.dart';
import 'batsh_shimmer.dart';
import 'tier_badge.dart';
import '../theme/batsh_icon_size.dart';

/// Large editorial-style card for the discover feed. Premium magazine layout:
/// a tall cover with the logo, name, headline and rating composited directly
/// onto the photo behind a legibility scrim, then a compact stats + chips strip
/// underneath. Behance-meets-Airbnb.
class ContractorCard extends StatelessWidget {
  const ContractorCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.isSaved = false,
    this.onToggleSave,
  });

  final ContractorListing listing;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback? onToggleSave;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.isNotEmpty
        ? listing.businessName
        : listing.fullName;
    final topSpecialties = listing.specialties.take(3).toList();
    final firstAreas = listing.serviceAreas.take(2).toList();

    return DecoratedBox(
      // Shadow lives on an outer box: a clipped Material clips its child's
      // shadow away, so it must sit outside the clip to render at all.
      decoration: BoxDecoration(
        borderRadius: BatshRadius.brLg,
        boxShadow: BatshShadows.soft,
      ),
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: name,
        child: Material(
          color: BatshColors.surfaceContainerLowest,
          borderRadius: BatshRadius.brLg,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EditorialCover(
                listing: listing,
                name: name,
                isSaved: isSaved,
                onToggleSave: onToggleSave,
              ),
              Padding(
                padding: const EdgeInsets.all(BatshSpacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MicroStats(listing: listing),
                    const SizedBox(height: BatshSpacing.md),
                    Wrap(
                      spacing: BatshSpacing.xs,
                      runSpacing: BatshSpacing.xs,
                      children: [
                        for (final s in topSpecialties)
                          _MiniChip(
                              label:
                                  OnboardingCatalog.specialtiesCatalog[s] ?? s),
                      ],
                    ),
                    if (firstAreas.isNotEmpty) ...[
                      const SizedBox(height: BatshSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: BatshIconSize.sm, color: BatshColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(firstAreas.join(' · '),
                                style: BatshTypography.labelMd.copyWith(
                                    color: BatshColors.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
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

/// Tall cover photo with logo + name + headline + rating composited on top of a
/// bottom-weighted scrim, plus a floating save control.
class _EditorialCover extends StatelessWidget {
  const _EditorialCover({
    required this.listing,
    required this.name,
    required this.isSaved,
    required this.onToggleSave,
  });

  final ContractorListing listing;
  final String name;
  final bool isSaved;
  final VoidCallback? onToggleSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 208,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          if (listing.coverPhotoUrl != null)
            CachedNetworkImage(
              imageUrl: sizedImageUrl(listing.coverPhotoUrl!, width: 800),
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder: (_, _) =>
                  const ColoredBox(color: BatshColors.surfaceContainer),
              errorWidget: (_, _, _) => const _CoverFallback(),
            )
          else
            const _CoverFallback(),
          // Legibility scrim: clear at top, deep at the foot so the composited
          // name/logo stay readable over any photo.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x33000000),
                    Color(0xD9000000),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Rating / new badge, top-start, with the earned level under it.
          // The level is not tappable here — the card itself is the tap
          // target, and the explainer is one tap further in, on the profile.
          PositionedDirectional(
            top: BatshSpacing.sm,
            start: BatshSpacing.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _RatingBadge(listing: listing),
                if (listing.tier.isPublic) ...[
                  const SizedBox(height: BatshSpacing.xxs),
                  TierBadge(tier: listing.tier),
                ],
              ],
            ),
          ),
          // Save control, top-end.
          if (onToggleSave != null)
            PositionedDirectional(
              top: BatshSpacing.sm,
              end: BatshSpacing.sm,
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: isSaved ? S.unsaveTooltip : S.saveTooltip,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: BatshIconSize.md,
                    color: isSaved
                        ? BatshColors.primary
                        : BatshColors.onSurfaceVariant,
                  ),
                  onPressed: onToggleSave,
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          // Logo + name + headline, composited at the foot.
          PositionedDirectional(
            start: BatshSpacing.gutter,
            end: BatshSpacing.gutter,
            bottom: BatshSpacing.gutter,
            child: Row(
              children: [
                _LogoAvatar(logoUrl: listing.logoUrl),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: BatshTypography.titleLg.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (listing.headline != null &&
                          listing.headline!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          listing.headline!,
                          style: BatshTypography.labelMd.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({this.logoUrl});
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: BatshShadows.soft,
      ),
      child: ClipOval(
        child: Container(
          color: BatshColors.surfaceContainer,
          child: logoUrl != null
              ? CachedNetworkImage(
                  imageUrl: sizedImageUrl(logoUrl!, width: 160),
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const ColoredBox(color: BatshColors.surfaceContainer),
                )
              : const Icon(Icons.engineering_outlined,
                  color: BatshColors.primary, size: BatshIconSize.lg),
        ),
      ),
    );
  }
}

/// Rating pill (star + score) or a neutral "new" badge for cold-start
/// contractors — icon + text, never colour alone.
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.listing});
  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final isNew = listing.reviewCount == 0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BatshRadius.brFull,
        boxShadow: BatshShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNew ? Icons.auto_awesome : Icons.star,
            size: BatshIconSize.sm,
            color: isNew ? BatshColors.secondary : BatshColors.tertiary,
          ),
          const SizedBox(width: 4),
          Text(
            listing.rating?.toStringAsFixed(1) ?? S.newBadge,
            style: BatshTypography.labelSm.copyWith(
              color: BatshColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();
  @override
  Widget build(BuildContext context) {
    return const BatshGradientFallback();
  }
}

class _MicroStats extends StatelessWidget {
  const _MicroStats({required this.listing});
  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
            icon: Icons.home_work_outlined,
            iconColor: BatshColors.primary,
            label: '${listing.projectsCompleted} ${S.singleProject}'),
        if (listing.yearsExperience != null) ...[
          const SizedBox(width: BatshSpacing.sm),
          _StatChip(
              icon: Icons.workspace_premium_outlined,
              iconColor: BatshColors.secondary,
              label: '${listing.yearsExperience} ${S.year}'),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLow,
        borderRadius: BatshRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: BatshIconSize.xs, color: iconColor),
          const SizedBox(width: 4),
          Text(label,
              style: BatshTypography.labelSm
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: BatshColors.primaryFixed,
        borderRadius: BatshRadius.brFull,
      ),
      child: Text(label,
          style: BatshTypography.labelSm.copyWith(
              color: BatshColors.onPrimaryFixed,
              fontWeight: FontWeight.w600)),
    );
  }
}
