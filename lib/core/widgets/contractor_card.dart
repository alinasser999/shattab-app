import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../features/discovery/domain/contractor_listing.dart';
import '../../features/onboarding/domain/onboarding_models.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

/// Large editorial-style card for the discover feed. Cover image + avatar +
/// name + headline + stats row + chips. LinkedIn-meets-Behance vibe.
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

    return Material(
      color: BatshColors.surfaceContainerLowest,
      borderRadius: BatshRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BatshRadius.brLg,
            boxShadow: BatshShadows.soft,
            border: Border.all(color: BatshColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CoverWithAvatar(
                  listing: listing,
                  isSaved: isSaved,
                  onToggleSave: onToggleSave),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BatshSpacing.gutter,
                  BatshSpacing.lg,
                  BatshSpacing.gutter,
                  BatshSpacing.gutter,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: BatshTypography.titleLg
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (listing.headline != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        listing.headline!,
                        style: BatshTypography.bodyMd.copyWith(
                            color: BatshColors.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: BatshSpacing.md),
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
                              size: 14,
                              color: BatshColors.onSurfaceVariant),
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

class _CoverWithAvatar extends StatelessWidget {
  const _CoverWithAvatar({
    required this.listing,
    required this.isSaved,
    required this.onToggleSave,
  });

  final ContractorListing listing;
  final bool isSaved;
  final VoidCallback? onToggleSave;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover hero
        SizedBox(
          height: 130,
          width: double.infinity,
          child: listing.coverPhotoUrl != null
              ? CachedNetworkImage(
                  imageUrl: listing.coverPhotoUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const _CoverFallback(),
                )
              : const _CoverFallback(),
        ),
        // Gradient overlay
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    BatshColors.primary.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Save heart top-right
        if (onToggleSave != null)
          Positioned(
            top: BatshSpacing.sm,
            right: BatshSpacing.sm,
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              child: IconButton(
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: isSaved
                      ? BatshColors.primary
                      : BatshColors.onSurfaceVariant,
                ),
                onPressed: onToggleSave,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        // Avatar peeking below
        Positioned(
          left: BatshSpacing.gutter,
          bottom: -28,
          child: Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: BatshColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Container(
                color: BatshColors.surfaceContainer,
                child: listing.logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: listing.logoUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.engineering_outlined,
                        color: BatshColors.primary, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            BatshColors.primaryContainer,
            BatshColors.tertiaryContainer,
          ],
        ),
      ),
    );
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
            icon: Icons.star,
            iconColor: BatshColors.tertiary,
            label: listing.computedRating.toStringAsFixed(1)),
        const SizedBox(width: BatshSpacing.sm),
        _StatChip(
            icon: Icons.home_work_outlined,
            iconColor: BatshColors.primary,
            label: '${listing.projectsCompleted} مشروع'),
        if (listing.yearsExperience != null) ...[
          const SizedBox(width: BatshSpacing.sm),
          _StatChip(
              icon: Icons.workspace_premium_outlined,
              iconColor: BatshColors.secondary,
              label: '${listing.yearsExperience} سنة'),
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
          Icon(icon, size: 12, color: iconColor),
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
