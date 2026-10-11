import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshBottomNavItem {
  const BatshBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Shared navigation: labels keep the user's text scale and may wrap.
class BatshBottomNav extends StatelessWidget {
  const BatshBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.anchored = false,
    this.fontFamily,
  });

  final List<BatshBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final bool anchored;
  final String? fontFamily;

  static double contentBottomInset(BuildContext context) =>
      112 + MediaQuery.of(context).padding.bottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final inset = anchored || MediaQuery.sizeOf(context).width <= 340
        ? 0.0
        : BatshSpacing.ml;
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: anchored ? 0 : BatshSpacing.xxs),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          inset,
          anchored ? 0 : BatshSpacing.xs,
          inset,
          0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelStyle = BatshTypography.labelSm.copyWith(
              fontFamily: fontFamily,
            );
            final width = (constraints.maxWidth / items.length - 8).clamp(
              1.0,
              double.infinity,
            );
            double labelHeight = 0;
            for (final item in items) {
              final painter = TextPainter(
                text: TextSpan(
                  text: item.label,
                  style: labelStyle.copyWith(fontWeight: FontWeight.w700),
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: width);
              if (painter.height > labelHeight) labelHeight = painter.height;
              painter.dispose();
            }
            final height = (24 + 4 + labelHeight + 16).clamp(
              64.0,
              double.infinity,
            );
            return DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor ?? colors.surfaceContainerLowest,
                borderRadius: anchored ? BorderRadius.zero : BatshRadius.brXl,
                border: Border.all(color: colors.outlineVariant),
                boxShadow: anchored ? null : BatshShadows.soft,
              ),
              child: SizedBox(
                height: height,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: Semantics(
                          selected: currentIndex == i,
                          button: true,
                          enabled: true,
                          label: items[i].label,
                          excludeSemantics: true,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(i);
                          },
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onTap(i);
                            },
                            style:
                                TextButton.styleFrom(
                                  foregroundColor: currentIndex == i
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(48, 48),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BatshRadius.brMd,
                                  ),
                                ).copyWith(
                                  overlayColor: WidgetStateProperty.resolveWith(
                                    (states) =>
                                        states.contains(WidgetState.focused)
                                        ? colors.primaryContainer
                                        : null,
                                  ),
                                ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: currentIndex == i
                                          ? colors.primaryContainer
                                          : Colors.transparent,
                                      borderRadius: BatshRadius.brFull,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Icon(
                                        currentIndex == i
                                            ? items[i].selectedIcon
                                            : items[i].icon,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    items[i].label,
                                    textAlign: TextAlign.center,
                                    style: labelStyle.copyWith(
                                      fontWeight: currentIndex == i
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
