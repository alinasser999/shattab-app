import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/professional_reference_theme.dart';
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
    this.referenceStyle = false,
  }) : assert(step > 0 && step <= total);

  final int step;
  final int total;
  final String stepLabel;
  final VoidCallback? onBack;
  final bool referenceStyle;

  @override
  Widget build(BuildContext context) {
    final announcement =
        '${context.l10n.onboardingStepLabel(step, total)}. $stepLabel';
    return Semantics(
      container: true,
      explicitChildNodes: referenceStyle,
      liveRegion: !referenceStyle,
      label: referenceStyle ? null : announcement,
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
                    child: IconTheme(
                      data: IconThemeData(
                        color: referenceStyle
                            ? ProfessionalReferenceTheme.action
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BackButtonIcon(),
                          const SizedBox(width: BatshSpacing.xs),
                          Text(
                            context.l10n.back,
                            style: referenceStyle
                                ? ProfessionalReferenceTheme.text(
                                    16,
                                    color: ProfessionalReferenceTheme.action,
                                    weight: FontWeight.w700,
                                  )
                                : BatshTypography.labelMd,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
          ],
          Semantics(
            container: referenceStyle,
            header: referenceStyle,
            liveRegion: referenceStyle,
            label: referenceStyle ? announcement : null,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.onboardingStepLabel(step, total),
                  style: referenceStyle
                      ? ProfessionalReferenceTheme.text(
                          14,
                          color: ProfessionalReferenceTheme.action,
                          weight: FontWeight.w700,
                        )
                      : BatshTypography.labelMd.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Semantics(
                  header: true,
                  child: Text(
                    stepLabel,
                    style: referenceStyle
                        ? ProfessionalReferenceTheme.text(
                            22,
                            weight: FontWeight.w700,
                          )
                        : BatshTypography.titleLg,
                  ),
                ),
                const SizedBox(height: BatshSpacing.sm),
                ClipRRect(
                  borderRadius: BatshRadius.brFull,
                  child: Container(
                    height: BatshSpacing.xs,
                    color: referenceStyle
                        ? const Color(0xffe7e5e0)
                        : context.colorScheme.surfaceContainerHighest,
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: step / total,
                      heightFactor: 1,
                      child: ColoredBox(
                        color: referenceStyle
                            ? ProfessionalReferenceTheme.orange
                            : context.colorScheme.primary,
                      ),
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
