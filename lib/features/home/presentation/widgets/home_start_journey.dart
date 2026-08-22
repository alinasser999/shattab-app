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

/// The first useful decision on the home page.
///
/// This intentionally keeps one dominant action beside three quieter ones.
/// It gives a new homeowner a clear beginning without turning the home page
/// into a symmetrical grid of equally loud cards.
class HomeStartJourney extends StatelessWidget {
  const HomeStartJourney({
    super.key,
    required this.onDiscover,
    required this.onRequestQuote,
  });

  final VoidCallback onDiscover;
  final VoidCallback onRequestQuote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: homeGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _JourneyHeading(title: context.l10n.homeStartTitle),
          const SizedBox(height: BatshSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              final request = _JourneyRequestAction(onTap: onRequestQuote);

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _JourneyPrimaryAction(onTap: onDiscover),
                    const SizedBox(height: BatshSpacing.sm),
                    request,
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 11,
                      child: _JourneyPrimaryAction(onTap: onDiscover),
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    Expanded(flex: 10, child: request),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JourneyHeading extends StatelessWidget {
  const _JourneyHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final lineColor = context.colorScheme.outlineVariant.withValues(alpha: 0.7);
    return Row(
      children: [
        const ShattabMotifIcon(
          motif: ShattabMotif.finish,
          color: BatshColors.primary,
          size: 18,
        ),
        const SizedBox(width: BatshSpacing.xs),
        Semantics(
          header: true,
          child: Text(
            title,
            style: BatshTypography.headlineSm.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(child: Divider(color: lineColor)),
      ],
    );
  }
}

class _JourneyPrimaryAction extends StatelessWidget {
  const _JourneyPrimaryAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.homeStartDiscoverTitle;
    final subtitle = context.l10n.homeStartDiscoverSubtitle;
    final color = context.colorScheme.primary;

    return BatshPressable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      pressedScale: 0.98,
      child: Container(
        constraints: const BoxConstraints(minHeight: 214),
        padding: const EdgeInsets.all(BatshSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BatshRadius.brCard,
          boxShadow: BatshShadows.soft,
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ShattabPattern(
                    kind: ShattabPatternKind.arches,
                    color: Colors.white,
                    opacity: 0.09,
                    strokeWidth: 1.1,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: ExcludeSemantics(
                child: ShattabMotifIcon(
                  motif: ShattabMotif.arch,
                  color: Colors.white.withValues(alpha: 0.82),
                  size: 34,
                ),
              ),
            ),
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: ShattabMotifIcon(
                        motif: ShattabMotif.compass,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.md),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.titleLg.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xxs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: BatshIconSize.md,
                      color: Colors.white,
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

class _JourneyRequestAction extends StatelessWidget {
  const _JourneyRequestAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.homeStartQuoteTitle;
    final subtitle = context.l10n.homeStartQuoteSubtitle;
    return BatshPressable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      pressedScale: 0.98,
      child: Container(
        constraints: const BoxConstraints(minHeight: 214),
        padding: const EdgeInsets.all(BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brCard,
          border: Border.all(
            color: context.colorScheme.primary.withValues(alpha: 0.32),
          ),
          boxShadow: BatshShadows.soft,
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              bottom: -20,
              end: -14,
              width: 116,
              height: 96,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ShattabPattern(
                    kind: ShattabPatternKind.contour,
                    color: context.colorScheme.primary,
                    opacity: 0.08,
                  ),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: ShattabMotifIcon(
                        motif: ShattabMotif.finish,
                        color: context.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 2,
                    style: BatshTypography.titleLg.copyWith(
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xxs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    style: BatshTypography.bodySm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: context.colorScheme.primary,
                      size: BatshIconSize.md,
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
