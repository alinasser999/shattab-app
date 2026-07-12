import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../domain/quote.dart';

/// Small colored pill describing a quote's status. Pass [status] null for the
/// "needs a reply" (no quote yet) state used in the contractor inbox.
class QuoteStatusBadge extends StatelessWidget {
  const QuoteStatusBadge({super.key, this.status});

  final QuoteStatus? status;

  ({Color fg, Color bg, String label, IconData icon}) _spec() {
    switch (status) {
      case null:
        return (
          fg: BatshColors.primary,
          bg: BatshColors.primaryFixed,
          label: S.noQuoteBadge,
          icon: Icons.mark_email_unread_outlined,
        );
      case QuoteStatus.sent:
        return (
          fg: BatshColors.onTertiaryContainer,
          bg: BatshColors.tertiaryContainer,
          label: S.quoteStatusSent,
          icon: Icons.schedule,
        );
      case QuoteStatus.accepted:
        return (
          fg: BatshColors.onSuccess,
          bg: BatshColors.success,
          label: S.quoteStatusAccepted,
          icon: Icons.check_circle,
        );
      case QuoteStatus.declined:
        return (
          fg: BatshColors.error,
          bg: BatshColors.errorContainer,
          label: S.quoteStatusDeclined,
          icon: Icons.cancel_outlined,
        );
      case QuoteStatus.withdrawn:
        return (
          fg: BatshColors.onSurfaceVariant,
          bg: BatshColors.surfaceContainerHigh,
          label: S.quoteStatusWithdrawn,
          icon: Icons.undo,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _spec();
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm, vertical: BatshSpacing.xs),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BatshRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 14, color: s.fg),
          const SizedBox(width: BatshSpacing.xs),
          Text(s.label,
              style: BatshTypography.labelSm
                  .copyWith(color: s.fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}