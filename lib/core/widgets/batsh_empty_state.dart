import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

class BatshEmptyState extends StatelessWidget {
  const BatshEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;

    final iconWidget = ExcludeSemantics(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: BatshColors.primaryFixed.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: BatshColors.primary.withValues(alpha: 0.6), size: 48),
      ),
    );

    final animatedIcon = reduced
        ? iconWidget
        : iconWidget
            .animate()
            .fadeIn(duration: 350.ms, curve: Curves.easeOut)
            .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack);

    final titleWidget = Text(
      title,
      textAlign: TextAlign.center,
      style: BatshTypography.titleLg.copyWith(color: BatshColors.onSurface),
    );

    final animatedTitle = reduced
        ? titleWidget
        : titleWidget
            .animate(delay: 100.ms)
            .fadeIn(duration: 350.ms, curve: Curves.easeOut)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);

    Widget? animatedMessage;
    if (message != null) {
      final messageWidget = Padding(
        padding: const EdgeInsets.only(top: BatshSpacing.sm),
        child: SizedBox(
          width: 280,
          child: Text(
            message!,
            textAlign: TextAlign.center,
            style: BatshTypography.bodyMd
                .copyWith(color: BatshColors.onSurfaceVariant),
          ),
        ),
      );
      animatedMessage = reduced
          ? messageWidget
          : messageWidget
              .animate(delay: 200.ms)
              .fadeIn(duration: 350.ms, curve: Curves.easeOut)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
    }

    Widget? animatedAction;
    if (action != null) {
      final actionWidget = Padding(
        padding: const EdgeInsets.only(top: BatshSpacing.lg),
        child: SizedBox(width: double.infinity, child: action),
      );
      animatedAction = reduced
          ? actionWidget
          : actionWidget
              .animate(delay: 300.ms)
              .fadeIn(duration: 350.ms, curve: Curves.easeOut)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
    }

    return Semantics(
      label: '$title ${message ?? ''}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(BatshSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              animatedIcon,
              const SizedBox(height: BatshSpacing.gutter),
              animatedTitle,
              ?animatedMessage,
              ?animatedAction,
            ],
          ),
        ),
      ),
    );
  }
}
