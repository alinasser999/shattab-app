import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

class BatshChip extends StatelessWidget {
  const BatshChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? BatshColors.primaryFixed
          : BatshColors.surfaceContainer,
      borderRadius: BatshRadius.brFull,
      child: InkWell(
        borderRadius: BatshRadius.brFull,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.gutter,
            vertical: BatshSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BatshRadius.brFull,
            border: Border.all(
              color: selected
                  ? BatshColors.primary
                  : BatshColors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: BatshTypography.labelMd.copyWith(
              color: selected ? BatshColors.primary : BatshColors.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
