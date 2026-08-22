import 'package:flutter/material.dart';

import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/shattab_pattern.dart';
import 'home_hero.dart';

/// The five trades a homeowner reaches for first, as one fixed row.
///
/// Deliberately not a scrolling strip. Five is the whole set, so scrolling
/// would hide part of a complete list behind a gesture; the "everything else"
/// affordance is spelled out above instead of riding along as a sixth tile
/// that looks like a trade and is not one.
class HomeServiceCategories extends StatelessWidget {
  const HomeServiceCategories({
    super.key,
    required this.onSelect,
    required this.onViewAll,
  });

  /// Receives a specialty key from the onboarding catalogue, e.g. `plumbing`.
  final ValueChanged<String> onSelect;
  final VoidCallback onViewAll;

  /// Left to right, which in Arabic puts plumbing nearest the reading edge and
  /// whole-home renovation furthest from it — the order the discover strip
  /// already uses, so the two do not reshuffle under a homeowner moving
  /// between tabs.
  static const _keys = <String>[
    'full_reno',
    'design',
    'paint',
    'electrical',
    'plumbing',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: homeGutter),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    context.l10n.homeServicesTitle,
                    style: BatshTypography.headlineSm.copyWith(
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              HomeViewAllLink(onTap: onViewAll),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: homeGutter),
          child: Semantics(
            container: true,
            label: context.l10n.filterCategory,
            // Equal columns rather than a fixed tile width: five tiles have to
            // span the gutter exactly on a 320 screen and on a 430 one.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _keys.length; i++) ...[
                    if (i > 0) const SizedBox(width: BatshSpacing.xs),
                    Expanded(
                      child: _ServiceCategoryTile(
                        icon: specialtyIcon(_keys[i]),
                        label: localizedSpecialtyLabel(context, _keys[i]),
                        onTap: () => onSelect(_keys[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceCategoryTile extends StatelessWidget {
  const _ServiceCategoryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.xxs,
          vertical: BatshSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brLg,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ShattabPattern(
                    kind: ShattabPatternKind.terrazzo,
                    color: BatshColors.patternLine,
                    opacity: 0.16,
                  ),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: BatshIconSize.action,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(height: BatshSpacing.xs),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelSm.copyWith(
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three things a homeowner can start right now.
///
/// Every card goes somewhere that exists. That constraint decided the middle
/// one: the reference offers a cost estimate, and Shattab has no estimator to
/// open, so the slot carries request tracking instead — a real destination in
/// the same "what is happening to my job" family, rather than a control that
/// looks live and does nothing.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onNearby,
    required this.onRequests,
    required this.onRequestQuote,
  });

  final VoidCallback onNearby;
  final VoidCallback onRequests;
  final VoidCallback onRequestQuote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: homeGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              header: true,
              child: Text(
                context.l10n.homeQuickStartTitle,
                style: BatshTypography.headlineSm.copyWith(
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: _PrimaryQuickActionCard(
                    icon: Icons.groups_2_outlined,
                    title: context.l10n.homeQuickNearbyTitle,
                    subtitle: context.l10n.homeQuickNearbySubtitle,
                    onTap: onNearby,
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  flex: 9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CompactQuickActionCard(
                        icon: Icons.fact_check_outlined,
                        title: context.l10n.homeQuickRequestsTitle,
                        subtitle: context.l10n.homeQuickRequestsSubtitle,
                        onTap: onRequests,
                      ),
                      const SizedBox(height: BatshSpacing.sm),
                      _CompactQuickActionCard(
                        icon: Icons.request_quote_outlined,
                        title: context.l10n.homeQuickQuoteTitle,
                        subtitle: context.l10n.homeQuickQuoteSubtitle,
                        onTap: onRequestQuote,
                      ),
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

class _PrimaryQuickActionCard extends StatelessWidget {
  const _PrimaryQuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: Container(
        constraints: const BoxConstraints(minHeight: 178),
        padding: const EdgeInsets.all(BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.primary,
          borderRadius: BatshRadius.brCard,
          boxShadow: BatshShadows.soft,
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colorScheme.onPrimary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: BatshIconSize.md,
                  color: context.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: BatshSpacing.sm),
              Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: BatshSpacing.xxxs),
              Text(
                subtitle,
                maxLines: 2,
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.onPrimary.withValues(alpha: 0.82),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: BatshSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: BatshIconSize.md,
                  color: context.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactQuickActionCard extends StatelessWidget {
  const _CompactQuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: Container(
        constraints: const BoxConstraints(minHeight: 84),
        padding: const EdgeInsets.all(BatshSpacing.sm),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brLg,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelMd.copyWith(
                        color: context.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.xxxs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              Icon(
                icon,
                size: BatshIconSize.md,
                color: context.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "عرض الكل" plus a chevron that points the way the language reads.
class HomeViewAllLink extends StatelessWidget {
  const HomeViewAllLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      label: context.l10n.viewAll,
      child: Material(
        color: Colors.transparent,
        borderRadius: BatshRadius.brSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brSm,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: BatshSpacing.minHitArea,
            ),
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.xs),
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.viewAll,
                    style: BatshTypography.labelMd.copyWith(
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.xxs),
                  Icon(
                    // "Onward" points left in Arabic, right in English.
                    rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: BatshIconSize.md,
                    color: context.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
