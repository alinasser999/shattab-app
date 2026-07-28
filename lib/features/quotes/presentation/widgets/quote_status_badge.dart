import 'package:flutter/material.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../domain/quote.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/theme_extension.dart';

/// Small colored pill describing a quote's status. Pass [status] null for the
/// "needs a reply" (no quote yet) state used in the contractor inbox.
class QuoteStatusBadge extends StatelessWidget {
  const QuoteStatusBadge({super.key, this.status});

  final QuoteStatus? status;

  ({Color fg, Color bg, String label, IconData icon}) _spec(
    BuildContext context,
  ) {
    switch (status) {
      case null:
        return (
          fg: context.colorScheme.primary,
          bg: context.colorScheme.primaryFixed,
          label: context.l10n.noQuoteBadge,
          icon: Icons.mark_email_unread_outlined,
        );
      case QuoteStatus.sent:
        return (
          fg: context.colorScheme.onTertiaryContainer,
          bg: context.colorScheme.tertiaryContainer,
          label: context.l10n.quoteStatusSent,
          icon: Icons.schedule,
        );
      case QuoteStatus.accepted:
        return (
          fg: context.colorScheme.onSuccess,
          bg: context.colorScheme.success,
          label: context.l10n.quoteStatusAccepted,
          icon: Icons.check_circle,
        );
      case QuoteStatus.declined:
        return (
          fg: context.colorScheme.error,
          bg: context.colorScheme.errorContainer,
          label: context.l10n.quoteStatusDeclined,
          icon: Icons.cancel_outlined,
        );
      case QuoteStatus.withdrawn:
        return (
          fg: context.colorScheme.onSurfaceVariant,
          bg: context.colorScheme.surfaceContainerHigh,
          label: context.l10n.quoteStatusWithdrawn,
          icon: Icons.undo,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _spec(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: BatshSpacing.xs,
      ),
      decoration: BoxDecoration(color: s.bg, borderRadius: BatshRadius.brFull),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: BatshIconSize.sm, color: s.fg),
          const SizedBox(width: BatshSpacing.xs),
          Text(
            s.label,
            style: BatshTypography.labelSm.copyWith(
              color: s.fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
