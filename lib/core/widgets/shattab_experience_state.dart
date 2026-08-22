import 'package:flutter/material.dart';

import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/theme_extension.dart';
import 'batsh_button.dart';
import 'batsh_shimmer.dart';
import 'shattab_pattern.dart';

/// Branded state surface for moments that need to explain what is happening.
class ShattabExperienceState extends StatelessWidget {
  const ShattabExperienceState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.pattern = ShattabPatternKind.arches,
    this.compact = false,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final ShattabPatternKind pattern;
  final bool compact;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final stateAccent = accent ?? scheme.primary;
    final horizontal = compact ? BatshSpacing.md : BatshSpacing.lg;
    final vertical = compact ? BatshSpacing.md : BatshSpacing.xl;

    return Semantics(
      container: true,
      label: '$title. $message',
      child: ClipRRect(
        borderRadius: BatshRadius.brCard,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brCard,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.72),
            ),
            boxShadow: BatshShadows.soft,
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                top: -18,
                end: -14,
                width: compact ? 130 : 170,
                height: compact ? 108 : 142,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: 0.22,
                      child: ShattabPattern(
                        kind: pattern,
                        color: stateAccent,
                        opacity: 0.32,
                        strokeWidth: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontal,
                  vertical: vertical,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StateIcon(icon: icon, color: stateAccent),
                        const SizedBox(width: BatshSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: BatshTypography.titleLg.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: BatshSpacing.xs),
                              Text(
                                message,
                                style: BatshTypography.bodyMd.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (onAction != null && actionLabel != null) ...[
                      const SizedBox(height: BatshSpacing.lg),
                      BatshButton(
                        label: actionLabel!,
                        onPressed: onAction,
                        icon: Icons.arrow_back_rounded,
                      ),
                    ],
                    if (onSecondaryAction != null &&
                        secondaryActionLabel != null) ...[
                      const SizedBox(height: BatshSpacing.xs),
                      TextButton(
                        onPressed: onSecondaryAction,
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            BatshSpacing.minHitArea,
                          ),
                          foregroundColor: stateAccent,
                        ),
                        child: Text(secondaryActionLabel!),
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

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

/// Layout-preserving skeleton for a state panel.
class ShattabExperienceSkeleton extends StatelessWidget {
  const ShattabExperienceSkeleton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brCard,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? BatshSpacing.md : BatshSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BatshShimmerBox(
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(26),
                ),
                const SizedBox(width: BatshSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BatshShimmerBox(width: 148, height: 18),
                      SizedBox(height: BatshSpacing.xs),
                      BatshShimmerBox(width: double.infinity, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshShimmerBox(width: double.infinity, height: compact ? 42 : 52),
            if (!compact) ...[
              const SizedBox(height: BatshSpacing.sm),
              const BatshShimmerBox(width: double.infinity, height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
