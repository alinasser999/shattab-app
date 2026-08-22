import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/batsh_section_header.dart';
import '../../../../core/widgets/shattab_pattern.dart';
import '../../domain/contractor_listing.dart';
import 'mockup_assets.dart';

/// A separate, clearly disclosed paid-placement shelf.
///
/// Sponsored supply is intentionally not merged into the factual shelves or
/// the organic catalogue sort. A homeowner can discover these profiles, while
/// still understanding that placement was purchased and trust signals remain
/// earned independently.
class SponsoredProfessionalRail extends StatelessWidget {
  const SponsoredProfessionalRail({
    super.key,
    required this.listings,
    required this.onTap,
  });

  final List<ContractorListing> listings;
  final ValueChanged<ContractorListing> onTap;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.sectionH,
              BatshSpacing.gutter,
              BatshSpacing.sectionH,
              BatshSpacing.md,
            ),
            child: BatshSectionHeader(
              title: context.l10n.sponsoredProfessionals,
              padding: EdgeInsets.zero,
              trailing: _PaidPlacementBadge(
                label: context.l10n.paidPlacementLabel,
              ),
            ),
          ),
          SizedBox(
            height: _SponsoredProfessionalCard.height,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.sectionH,
              ),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: listings.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: BatshSpacing.md),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return _SponsoredProfessionalCard(
                  listing: listing,
                  onTap: () => onTap(listing),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaidPlacementBadge extends StatelessWidget {
  const _PaidPlacementBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: BatshSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.tertiaryContainer.withValues(alpha: 0.56),
        borderRadius: BatshRadius.brFull,
        border: Border.all(
          color: context.colorScheme.tertiary.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: BatshIconSize.sm,
            color: context.colorScheme.tertiary,
          ),
          const SizedBox(width: BatshSpacing.xxs),
          Text(
            label,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsoredProfessionalCard extends StatelessWidget {
  const _SponsoredProfessionalCard({
    required this.listing,
    required this.onTap,
  });

  static const double width = 248;
  static const double height = 188;

  final ContractorListing listing;
  final VoidCallback onTap;

  String get _name => listing.businessName.trim().isNotEmpty
      ? listing.businessName.trim()
      : listing.fullName.trim();

  String get _coverFallback {
    final index = listing.id.hashCode.abs() % mockupPortfolioImages.length;
    return mockupPortfolioImages[index];
  }

  @override
  Widget build(BuildContext context) {
    final area = listing.serviceAreas.isEmpty
        ? null
        : listing.serviceAreas.first;
    return SizedBox(
      width: width,
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: '${context.l10n.paidPlacementLabel}: $_name',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brCard,
            border: Border.all(
              color: context.colorScheme.tertiary.withValues(alpha: 0.26),
            ),
            boxShadow: BatshShadows.subtle,
          ),
          child: ClipRRect(
            borderRadius: BatshRadius.brCard,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 94,
                      child: MockupImage(
                        url: listing.coverPhotoUrl ?? _coverFallback,
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ShattabPattern(
                            kind: ShattabPatternKind.terrazzo,
                            color: context.colorScheme.primary,
                            opacity: 0.035,
                            strokeWidth: 0.8,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              BatshSpacing.sm,
                              BatshSpacing.xs,
                              BatshSpacing.md,
                              BatshSpacing.xs,
                            ),
                            child: _CardDetails(
                              name: _name,
                              area: area,
                              listing: listing,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                PositionedDirectional(
                  top: BatshSpacing.sm,
                  end: BatshSpacing.sm,
                  child: _PaidPlacementBadge(
                    label: context.l10n.paidPlacementLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardDetails extends StatelessWidget {
  const _CardDetails({
    required this.name,
    required this.area,
    required this.listing,
  });

  final String name;
  final String? area;
  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AvatarWithInitials(imageUrl: listing.logoUrl, name: name, radius: 20),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: BatshTypography.labelLg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: BatshSpacing.xxs),
              if (listing.verified || listing.hasReviews)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (listing.verified) ...[
                      Icon(
                        Icons.verified_rounded,
                        size: BatshIconSize.sm,
                        color: context.colorScheme.secondary,
                      ),
                      const SizedBox(width: BatshSpacing.xxs),
                    ],
                    if (listing.hasReviews)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: BatshIconSize.xs,
                            color: context.colorScheme.tertiary,
                          ),
                          const SizedBox(width: BatshSpacing.xxs),
                          Text(
                            listing.reviewAvg.toStringAsFixed(1),
                            style: BatshTypography.labelSm.copyWith(
                              color: context.colorScheme.tertiary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              if (area != null)
                Text(
                  area!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: BatshSpacing.sm),
        Icon(
          Icons.arrow_back_rounded,
          size: BatshIconSize.md,
          color: context.colorScheme.primary,
        ),
      ],
    );
  }
}
