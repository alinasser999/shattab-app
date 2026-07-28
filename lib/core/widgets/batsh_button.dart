import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_motion.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';

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
    this.hapticOnPress = true,
    this.animate = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final BatshButtonStyle style;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final bool hapticOnPress;
  final bool animate;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: switch (style) {
                BatshButtonStyle.primary => context.colorScheme.onPrimary,
                BatshButtonStyle.secondary => context.colorScheme.primary,
                BatshButtonStyle.ghost => context.colorScheme.onSurfaceVariant,
              },
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: BatshIconSize.md),
                const SizedBox(width: BatshSpacing.sm),
              ],
              Text(
                label,
                style: BatshTypography.labelLg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );

    Widget button = switch (style) {
      BatshButtonStyle.primary => ElevatedButton(
        onPressed: disabled
            ? null
            : () {
                if (hapticOnPress) HapticFeedback.lightImpact();
                onPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? context.colorScheme.primary,
          foregroundColor: foregroundColor ?? context.colorScheme.onPrimary,
          disabledBackgroundColor: context.colorScheme.surfaceContainerHigh,
          disabledForegroundColor: context.colorScheme.onSurfaceVariant,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.lg,
            vertical: BatshSpacing.gutter,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BatshRadius.brDefault),
        ),
        child: child,
      ),
      BatshButtonStyle.secondary => OutlinedButton(
        onPressed: disabled
            ? null
            : () {
                if (hapticOnPress) HapticFeedback.lightImpact();
                onPressed?.call();
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? context.colorScheme.primary,
          backgroundColor: backgroundColor,
          side: BorderSide(
            color: context.colorScheme.outline.withValues(alpha: 0.5),
            width: 1.5,
          ),
          disabledBackgroundColor: context.colorScheme.surfaceContainerHigh,
          disabledForegroundColor: context.colorScheme.onSurfaceVariant,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.lg,
            vertical: BatshSpacing.gutter,
          ),
          shape: RoundedRectangleBorder(borderRadius: BatshRadius.brDefault),
        ),
        child: child,
      ),
      BatshButtonStyle.ghost => TextButton(
        onPressed: disabled
            ? null
            : () {
                if (hapticOnPress) HapticFeedback.lightImpact();
                onPressed?.call();
              },
        style: TextButton.styleFrom(
          foregroundColor:
              foregroundColor ?? context.colorScheme.onSurfaceVariant,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.gutter,
            vertical: BatshSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: BatshRadius.brDefault),
        ),
        child: child,
      ),
    };

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    if (animate && !MediaQuery.disableAnimationsOf(context)) {
      button = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1.0),
        duration: BatshMotion.normal,
        curve: BatshMotion.easeOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: button,
      );
    }

    return Semantics(button: true, label: label, child: button);
  }
}
