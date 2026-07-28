import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import 'batsh_button.dart';
import '../theme/batsh_icon_size.dart';
import '../theme/batsh_motion.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshError extends StatelessWidget {
  const BatshError({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);

    final icon = Semantics(
      label: context.l10n.errServerError,
      child: Icon(
        Icons.error_outline_rounded,
        color: context.colorScheme.error,
        size: BatshIconSize.xxl,
      ),
    );

    final animatedIcon = reduced
        ? icon
        : icon
              .animate()
              .shake(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: BatshMotion.springCelebrate,
              );

    return Semantics(
      label: message ?? context.l10n.errServerError,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(BatshSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              animatedIcon,
              const SizedBox(height: BatshSpacing.gutter),
              _AnimatedText(
                message: message ?? context.l10n.unknownErrorRetry,
                reduced: reduced,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: BatshSpacing.lg),
                _AnimatedButton(onRetry: onRetry, reduced: reduced),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedText extends StatelessWidget {
  const _AnimatedText({required this.message, required this.reduced});
  final String message;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final widget = Text(
      message,
      textAlign: TextAlign.center,
      style: BatshTypography.bodyLg,
    );
    if (reduced) return widget;
    return widget
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
          curve: BatshMotion.easeOut,
        );
  }
}

class _AnimatedButton extends StatelessWidget {
  const _AnimatedButton({required this.onRetry, required this.reduced});
  final VoidCallback? onRetry;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final widget = SizedBox(
      child: BatshButton(
        label: context.l10n.tryAgain,
        onPressed: onRetry,
        fullWidth: false,
      ),
    );
    if (reduced) return widget;
    return widget.animate().fadeIn(
      duration: 400.ms,
      delay: 150.ms,
      curve: BatshMotion.easeOut,
    );
  }
}
