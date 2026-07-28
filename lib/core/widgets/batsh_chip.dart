import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_motion.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshChip extends StatefulWidget {
  const BatshChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<BatshChip> createState() => _BatshChipState();
}

class _BatshChipState extends State<BatshChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: BatshMotion.fast, vsync: this);
    if (widget.selected) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(BatshChip old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final t = _controller.value;
          return Transform.scale(scale: 0.92 + (t * 0.08), child: child);
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: BatshMotion.fast,
            curve: BatshMotion.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? BatshSpacing.sm : BatshSpacing.md,
              vertical: widget.compact ? BatshSpacing.xs : BatshSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: widget.selected
                  ? context.colorScheme.primaryFixed
                  : context.colorScheme.surfaceContainer,
              borderRadius: BatshRadius.brFull,
              border: Border.all(
                color: widget.selected
                    ? context.colorScheme.primary
                    : context.colorScheme.outlineVariant.withValues(alpha: 0.6),
                width: widget.selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: widget.compact ? 14 : 16,
                    color: widget.selected
                        ? context.colorScheme.primary
                        : context.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                  ),
                  SizedBox(width: widget.compact ? 4 : 6),
                ],
                Text(
                  widget.label,
                  style:
                      (widget.compact
                              ? BatshTypography.labelSm
                              : BatshTypography.labelMd)
                          .copyWith(
                            color: widget.selected
                                ? context.colorScheme.primary
                                : context.colorScheme.onSurfaceVariant,
                            fontWeight: widget.selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
