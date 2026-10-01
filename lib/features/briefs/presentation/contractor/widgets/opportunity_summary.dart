import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/l10n/l10n_extension.dart';
import '../../../../../core/theme/batsh_icon_size.dart';
import '../../../../../core/theme/batsh_motion.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/theme/batsh_typography.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../domain/opportunity_experience.dart';

/// Compact four-part summary matching the opportunities reference.
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
    final surface = _SummarySurface(metrics: metrics, onMetricTap: onMetricTap);
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
  const _SummarySurface({required this.metrics, required this.onMetricTap});

  final OpportunityRadarMetrics metrics;
  final ValueChanged<OpportunityFocus>? onMetricTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .62)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.sm,
          BatshSpacing.sm,
          BatshSpacing.sm,
          BatshSpacing.md,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.opportunitySummaryHeading,
                    style: BatshTypography.titleMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.bar_chart_rounded, color: scheme.primary),
              ],
            ),
            const SizedBox(height: BatshSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    value: metrics.matchingCount,
                    label: context.l10n.opportunityCountLabel,
                    icon: Icons.track_changes_rounded,
                    onTap: _focus(OpportunityFocus.all),
                  ),
                ),
                const SizedBox(width: BatshSpacing.xs),
                Expanded(
                  child: _SummaryMetric(
                    value: metrics.weekCount,
                    label: context.l10n.opportunityWeekCount,
                    icon: Icons.schedule_rounded,
                    onTap: _focus(OpportunityFocus.thisWeek),
                  ),
                ),
                const SizedBox(width: BatshSpacing.xs),
                Expanded(
                  child: _SummaryMetric(
                    value: metrics.areaCount,
                    label: context.l10n.opportunityAreaCount,
                    icon: Icons.location_on_outlined,
                    onTap: _focus(OpportunityFocus.nearby),
                  ),
                ),
                const SizedBox(width: BatshSpacing.xs),
                Expanded(
                  child: _SummaryMetric(
                    value: metrics.freshCount,
                    label: context.l10n.radarFresh,
                    icon: Icons.bolt_rounded,
                    onTap: _focus(OpportunityFocus.fresh),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _focus(OpportunityFocus focus) =>
      onMetricTap == null ? null : () => onMetricTap!(focus);
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final int value;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: '$value $label',
    child: InkWell(
      onTap: onTap,
      borderRadius: BatshRadius.brMd,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.xxs,
          vertical: BatshSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLow.withValues(alpha: .5),
          borderRadius: BatshRadius.brMd,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: .5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: BatshIconSize.sm,
              color: context.colorScheme.primary,
            ),
            Text(
              '$value',
              style: BatshTypography.titleMd.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
