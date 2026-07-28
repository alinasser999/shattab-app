import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

import '../../features/discovery/domain/contractor_listing.dart';
import '../../features/onboarding/domain/onboarding_models.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../utils/image_url.dart';
import 'batsh_initial_plate.dart';
import 'batsh_pressable.dart';
import 'tier_badge.dart';
import '../theme/batsh_icon_size.dart';
import 'batsh_badge.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Discover-feed card, cut to six things.
///
/// It used to carry fourteen: cover, scrim, rating badge, tier badge, save,
/// a floating logo, name and headline composited on the photo, two stat
/// chips, three specialty chips, and a location line. Density was doing the
/// work restraint should do, and the photo — the only part a homeowner
/// actually judges a contractor on — was capped at 208px so the chips could
/// have the rest.
///
/// Now: photo, one identity badge, name, a stat line set in type, up to two
/// specialties, location. Save stays, because saving from a list is a real
/// affordance and every comparable marketplace has one.
///
/// The name moved off the photo. Overlaid on a cover it had one line over a
/// scrim and truncated on any business with a long Arabic name; below the
/// photo it gets two lines and the whole string.
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
    // Two, not three. A third chip pushed the row to wrap on the narrow
    // phones that are most of this market, and a wrapped chip row reads as
    // overflow rather than as a list.
    final topSpecialties = listing.specialties.take(2).toList();
    final overflowCount = listing.specialties.length - topSpecialties.length;
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
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brLg,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cover(
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
                    // Two lines and no ellipsis. This is the contractor's
                    // identity; it is the one string on the card that must
                    // never arrive cut in half.
                    Text(name, style: BatshTypography.titleLg, maxLines: 2),
                    const SizedBox(height: BatshSpacing.xs),
                    _StatLine(listing: listing),
                    if (topSpecialties.isNotEmpty) ...[
                      const SizedBox(height: BatshSpacing.md),
                      Row(
                        children: [
                          for (final s in topSpecialties) ...[
                            Flexible(
                              child: BatshBadge(
                                label:
                                    OnboardingCatalog.specialtiesCatalog[s] ??
                                    s,
                                tone: BatshBadgeTone.brand,
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: BatshSpacing.xs),
                          ],
                          if (overflowCount > 0)
                            Text(
                              '+$overflowCount',
                              style: BatshTypography.labelMd.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (firstAreas.isNotEmpty) ...[
                      const SizedBox(height: BatshSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: BatshIconSize.sm,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              firstAreas.join(' · '),
                              style: BatshTypography.bodySm.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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

/// Cover photo at 4:3, one identity badge, and save.
///
/// Nothing is composited onto the photo any more except the two controls that
/// have to float. Text over a photo needs a scrim, a scrim greys the
/// photograph, and the photograph is the product in a renovation marketplace.
class _Cover extends StatelessWidget {
  const _Cover({
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
    return AspectRatio(
      // 4:3 instead of a fixed 208px. The photo now takes roughly 60% of the
      // card rather than a third of it, which is the ratio every marketplace
      // that sells on imagery settles on.
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (listing.coverPhotoUrl != null)
            CachedNetworkImage(
              imageUrl: sizedImageUrl(listing.coverPhotoUrl!, width: 800),
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder: (_, _) =>
                  ColoredBox(color: context.colorScheme.surfaceContainer),
              errorWidget: (_, _, _) => BatshInitialPlate(name: name),
            )
          else
            BatshInitialPlate(name: name),
          // One identity badge, never two. A silver-tier contractor with 56
          // projects was rendering "new" beside their level, because the
          // rating pill falls back to "new" whenever reviewCount is 0 — an
          // unreviewed veteran is common and the card called them a beginner.
          // Earned level wins; rating stands in only when there is no level
          // to show.
          PositionedDirectional(
            top: BatshSpacing.sm,
            start: BatshSpacing.sm,
            child: listing.tier.isPublic
                ? TierBadge(tier: listing.tier)
                : BatshBadge(
                    label:
                        listing.rating?.toStringAsFixed(1) ??
                        context.l10n.newBadge,
                    icon: listing.reviewCount == 0
                        ? Icons.auto_awesome
                        : Icons.star,
                    emphasis: BatshBadgeEmphasis.onImage,
                    compact: true,
                    semanticLabel: listing.rating == null
                        ? context.l10n.newBadge
                        : '${context.l10n.ratingLabel} ${listing.rating!.toStringAsFixed(1)}',
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
                  tooltip: isSaved
                      ? context.l10n.unsaveTooltip
                      : context.l10n.saveTooltip,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: BatshIconSize.md,
                    color: isSaved
                        ? context.colorScheme.primary
                        : context.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onToggleSave,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Projects, experience and rating on one line, set in type.
///
/// These were three pills. Chips are for filters and taxonomy — things you
/// tap. Using them as a general container for any short string is what makes
/// a card look like component soup, and it gave three unrelated facts three
/// competing borders. Airbnb sets the same information as `4.92 ★ · 128
/// reviews` and it reads as a sentence, which is what it is.
class _StatLine extends StatelessWidget {
  const _StatLine({required this.listing});
  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      '${listing.projectsCompleted} ${context.l10n.singleProject}',
      if (listing.yearsExperience != null)
        '${listing.yearsExperience} ${context.l10n.year}',
      // Only when it was actually earned. The rating badge on the cover
      // already carries the cold-start case; repeating "new" here would say
      // the same thing twice.
      if (listing.rating != null && listing.reviewCount > 0)
        '${listing.rating!.toStringAsFixed(1)} ★',
    ];

    return Text(
      parts.join('  ·  '),
      style: BatshTypography.labelLg.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
