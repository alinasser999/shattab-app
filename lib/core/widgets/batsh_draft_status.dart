import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/theme_extension.dart';

class BatshDraftStatus extends StatelessWidget {
  const BatshDraftStatus({super.key, required this.restored});

  final bool restored;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(
            restored ? Icons.history_rounded : Icons.cloud_done_outlined,
            size: 18,
            color: context.colorScheme.secondary,
          ),
          const SizedBox(width: BatshSpacing.xxs),
          Expanded(
            child: Text(
              restored
                  ? context.l10n.draftRestored
                  : context.l10n.draftSavedAutomatically,
              style: BatshTypography.labelMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
