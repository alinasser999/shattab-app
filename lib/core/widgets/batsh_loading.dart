import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshLoading extends StatelessWidget {
  const BatshLoading({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.loading,
    liveRegion: true,
    excludeSemantics: true,
    child: Center(
      child: SizedBox(
        height: size,
        width: size,
        child: MediaQuery.disableAnimationsOf(context)
            ? Icon(
                Icons.hourglass_top_rounded,
                color: context.colorScheme.primary,
                size: size,
              )
            : CircularProgressIndicator(
                color: context.colorScheme.primary,
                strokeWidth: 2.5,
              ),
      ),
    ),
  );
}
