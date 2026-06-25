import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';

enum BatshButtonStyle { primary, secondary, ghost }

class BatshButton extends StatelessWidget {
  const BatshButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = BatshButtonStyle.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final BatshButtonStyle style;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: BatshSpacing.sm),
              ],
              Text(label),
            ],
          );

    final button = switch (style) {
      BatshButtonStyle.primary => ElevatedButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      BatshButtonStyle.secondary => OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: BatshColors.outline),
            shape:
                const RoundedRectangleBorder(borderRadius: BatshRadius.brDefault),
            minimumSize: const Size.fromHeight(BatshSpacing.minHitArea),
          ),
          child: child,
        ),
      BatshButtonStyle.ghost => TextButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
    };

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
