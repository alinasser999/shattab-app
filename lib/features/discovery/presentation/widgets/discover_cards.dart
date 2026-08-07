import 'package:flutter/material.dart';

import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../domain/contractor_listing.dart';
import 'mockup_assets.dart';

class NearbyProfessionalCard extends StatelessWidget {
  const NearbyProfessionalCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  final ContractorListing listing;
  final VoidCallback onTap;

  static const double width = 268;
  static const double height = 116;

  @override
  Widget build(BuildContext context) {
    final name = _professionalName(listing);
    final area = listing.serviceAreas.firstOrNull ?? '';
    return SizedBox(
      width: width,
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: name,
        child: Material(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brXl,
          clipBehavior: Clip.antiAlias,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                SizedBox(
                  width: 104,
                  child: MockupImage(
                    url: listing.coverPhotoUrl ?? mockupPortfolioImages[1],
                    memCacheWidth: 360,
                  ),
                ),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Padding(
                      padding: const EdgeInsets.all(BatshSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.labelLg,
                          ),
                          if (area.isNotEmpty)
                            Text(
                              area,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BatshTypography.bodySm.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (listing.hasReviews)
                            _InlineMetric(
                              icon: Icons.star_rounded,
                              value: listing.reviewAvg.toStringAsFixed(1),
                              label: '(${listing.reviewCount})',
                            ),
                        ],
                      ),
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

class RankedProfessionalTile extends StatelessWidget {
  const RankedProfessionalTile({
    super.key,
    required this.rank,
    required this.listing,
    required this.onTap,
  });

  final int rank;
  final ContractorListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = _professionalName(listing);
    final trade = listing.specialties.isEmpty
        ? listing.providerKind.label(context)
        : localizedSpecialtyLabel(context, listing.specialties.first);
    return BatshPressable(
      onTap: onTap,
      semanticLabel: name,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BatshSpacing.sm),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$rank',
                  style: BatshTypography.titleLg.copyWith(
                    color: context.colorScheme.primary,
                  ),
                ),
              ),
              AvatarWithInitials(
                imageUrl: listing.logoUrl ?? listing.coverPhotoUrl,
                name: name,
                radius: 24,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelLg,
                      ),
                      Text(
                        trade,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.bodySm.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (listing.hasReviews)
                _InlineMetric(
                  icon: Icons.star_rounded,
                  value: listing.reviewAvg.toStringAsFixed(1),
                  label: '(${listing.reviewCount})',
                ),
              const SizedBox(width: BatshSpacing.xs),
              Icon(
                Icons.arrow_forward_ios,
                size: BatshIconSize.xs,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    super.key,
    required this.onSelect,
    required this.onMore,
  });

  final ValueChanged<String> onSelect;
  final VoidCallback onMore;

  static const double _itemWidth = 70;
  static const double _plateSize = 58;
  static const _keys = [
    'full_reno',
    'design',
    'paint',
    'electrical',
    'plumbing',
  ];
  static const _icons = <String, IconData>{
    'full_reno': Icons.home_work_outlined,
    'design': Icons.chair_outlined,
    'paint': Icons.format_paint_outlined,
    'electrical': Icons.bolt_outlined,
    'plumbing': Icons.plumbing_outlined,
  };

  static double heightFor(BuildContext context) =>
      _plateSize + BatshSpacing.xs + MediaQuery.textScalerOf(context).scale(30);

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final key in _keys)
        (
          key: key,
          label: localizedSpecialtyLabel(context, key),
          icon: _icons[key]!,
        ),
      (key: '', label: context.l10n.more, icon: Icons.more_horiz_rounded),
    ];

    return SizedBox(
      height: heightFor(context),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.sectionH,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.xs),
          itemBuilder: (_, index) {
            final item = items[index];
            return SizedBox(
              width: _itemWidth,
              child: BatshPressable(
                onTap: item.key.isEmpty ? onMore : () => onSelect(item.key),
                semanticLabel: item.label,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: _plateSize,
                        height: _plateSize,
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colorScheme.outlineVariant,
                          ),
                          boxShadow: BatshShadows.soft,
                        ),
                        child: Icon(
                          item.icon,
                          size: BatshIconSize.action,
                          color: context.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.xs),
                      Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: BatshTypography.labelSm.copyWith(
                          color: context.colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: BatshIconSize.inline,
          color: icon == Icons.star_rounded
              ? context.colorScheme.tertiary
              : context.colorScheme.primary,
        ),
        const SizedBox(width: BatshSpacing.xxs),
        Text(
          value,
          style: BatshTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: BatshSpacing.xxs),
          Text(
            label,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

String _professionalName(ContractorListing listing) =>
    listing.businessName.isNotEmpty ? listing.businessName : listing.fullName;
