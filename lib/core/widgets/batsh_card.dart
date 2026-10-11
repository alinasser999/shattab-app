import 'package:flutter/material.dart';

import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import 'batsh_pressable.dart';

class BatshCard extends StatelessWidget {
  const BatshCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BatshSpacing.gutter),
    this.onTap,
    this.elevated = false,
    this.selected = false,
    this.highlightColor,
    this.primary = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool elevated;
  final bool selected;
  final Color? highlightColor;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color:
            highlightColor ??
            (primary || selected
                ? colors.primaryContainer
                : colors.surfaceContainerLowest),
        borderRadius: BatshRadius.brCard,
        border: Border.all(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
        boxShadow: elevated ? BatshShadows.elevated : null,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Semantics(
      selected: selected,
      child: BatshPressable(onTap: onTap, child: content),
    );
  }
}
