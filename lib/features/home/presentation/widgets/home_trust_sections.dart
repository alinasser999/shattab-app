import 'package:flutter/material.dart';

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

/// A calm explanation of the product journey, placed after evidence rather
/// than before it. It answers "what happens next?" without becoming a generic
/// benefits grid.
class HomeProcessSection extends StatelessWidget {
  const HomeProcessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: homeGutter),
      child: Container(
        padding: const EdgeInsets.all(BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brCard,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.58),
          ),
          boxShadow: BatshShadows.soft,
        ),
        child: Stack(
          children: [
            const PositionedDirectional(
              top: 0,
              end: 0,
              width: 116,
              height: 96,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ShattabPattern(
                    kind: ShattabPatternKind.lattice,
                    color: BatshColors.patternLine,
                    opacity: 0.12,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const ShattabMotifIcon(
                      motif: ShattabMotif.arch,
                      color: BatshColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          context.l10n.homeProcessTitle,
                          style: BatshTypography.titleLg.copyWith(
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BatshSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 300;
                    final steps = [
                      _ProcessStepData(
                        number: '١',
                        title: context.l10n.homeProcessStepOne,
                        body: context.l10n.homeProcessStepOneBody,
                        motif: ShattabMotif.compass,
                      ),
                      _ProcessStepData(
                        number: '٢',
                        title: context.l10n.homeProcessStepTwo,
                        body: context.l10n.homeProcessStepTwoBody,
                        motif: ShattabMotif.tile,
                      ),
                      _ProcessStepData(
                        number: '٣',
                        title: context.l10n.homeProcessStepThree,
                        body: context.l10n.homeProcessStepThreeBody,
                        motif: ShattabMotif.finish,
                      ),
                    ];

                    if (compact) {
                      return Column(
                        children: [
                          for (var i = 0; i < steps.length; i++) ...[
                            _ProcessStep(data: steps[i]),
                            if (i < steps.length - 1)
                              const _ProcessConnector(vertical: true),
                          ],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < steps.length; i++) ...[
                          Expanded(child: _ProcessStep(data: steps[i])),
                          if (i < steps.length - 1)
                            const _ProcessConnector(vertical: false),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessStepData {
  const _ProcessStepData({
    required this.number,
    required this.title,
    required this.body,
    required this.motif,
  });

  final String number;
  final String title;
  final String body;
  final ShattabMotif motif;
}

class _ProcessStep extends StatelessWidget {
  const _ProcessStep({required this.data});

  final _ProcessStepData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.colorScheme.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: ShattabMotifIcon(
                  motif: data.motif,
                  color: context.colorScheme.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: BatshSpacing.xs),
            Text(
              data.number,
              textDirection: TextDirection.rtl,
              style: BatshTypography.labelLg.copyWith(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.xs),
        Text(
          data.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: BatshTypography.labelMd.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: BatshSpacing.xxxs),
        Text(
          data.body,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: BatshTypography.labelSm.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ProcessConnector extends StatelessWidget {
  const _ProcessConnector({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.outlineVariant.withValues(alpha: 0.8);
    return vertical
        ? SizedBox(
            height: BatshSpacing.md,
            child: Center(child: Container(width: 1, color: color)),
          )
        : Padding(
            padding: const EdgeInsets.only(top: 21),
            child: SizedBox(
              width: BatshSpacing.md,
              child: Center(child: Container(height: 1, color: color)),
            ),
          );
  }
}

class HomeCommunityInvite extends StatelessWidget {
  const HomeCommunityInvite({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.homeCommunityInviteTitle;
    final body = context.l10n.homeCommunityInviteBody;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: homeGutter),
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: '$title. $body',
        pressedScale: 0.985,
        child: Container(
          padding: const EdgeInsets.all(BatshSpacing.md),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLow,
            borderRadius: BatshRadius.brCard,
            border: Border.all(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.64),
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: ShattabPattern(
                      kind: ShattabPatternKind.contour,
                      color: BatshColors.patternLine,
                      opacity: 0.14,
                    ),
                  ),
                ),
              ),
              ExcludeSemantics(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceContainerLowest,
                        borderRadius: BatshRadius.brLg,
                        border: Border.all(
                          color: context.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Center(
                        child: ShattabMotifIcon(
                          motif: ShattabMotif.compass,
                          color: context.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.titleMd.copyWith(
                              color: context.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: BatshSpacing.xxxs),
                          Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.bodySm.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Icon(
                      Icons.arrow_back_rounded,
                      size: BatshIconSize.md,
                      color: context.colorScheme.primary,
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

class HomeClosingCta extends StatelessWidget {
  const HomeClosingCta({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: homeGutter),
      child: Container(
        padding: const EdgeInsets.all(BatshSpacing.lg),
        decoration: BoxDecoration(
          color: context.colorScheme.primary,
          borderRadius: BatshRadius.brCard,
          boxShadow: BatshShadows.soft,
        ),
        child: Stack(
          children: [
            const PositionedDirectional(
              top: -8,
              end: -6,
              width: 150,
              height: 120,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ShattabPattern(
                    kind: ShattabPatternKind.lattice,
                    color: Colors.white,
                    opacity: 0.08,
                  ),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ShattabMotifIcon(
                      motif: ShattabMotif.finish,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Text(
                    context.l10n.homeClosingCtaTitle,
                    style: BatshTypography.headlineSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xxs),
                  Text(
                    context.l10n.homeClosingCtaBody,
                    style: BatshTypography.bodyMd.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _ClosingButton(onTap: onTap),
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

class _ClosingButton extends StatelessWidget {
  const _ClosingButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.homeClosingCtaAction,
      child: Material(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brFull,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.md,
              vertical: BatshSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.homeClosingCtaAction,
                  style: BatshTypography.labelMd.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: BatshSpacing.xs),
                Icon(
                  Icons.arrow_back_rounded,
                  size: BatshIconSize.md,
                  color: context.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
