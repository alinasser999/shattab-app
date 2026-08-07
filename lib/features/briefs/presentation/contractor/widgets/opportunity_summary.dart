import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/l10n/l10n_extension.dart';
import '../../../../../core/theme/batsh_icon_size.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_shadows.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/theme/batsh_typography.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/shattab_pattern.dart';
import '../../../domain/opportunity_experience.dart';

const _terrazzoAsset = 'assets/images/opportunity_terrazzo.png';

/// The opportunity summary mirrors the approved asymmetric composition:
/// one meaningful match is the focal point, while the supporting metrics stay
/// compact and actionable instead of becoming a generic dashboard.
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final surface = _OpportunitySummarySurface(
      metrics: metrics,
      preferencesCompletion: preferencesCompletion,
      onPreferencesTap: onPreferencesTap,
      onMetricTap: onMetricTap,
    );

    if (reduceMotion) return surface;
    return KeyedSubtree(
      key: ValueKey(animationKey ?? 'opportunity-summary'),
      child: surface
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 360))
          .slideY(
            begin: 0.035,
            end: 0,
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
          ),
    );
  }
}

class _OpportunitySummarySurface extends StatelessWidget {
  const _OpportunitySummarySurface({
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXxl,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.62),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BatshRadius.brXxl,
        child: Stack(
          children: [
            PositionedDirectional(
              end: -4,
              bottom: preferencesCompletion < 100 ? 58 : -8,
              width: 84,
              height: 108,
              child: IgnorePointer(
                child: Opacity(
                  opacity: context.theme.brightness == Brightness.dark
                      ? 0.18
                      : 0.28,
                  child: const _BotanicalBranch(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BatshSpacing.md,
                BatshSpacing.sm,
                BatshSpacing.md,
                BatshSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryHeading(),
                  const SizedBox(height: BatshSpacing.sm),
                  _SummaryGrid(metrics: metrics, onMetricTap: onMetricTap),
                  if (preferencesCompletion < 100) ...[
                    const SizedBox(height: BatshSpacing.sm),
                    _PreferencesNudge(onTap: onPreferencesTap),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          const Expanded(child: _DottedRule()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShattabMotifIcon(
                  motif: ShattabMotif.finish,
                  color: context.colorScheme.primary,
                  size: BatshIconSize.sm,
                ),
                const SizedBox(width: BatshSpacing.xs),
                Text(
                  context.l10n.opportunitySummaryHeading,
                  style: BatshTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: _DottedRule()),
        ],
      ),
    );
  }
}

class _DottedRule extends StatelessWidget {
  const _DottedRule();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: CustomPaint(
        painter: _DottedRulePainter(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _DottedRulePainter extends CustomPainter {
  const _DottedRulePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawCircle(Offset(x, size.height / 2), 1, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedRulePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.metrics, required this.onMetricTap});

  final OpportunityRadarMetrics metrics;
  final ValueChanged<OpportunityFocus>? onMetricTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).width <= 340 ? 148 : 160,
      child: Row(
        textDirection: Directionality.of(context),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricTile(
              icon: Icons.location_on_outlined,
              value: metrics.areaCount,
              label: context.l10n.opportunityAreaCount,
              accent: context.colorScheme.secondary,
              onTap: onMetricTap == null
                  ? null
                  : () => onMetricTap!(OpportunityFocus.nearby),
            ),
          ),
          const SizedBox(width: BatshSpacing.xs),
          Expanded(
            flex: 1,
            child: _HighlightedMetric(
              value: metrics.matchingCount,
              label: context.l10n.opportunityCountLabel,
              onTap: onMetricTap == null
                  ? null
                  : () => onMetricTap!(OpportunityFocus.all),
            ),
          ),
          const SizedBox(width: BatshSpacing.xs),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.bolt_rounded,
                    value: metrics.freshCount,
                    label: context.l10n.radarFresh,
                    accent: context.colorScheme.primary,
                    onTap: onMetricTap == null
                        ? null
                        : () => onMetricTap!(OpportunityFocus.fresh),
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.schedule_outlined,
                    value: metrics.weekCount,
                    label: context.l10n.opportunityWeekCount,
                    accent: context.colorScheme.error,
                    onTap: onMetricTap == null
                        ? null
                        : () => onMetricTap!(OpportunityFocus.thisWeek),
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

class _HighlightedMetric extends StatelessWidget {
  const _HighlightedMetric({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = context.colorScheme.primary;
    return Semantics(
      button: onTap != null,
      label: '$value $label',
      child: Material(
        color: background,
        borderRadius: BatshRadius.brLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: context.colorScheme.onPrimary.withValues(alpha: 0.14),
          highlightColor: context.colorScheme.onPrimary.withValues(alpha: 0.08),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: context.theme.brightness == Brightness.dark
                    ? 0.12
                    : 0.2,
                child: Image.asset(_terrazzoAsset, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.xs,
                  vertical: BatshSpacing.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colorScheme.onPrimary.withValues(
                          alpha: 0.13,
                        ),
                        borderRadius: BatshRadius.brFull,
                      ),
                      child: Icon(
                        Icons.gps_fixed_rounded,
                        size: BatshIconSize.sm,
                        color: context.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$value',
                        style: BatshTypography.displayMd.copyWith(
                          color: context.colorScheme.onPrimary,
                          fontSize: 30,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.xxs),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onPrimary.withValues(
                          alpha: 0.94,
                        ),
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
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$value $label',
      child: Material(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BatshRadius.brLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: accent.withValues(alpha: 0.12),
          highlightColor: accent.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.xs,
              vertical: BatshSpacing.xs,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BatshRadius.brFull,
                      ),
                      child: Icon(icon, size: BatshIconSize.xs, color: accent),
                    ),
                    const SizedBox(height: BatshSpacing.xxs),
                    Text(
                      '$value',
                      style: BatshTypography.titleLg.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferencesNudge extends StatelessWidget {
  const _PreferencesNudge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.primaryContainer.withValues(alpha: 0.54),
      borderRadius: BatshRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brMd,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            BatshSpacing.sm,
            BatshSpacing.xs,
            BatshSpacing.xs,
            BatshSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.completeOpportunityPreferencesHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onPrimaryContainer,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              Icon(
                Icons.arrow_back_rounded,
                size: BatshIconSize.xs,
                color: context.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotanicalBranch extends StatelessWidget {
  const _BotanicalBranch();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BotanicalBranchPainter(
        color: context.colorScheme.primary.withValues(alpha: 0.6),
      ),
    );
  }
}

class _BotanicalBranchPainter extends CustomPainter {
  const _BotanicalBranchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final branch = Path()
      ..moveTo(size.width * 0.12, size.height * 0.96)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.72,
        size.width * 0.42,
        size.height * 0.54,
        size.width * 0.86,
        size.height * 0.12,
      );
    canvas.drawPath(branch, stroke);
    for (final leaf in [
      (0.3, 0.73, -0.55),
      (0.46, 0.56, 0.2),
      (0.61, 0.39, -0.42),
      (0.75, 0.24, 0.22),
    ]) {
      final center = Offset(size.width * leaf.$1, size.height * leaf.$2);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(leaf.$3);
      final path = Path()
        ..moveTo(0, 0)
        ..cubicTo(
          size.width * 0.1,
          -size.height * 0.11,
          size.width * 0.22,
          -size.height * 0.08,
          size.width * 0.25,
          0,
        )
        ..cubicTo(
          size.width * 0.17,
          size.height * 0.08,
          size.width * 0.06,
          size.height * 0.08,
          0,
          0,
        );
      canvas.drawPath(path, stroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BotanicalBranchPainter oldDelegate) =>
      oldDelegate.color != color;
}
