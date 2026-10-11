import 'package:flutter/material.dart';

import '../theme/batsh_icon_size.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshChip extends StatelessWidget {
  const BatshChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.compact = false,
    this.minimumHitHeight = false,
    this.singleSelection = false,
    this.showSelectionMark = false,
    this.semanticLabel,
  });
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;
  final bool minimumHitHeight;
  final bool singleSelection;
  final bool showSelectionMark;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: BatshIconSize.sm),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: (compact ? BatshTypography.labelSm : BatshTypography.labelMd)
                .copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
          ),
        ),
        if (selected && (showSelectionMark || onTap != null)) ...[
          const SizedBox(width: BatshSpacing.xs),
          Icon(Icons.check_rounded, size: BatshIconSize.sm),
        ],
      ],
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BatshRadius.brFull,
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
      ),
    );
    if (onTap == null) {
      return AnimatedContainer(
        duration: Duration.zero,
        padding: EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surfaceContainer,
          borderRadius: BatshRadius.brFull,
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: content,
      );
    }
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: singleSelection,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
          backgroundColor: selected
              ? colors.primaryContainer
              : colors.surfaceContainer,
          minimumSize: const Size(48, 48),
          shape: shape,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? BatshSpacing.sm : BatshSpacing.md,
            vertical: BatshSpacing.sm,
          ),
        ),
        child: Semantics(
          label: semanticLabel ?? label,
          excludeSemantics: true,
          child: content,
        ),
      ),
    );
  }
}
