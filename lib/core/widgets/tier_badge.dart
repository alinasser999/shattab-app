import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

import '../../features/discovery/domain/contractor_listing.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// The earned trust level — "مستوى فضي" / "مستوى ذهبي" — shown to homeowners.
///
/// **Deliberately unlike the paid Pro badge.** Pro is a filled gradient pill in
/// terracotta/gold carrying `workspace_premium_rounded`; this is a flat,
/// square-cornered chip in olive with an outlined trophy, and it names itself
/// "مستوى". If a bought badge and an earned one look alike, the app is selling
/// trust it never verified — an ethics problem before it is a store-review one.
///
/// Bronze never renders: see [ContractorTier.isPublic].
class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.tier, this.explainOnTap = false});

  final ContractorTier tier;

  /// Makes the chip tappable and opens [showTierExplainer].
  ///
  /// Off inside a card, where the whole card is already one tap target and a
  /// nested one would swallow the navigation gesture.
  final bool explainOnTap;

  @override
  Widget build(BuildContext context) {
    if (!tier.isPublic) return const SizedBox.shrink();

    final label = '${context.l10n.tierLevelPrefix} ${tier.label(context)}';
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        // Opaque: on the card this sits over an arbitrary cover photo.
        color: context.colorScheme.secondaryContainer,
        borderRadius: BatshRadius.brSm,
        border: Border.all(color: context.colorScheme.secondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon and word each carry the meaning alone, so the badge survives a
          // greyscale or colour-blind read.
          Icon(
            Icons.emoji_events_outlined,
            size: BatshIconSize.sm,
            color: context.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (explainOnTap) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.info_outline,
              size: BatshIconSize.xs,
              color: context.colorScheme.onSecondaryContainer,
            ),
          ],
        ],
      ),
    );

    if (!explainOnTap) return Semantics(label: label, child: chip);

    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        borderRadius: BatshRadius.brSm,
        onTap: () => showTierExplainer(context),
        child: chip,
      ),
    );
  }
}

/// Spells out exactly how a level is reached, including the line saying it
/// cannot be bought. The badge is worth nothing as a trust signal if the reader
/// cannot check what produced it.
Future<void> showTierExplainer(BuildContext context) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(context.l10n.tierHowTitle),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.tierHowGold, style: BatshTypography.bodyMd),
        const SizedBox(height: BatshSpacing.xs),
        Text(context.l10n.tierHowSilver, style: BatshTypography.bodyMd),
        const SizedBox(height: BatshSpacing.sm),
        Text(
          context.l10n.tierNotForSale,
          style: BatshTypography.bodySm.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text(context.l10n.done),
      ),
    ],
  ),
);
