import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';

class BatshLoading extends StatelessWidget {
  const BatshLoading({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.loading,
      liveRegion: true,
      child: Center(
      child: SizedBox(
        height: size,
        width: size,
        child: const CircularProgressIndicator(
          color: BatshColors.primary,
          strokeWidth: 3,
        ),
      ).animate().fadeIn(
            duration: 300.ms,
            curve: Curves.easeOut,
          ).shimmer(
            duration: 1500.ms,
            color: BatshColors.primaryContainer,
          ),
    ));
  }
}
