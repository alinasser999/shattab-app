import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: BatshColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative top-left shape
            IgnorePointer(child: _animatedCircle(reduced)),
            const SizedBox(height: 24),
            // Brand name with dramatic entrance
            _animatedBrand(reduced),
            const SizedBox(height: 8),
            // Tagline
            _animatedTagline(reduced),
            const SizedBox(height: 48),
            // Loading indicator with delayed entrance
            _animatedLoader(reduced),
            const SizedBox(height: 24),
            // Decorative dots
            _animatedDots(reduced),
          ],
        ),
      ),
    );
  }

  Widget _animatedCircle(bool reduced) {
    final circle = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BatshColors.primaryFixed.withValues(alpha: 0.15),
      ),
    );
    if (reduced) return circle;
    return circle
        .animate()
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .slide(
          begin: const Offset(-1, -1),
          end: Offset.zero,
          duration: 1000.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _animatedBrand(bool reduced) {
    final brand = Text(
      S.appName,
      style: BatshTypography.displayLg.copyWith(
        color: BatshColors.primary,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
    );
    if (reduced) return brand;
    return brand
        .animate()
        .fadeIn(duration: 700.ms, curve: Curves.easeOut)
        .slideY(
          begin: -0.2,
          end: 0,
          duration: 800.ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          duration: 800.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _animatedTagline(bool reduced) {
    final tagline = Text(
      S.taglineNew,
      style: BatshTypography.bodyMd.copyWith(
        color: BatshColors.onSurfaceVariant,
      ),
    );
    if (reduced) return tagline;
    return tagline
        .animate()
        .fadeIn(duration: 500.ms, delay: 400.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 500.ms,
          delay: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _animatedLoader(bool reduced) {
    final loader = SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        color: BatshColors.primary.withValues(alpha: 0.6),
        strokeWidth: 2.5,
      ),
    );
    if (reduced) return loader;
    return loader
        .animate()
        .fadeIn(duration: 400.ms, delay: 600.ms, curve: Curves.easeOut)
        .shimmer(
          duration: 1200.ms,
          delay: 600.ms,
          color: BatshColors.primaryContainer,
        );
  }

  Widget _animatedDots(bool reduced) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final dot = Container(
          width: 6,
          height: 6,
          margin: EdgeInsetsDirectional.only(start: i < 2 ? 8 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == 1
                ? BatshColors.primary
                : BatshColors.primary.withValues(alpha: 0.3),
          ),
        );
        if (reduced) return dot;
        return dot
            .animate()
            .fadeIn(
              duration: 300.ms,
              delay: (800 + i * 150).ms,
              curve: Curves.easeOut,
            )
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 300.ms,
              delay: (800 + i * 150).ms,
              curve: Curves.easeOutBack,
            );
      }),
    );
  }
}
