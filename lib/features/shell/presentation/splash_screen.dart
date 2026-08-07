import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/batsh_motion.dart';

import 'package:batsh/core/theme/theme_extension.dart';

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
      backgroundColor: context.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use the approved wordmark instead of redrawing the logo as text.
            _animatedBrand(reduced),
            const SizedBox(height: 8),
            // Tagline
            _animatedTagline(reduced),
            const SizedBox(height: 48),
            // Loading indicator with delayed entrance
            _animatedLoader(reduced),
          ],
        ),
      ),
    );
  }

  Widget _animatedBrand(bool reduced) {
    final brand = SizedBox(
      width: 220,
      height: 112,
      child: Image.asset(
        'assets/icon/app_icon_foreground.png',
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        semanticLabel: context.l10n.appName,
      ),
    );
    if (reduced) return brand;
    return brand
        .animate()
        .fadeIn(duration: 700.ms, curve: BatshMotion.easeOut)
        .slideY(
          begin: -0.2,
          end: 0,
          duration: 800.ms,
          curve: BatshMotion.easeOut,
        )
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          duration: 800.ms,
          curve: BatshMotion.easeOut,
        );
  }

  Widget _animatedTagline(bool reduced) {
    final tagline = Text(
      context.l10n.taglineNew,
      style: BatshTypography.bodyMd.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
    if (reduced) return tagline;
    return tagline
        .animate()
        .fadeIn(duration: 500.ms, delay: 400.ms, curve: BatshMotion.easeOut)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 500.ms,
          delay: 400.ms,
          curve: BatshMotion.easeOut,
        );
  }

  Widget _animatedLoader(bool reduced) {
    final loader = SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        color: context.colorScheme.primary.withValues(alpha: 0.6),
        strokeWidth: 2.5,
      ),
    );
    if (reduced) return loader;
    return loader
        .animate()
        .fadeIn(duration: 400.ms, delay: 600.ms, curve: BatshMotion.easeOut)
        .shimmer(
          duration: 1200.ms,
          delay: 600.ms,
          color: context.colorScheme.primaryContainer,
        );
  }
}
