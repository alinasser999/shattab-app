import 'package:flutter/material.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:batsh/core/theme/batsh_icon_size.dart';
import 'package:batsh/core/theme/batsh_spacing.dart';
import 'package:batsh/core/theme/batsh_typography.dart';
import 'package:batsh/core/theme/theme_extension.dart';
import 'package:batsh/features/discovery/domain/trust_signals.dart';

class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key, required this.profile});

  final TrustProfile profile;

  @override
  Widget build(BuildContext context) {
    final signals = <({IconData icon, String label})>[
      if (profile.verification != VerificationLevel.none)
        (
          icon: Icons.verified_user_outlined,
          label: context.l10n.verifiedIdentity,
        ),
      for (final metric in profile.metrics)
        (
          icon: switch (metric.kind) {
            TrustSignalKind.projectsCompleted => Icons.home_work_outlined,
            TrustSignalKind.yearsExperience => Icons.work_history_outlined,
          },
          label: metric.semanticLabel,
        ),
    ];

    if (signals.isEmpty) return const SizedBox.shrink();

    // Show identity plus one measurable outcome when possible. The profile
    // page owns the full explanation; the catalogue only needs enough honest
    // evidence to support the next decision.
    final visible = signals.take(2).toList();
    return Semantics(
      container: true,
      label: visible.map((signal) => signal.label).join('، '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final signal in visible)
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  Icon(
                    signal.icon,
                    size: BatshIconSize.sm,
                    color: context.colorScheme.secondary,
                  ),
                  const SizedBox(width: BatshSpacing.xxs),
                  Expanded(
                    child: Text(
                      signal.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
