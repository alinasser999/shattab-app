import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';

class BatshCard extends StatelessWidget {
  const BatshCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BatshSpacing.gutter),
    this.onTap,
    this.elevated = false,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool elevated;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? Border.all(color: BatshColors.primary, width: 2)
        : Border.all(color: BatshColors.outlineVariant, width: 1);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: border,
        boxShadow: elevated ? BatshShadows.raised : BatshShadows.soft,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BatshRadius.brLg,
      child: InkWell(
        borderRadius: BatshRadius.brLg,
        onTap: onTap,
        child: content,
      ),
    );
  }
}
