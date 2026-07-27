import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import 'batsh_button.dart';
import '../theme/batsh_icon_size.dart';

class BatshError extends StatelessWidget {
  const BatshError({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);

    final icon = Semantics(
      label: S.errServerError,
      child: const Icon(
        Icons.error_outline_rounded,
        color: BatshColors.error,
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
                curve: Curves.elasticOut,
              );

    return Semantics(
      label: message ?? S.errServerError,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(BatshSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              animatedIcon,
              const SizedBox(height: BatshSpacing.gutter),
              _AnimatedText(
                message: message ?? S.unknownErrorRetry,
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
        .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
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
        label: S.tryAgain,
        onPressed: onRetry,
        fullWidth: false,
      ),
    );
    if (reduced) return widget;
    return widget.animate().fadeIn(
      duration: 400.ms,
      delay: 150.ms,
      curve: Curves.easeOut,
    );
  }
}
