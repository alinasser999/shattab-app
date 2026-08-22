import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/l10n/l10n_extension.dart';
import '../../../../../core/theme/batsh_icon_size.dart';
import '../../../../../core/theme/batsh_motion.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/theme/batsh_typography.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/batsh_pressable.dart';
import '../../../domain/opportunity_experience.dart';

/// A compact, actionable read of the feed.
///
/// The previous dashboard visual asked contractors to decode a chart before
/// seeing work. This surface answers the real question in one sentence, then
/// exposes only the three useful feed views.
class OpportunitySummary extends StatelessWidget {
  const OpportunitySummary({
    super.key,
    required this.metrics,
    required this.preferencesCompletion,
    required this.onPreferencesTap,
    this.onMetricTap,
    this.animationKey,
  });

  final OpportunityRadarMetrics metrics;
  final int preferencesCompletion;
  final VoidCallback onPreferencesTap;
  final ValueChanged<OpportunityFocus>? onMetricTap;
  final Object? animationKey;

  @override
  Widget build(BuildContext context) {
    final surface = _SummarySurface(
      metrics: metrics,
      preferencesCompletion: preferencesCompletion,
      onPreferencesTap: onPreferencesTap,
      onMetricTap: onMetricTap,
    );
    if (MediaQuery.disableAnimationsOf(context)) return surface;
    return KeyedSubtree(
      key: ValueKey(animationKey ?? 'opportunity-summary'),
      child: surface
          .animate()
          .fadeIn(duration: BatshMotion.normal)
          .slideY(begin: 0.025, end: 0, curve: BatshMotion.easeOut),
    );
  }
}

class _SummarySurface extends StatelessWidget {
  const _SummarySurface({
    required this.metrics,
    required this.preferencesCompletion,
    required this.onPreferencesTap,
    required this.onMetricTap,
  });

  final OpportunityRadarMetrics metrics;
  final int preferencesCompletion;
  final VoidCallback onPreferencesTap;
  final ValueChanged<OpportunityFocus>? onMetricTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brCard,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BatshRadius.brMd,
                  ),
                  child: Icon(
                    Icons.work_outline_rounded,
                    color: scheme.primary,
                    size: BatshIconSize.md,
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.opportunitySummaryHeading,
                        style: BatshTypography.titleMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.xxs),
                      Text(
                        context.l10n.opportunityCompactSummary(
                          metrics.matchingCount,
                          metrics.freshCount,
                          metrics.areaCount,
                        ),
                        style: BatshTypography.bodySm.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BatshSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _FeedView(
                    icon: Icons.auto_awesome_outlined,
                    label: context.l10n.filterAll,
                    onTap: onMetricTap == null
                        ? null
                        : () => onMetricTap!(OpportunityFocus.all),
                  ),
                ),
                const SizedBox(width: BatshSpacing.xs),
                Expanded(
                  child: _FeedView(
                    icon: Icons.location_on_outlined,
                    label: context.l10n.filterNearYou,
                    onTap: onMetricTap == null
                        ? null
                        : () => onMetricTap!(OpportunityFocus.nearby),
                  ),
                ),
                const SizedBox(width: BatshSpacing.xs),
                Expanded(
                  child: _FeedView(
                    icon: Icons.bolt_rounded,
                    label: context.l10n.filterFresh,
                    onTap: onMetricTap == null
                        ? null
                        : () => onMetricTap!(OpportunityFocus.fresh),
                  ),
                ),
              ],
            ),
            if (preferencesCompletion < 100) ...[
              const SizedBox(height: BatshSpacing.sm),
              BatshPressable(
                onTap: onPreferencesTap,
                semanticLabel: context.l10n.adjustOpportunityPreferences,
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: scheme.primary,
                      size: BatshIconSize.sm,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Expanded(
                      child: Text(
                        context.l10n.adjustOpportunityPreferences,
                        style: BatshTypography.labelMd.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$preferencesCompletion%',
                      textDirection: TextDirection.ltr,
                      style: BatshTypography.labelMd.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedView extends StatelessWidget {
  const _FeedView({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.xs),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLow,
          borderRadius: BatshRadius.brMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: BatshIconSize.sm,
              color: context.colorScheme.primary,
            ),
            const SizedBox(width: BatshSpacing.xxs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
