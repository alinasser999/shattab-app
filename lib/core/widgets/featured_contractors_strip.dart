import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../features/discovery/domain/contractor_listing.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

/// Horizontal showcase strip — the top "featured" contractors with a richer
/// visual treatment than the standard cards below them.
class FeaturedContractorsStrip extends StatelessWidget {
  const FeaturedContractorsStrip({
    super.key,
    required this.contractors,
    required this.onTap,
  });

  final List<ContractorListing> contractors;
  final void Function(ContractorListing) onTap;

  @override
  Widget build(BuildContext context) {
    if (contractors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.marginMobile),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: BatshColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Text('مقاولين مميّزين',
                  style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.marginMobile,
                vertical: BatshSpacing.xs),
            itemCount: contractors.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: BatshSpacing.gutter),
            itemBuilder: (context, i) =>
                _FeaturedTile(listing: contractors[i], onTap: onTap),
          ),
        ),
      ],
    );
  }
}

class _FeaturedTile extends StatelessWidget {
  const _FeaturedTile({required this.listing, required this.onTap});
  final ContractorListing listing;
  final void Function(ContractorListing) onTap;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.isNotEmpty
        ? listing.businessName
        : listing.fullName;
    return SizedBox(
      width: 240,
      child: Material(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTap(listing),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brLg,
              boxShadow: BatshShadows.raised,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (listing.coverPhotoUrl != null)
                  CachedNetworkImage(
                    imageUrl: listing.coverPhotoUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BatshColors.primaryContainer,
                          BatshColors.tertiaryContainer,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: BatshSpacing.sm,
                  right: BatshSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: BatshSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: BatshColors.tertiaryFixed,
                      borderRadius: BatshRadius.brFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            size: 12, color: BatshColors.tertiary),
                        const SizedBox(width: 4),
                        Text(listing.computedRating.toStringAsFixed(1),
                            style: BatshTypography.labelSm.copyWith(
                                color: BatshColors.onTertiaryContainer,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: BatshSpacing.gutter,
                  right: BatshSpacing.gutter,
                  bottom: BatshSpacing.gutter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.titleLg.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      if (listing.headline != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          listing.headline!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.labelMd.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
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
