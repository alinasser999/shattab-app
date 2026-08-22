import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:batsh/core/theme/theme_extension.dart';

import '../../features/discovery/domain/contractor_listing.dart';
import '../../features/discovery/domain/trust_signals.dart';
import '../l10n/catalog_labels.dart';
import '../l10n/l10n_extension.dart';
import '../theme/batsh_icon_size.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../utils/image_url.dart';
import 'avatar_with_initials.dart';
import 'batsh_initial_plate.dart';
import 'batsh_pressable.dart';
import 'shattab_pattern.dart';
import 'trust_strip.dart';

/// A professional card for the homeowner catalogue.
///
/// The photo, identity, and proof are kept in one stable split. The terracotta
/// strip is a small brand signature, not a second control surface, and the
/// only actions are save and open profile.
class ContractorCard extends StatelessWidget {
  const ContractorCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.isSaved = false,
    this.onToggleSave,
    this.discoveryReason,
  });

  final ContractorListing listing;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback? onToggleSave;
  final String? discoveryReason;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.isNotEmpty
        ? listing.businessName
        : listing.fullName;
    final specialty = listing.specialties.isNotEmpty
        ? localizedSpecialtyLabel(context, listing.specialties.first)
        : context.l10n.providerKindContractor;
    final area = listing.serviceAreas.isNotEmpty
        ? listing.serviceAreas.first
        : context.l10n.notSpecified;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brCard,
        boxShadow: BatshShadows.soft,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.62),
        ),
      ),
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: '$name. ${context.l10n.homeViewProfile}',
        child: SizedBox(
          height: 304,
          child: ClipRRect(
            borderRadius: BatshRadius.brCard,
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                Expanded(
                  flex: 42,
                  child: _CatalogueCover(listing: listing, name: name),
                ),
                SizedBox(
                  width: 22,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: context.colorScheme.primary),
                      IgnorePointer(
                        child: ExcludeSemantics(
                          child: ShattabPattern(
                            kind: ShattabPatternKind.terrazzo,
                            color: Colors.white,
                            opacity: 0.18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 58,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: _CatalogueDetails(
                      listing: listing,
                      name: name,
                      specialty: specialty,
                      area: area,
                      isSaved: isSaved,
                      onToggleSave: onToggleSave,
                      discoveryReason: discoveryReason,
                      onTap: onTap,
                    ),
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

class _CatalogueCover extends StatelessWidget {
  const _CatalogueCover({required this.listing, required this.name});

  final ContractorListing listing;
  final String name;

  @override
  Widget build(BuildContext context) {
    final url = listing.coverPhotoUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isDisplayableImageUrl(url))
          CachedNetworkImage(
            imageUrl: sizedImageUrl(url!, width: 720),
            fit: BoxFit.cover,
            memCacheWidth: 720,
            placeholder: (_, _) =>
                ColoredBox(color: context.colorScheme.surfaceContainerHigh),
            errorWidget: (_, _, _) => BatshInitialPlate(name: name),
          )
        else
          BatshInitialPlate(name: name),
        Positioned(
          left: BatshSpacing.sm,
          bottom: BatshSpacing.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.xs,
              vertical: BatshSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.56),
              borderRadius: BatshRadius.brFull,
            ),
            child: Text(
              context.l10n.homeViewProfile,
              style: BatshTypography.labelSm.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CatalogueDetails extends StatelessWidget {
  const _CatalogueDetails({
    required this.listing,
    required this.name,
    required this.specialty,
    required this.area,
    required this.isSaved,
    required this.onToggleSave,
    required this.discoveryReason,
    required this.onTap,
  });

  final ContractorListing listing;
  final String name;
  final String specialty;
  final String area;
  final bool isSaved;
  final VoidCallback? onToggleSave;
  final String? discoveryReason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final rating = listing.rating;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.md,
            BatshSpacing.lg,
            BatshSpacing.md,
            BatshSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 36),
                child: Row(
                  children: [
                    AvatarWithInitials(
                      imageUrl: listing.logoUrl,
                      name: name,
                      radius: 20,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                        style: BatshTypography.titleMd.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BatshSpacing.xs),
              if (discoveryReason != null) ...[
                _DiscoveryReason(text: discoveryReason!),
                const SizedBox(height: BatshSpacing.xxs),
              ],
              TrustStrip(profile: TrustProfile.of(context, listing)),
              if (!listing.verified &&
                  listing.projectsCompleted == 0 &&
                  listing.yearsExperience == null)
                Text(
                  context.l10n.providerKindContractor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const Spacer(),
              Text(
                specialty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.bodyMd.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: BatshSpacing.xxs),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: BatshIconSize.sm,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: BatshSpacing.xxs),
                  Expanded(
                    child: Text(
                      area,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.bodySm.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BatshSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: BatshIconSize.sm,
                    color: scheme.tertiary,
                  ),
                  const SizedBox(width: BatshSpacing.xxs),
                  Text(
                    rating?.toStringAsFixed(1) ?? context.l10n.newBadge,
                    style: BatshTypography.labelLg.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (rating != null && listing.reviewCount > 0) ...[
                    const SizedBox(width: BatshSpacing.xxs),
                    Text(
                      '(${listing.reviewCount})',
                      style: BatshTypography.labelSm.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              if (listing.projectsCompleted > 0 ||
                  (listing.yearsExperience != null &&
                      listing.yearsExperience! > 0))
                Row(
                  children: [
                    if (listing.projectsCompleted > 0)
                      Expanded(
                        child: _Metric(
                          value: '${listing.projectsCompleted}',
                          label: context.l10n.singleProject,
                        ),
                      ),
                    if (listing.yearsExperience != null &&
                        listing.yearsExperience! > 0)
                      Expanded(
                        child: _Metric(
                          value: '${listing.yearsExperience}',
                          label: context.l10n.year,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: BatshSpacing.sm),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BatshRadius.brMd,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    context.l10n.homeViewProfile,
                    style: BatshTypography.labelMd.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        PositionedDirectional(
          top: BatshSpacing.xs,
          end: BatshSpacing.xs,
          child: IconButton(
            tooltip: isSaved
                ? context.l10n.unsaveTooltip
                : context.l10n.saveTooltip,
            onPressed: onToggleSave == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onToggleSave!();
                  },
            constraints: const BoxConstraints(
              minWidth: BatshSpacing.minHitArea,
              minHeight: BatshSpacing.minHitArea,
            ),
            padding: EdgeInsets.zero,
            icon: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: child,
              ),
              child: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                key: ValueKey(isSaved),
                size: BatshIconSize.md,
                color: isSaved ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoveryReason extends StatelessWidget {
  const _DiscoveryReason({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome_outlined,
          size: BatshIconSize.sm,
          color: context.colorScheme.primary,
        ),
        const SizedBox(width: BatshSpacing.xxs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: BatshTypography.labelLg.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BatshTypography.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
