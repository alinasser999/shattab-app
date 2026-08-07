import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/batsh_motion.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshLoading extends StatelessWidget {
  const BatshLoading({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loading,
      liveRegion: true,
      child: Center(
        child:
            SizedBox(
                  height: size,
                  width: size,
                  child: CircularProgressIndicator(
                    color: context.colorScheme.primary,
                    strokeWidth: 3,
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms, curve: BatshMotion.easeOut)
                .shimmer(
                  duration: 1500.ms,
                  color: context.colorScheme.primaryContainer,
                ),
      ),
    );
  }
}
