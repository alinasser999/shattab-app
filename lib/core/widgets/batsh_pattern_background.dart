import 'package:flutter/material.dart';

import '../theme/batsh_radius.dart';
import '../theme/theme_extension.dart';
import 'shattab_pattern.dart';

/// The quiet identity layer shared by content screens.
///
/// Shattab's architectural language should be present in the negative space,
/// not stamped across every card. The corner compositions stay fixed behind
/// scrolling content, so the page feels authored without adding visual noise
/// or making long lists expensive to paint.
class BatshPatternBackground extends StatelessWidget {
  const BatshPatternBackground({
    super.key,
    required this.child,
    this.kind = ShattabPatternKind.contour,
    this.opacity = 0.085,
    this.showMotifs = true,
  });

  final Widget child;
  final ShattabPatternKind kind;
  final double opacity;
  final bool showMotifs;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final lineColor = scheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surface),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PositionedDirectional(
                      top: -84,
                      start: -76,
                      width: 224,
                      height: 224,
                      child: Opacity(
                        opacity: opacity,
                        child: ShattabPattern(
                          kind: ShattabPatternKind.arches,
                          color: lineColor,
                          strokeWidth: 1.05,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 34,
                      end: -98,
                      width: 250,
                      height: 250,
                      child: Opacity(
                        opacity: opacity * 0.72,
                        child: ShattabPattern(
                          kind: kind,
                          color: lineColor,
                          strokeWidth: 0.85,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: -112,
                      start: -86,
                      width: 270,
                      height: 270,
                      child: Opacity(
                        opacity: opacity * 0.82,
                        child: ShattabPattern(
                          kind: ShattabPatternKind.lattice,
                          color: lineColor,
                          strokeWidth: 0.8,
                        ),
                      ),
                    ),
                    if (showMotifs) ...[
                      PositionedDirectional(
                        top: 26,
                        start: 18,
                        child: _MotifPlate(
                          motif: ShattabMotif.arch,
                          color: lineColor,
                        ),
                      ),
                      PositionedDirectional(
                        bottom: 82,
                        end: 14,
                        child: _MotifPlate(
                          motif: ShattabMotif.tile,
                          color: lineColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          child,
          // A final watermark layer keeps the identity visible even when a
          // scrolling viewport paints an opaque canvas over its background.
          // It is confined to the edges and remains quiet beneath content.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PositionedDirectional(
                      top: 136,
                      start: -52,
                      width: 92,
                      height: 128,
                      child: Opacity(
                        opacity: 0.075,
                        child: ShattabPattern(
                          kind: ShattabPatternKind.arches,
                          color: lineColor,
                          strokeWidth: 0.75,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 74,
                      end: -42,
                      width: 118,
                      height: 156,
                      child: Opacity(
                        opacity: 0.09,
                        child: ShattabPattern(
                          kind: ShattabPatternKind.contour,
                          color: lineColor,
                          strokeWidth: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MotifPlate extends StatelessWidget {
  const _MotifPlate({required this.motif, required this.color});

  final ShattabMotif motif;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.11,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLow.withValues(
            alpha: 0.34,
          ),
          borderRadius: BatshRadius.brFull,
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: ShattabMotifIcon(motif: motif, color: color, size: 26),
        ),
      ),
    );
  }
}
