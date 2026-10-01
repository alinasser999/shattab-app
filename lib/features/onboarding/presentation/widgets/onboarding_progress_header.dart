import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/batsh_pressable.dart';

class OnboardingProgressHeader extends StatelessWidget {
  const OnboardingProgressHeader({
    super.key,
    required this.step,
    required this.stepLabel,
    this.total = 3,
    this.onBack,
  }) : assert(step > 0 && step <= total);

  final int step;
  final int total;
  final String stepLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final announcement =
        '${context.l10n.onboardingStepLabel(step, total)}. $stepLabel';
    return Semantics(
      container: true,
      liveRegion: true,
      label: announcement,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onBack != null) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: BatshPressable(
                semanticLabel: context.l10n.back,
                onTap: onBack,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: BatshSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BackButtonIcon(),
                        const SizedBox(width: BatshSpacing.xs),
                        Text(context.l10n.back, style: BatshTypography.labelMd),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
          ],
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.onboardingStepLabel(step, total),
                  style: BatshTypography.labelMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Text(stepLabel, style: BatshTypography.titleLg),
                const SizedBox(height: BatshSpacing.sm),
                ClipRRect(
                  borderRadius: BatshRadius.brFull,
                  child: Container(
                    height: BatshSpacing.xs,
                    color: context.colorScheme.surfaceContainerHighest,
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: step / total,
                      heightFactor: 1,
                      child: ColoredBox(color: context.colorScheme.primary),
                    ),
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
