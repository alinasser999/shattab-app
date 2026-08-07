import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../billing/presentation/paywall_sheet.dart';
import '../../domain/quote.dart';
import '../providers/quotes_providers.dart';
import '../quote_format.dart';
import '../quote_sheet.dart';
import 'quote_status_badge.dart';
import '../../../../core/theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Contractor-side CTA on a brief/post: "send a quote", or a summary card with
/// an edit action when a quote already exists.
class ContractorQuoteCta extends ConsumerWidget {
  const ContractorQuoteCta({super.key, required this.briefId});
  final String briefId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myQuoteForBriefProvider(briefId));
    // Free contractors can quote up to a monthly cap (0025); only a spent quota
    // shows the paywall. The same rule is enforced in RLS — this is UX, not the
    // security boundary. While the quota is still loading, assume the quote can
    // be sent: briefly flashing the paywall at a paying contractor is worse
    // than a rejected insert, which the sheet already reports.
    final quota = ref.watch(myQuoteQuotaProvider).value;
    final remaining = quota == null
        ? null
        : (quota.quota - quota.used).clamp(0, 9999);
    final canSend = quota == null || quota.isPro || remaining! > 0;

    Widget sendCta() {
      if (!canSend) {
        return BatshButton(
          label: context.l10n.upgradeToProShort,
          icon: Icons.workspace_premium_outlined,
          onPressed: () => showPaywallSheet(context),
        );
      }
      final button = BatshButton(
        label: context.l10n.sendQuote,
        icon: Icons.request_quote_outlined,
        onPressed: () => showQuoteSheet(context, briefId: briefId),
      );
      // Only free contractors see a counter.
      if (quota == null || quota.isPro) return button;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          button,
          const SizedBox(height: BatshSpacing.xs),
          Text(
            context.l10n.quotesLeftThisMonth(remaining!),
            textAlign: TextAlign.center,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return async.when(
      loading: () => const BatshShimmerBox(
        height: BatshSpacing.minHitArea,
        width: double.infinity,
      ),
      error: (_, _) => sendCta(),
      data: (quote) =>
          quote == null ? sendCta() : _CurrentQuoteCard(quote: quote),
    );
  }
}

class _CurrentQuoteCard extends StatelessWidget {
  const _CurrentQuoteCard({required this.quote});
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    return BatshCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.yourQuote,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              QuoteStatusBadge(status: quote.status),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          Text(quotePriceLabel(quote), style: BatshTypography.titleLg),
          if (quote.durationText != null) ...[
            const SizedBox(height: BatshSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: BatshIconSize.sm,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: BatshSpacing.xs),
                Text(
                  quote.durationText!,
                  style: BatshTypography.labelMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: BatshSpacing.sm),
          Text(quote.note, style: BatshTypography.bodyMd),
          // An accepted quote is a struck deal — editing it would silently
          // reset it to pending, so the edit affordance is withheld.
          if (quote.status != QuoteStatus.accepted) ...[
            const SizedBox(height: BatshSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: BatshButton(
                label: context.l10n.editQuote,
                icon: Icons.edit_outlined,
                style: BatshButtonStyle.ghost,
                fullWidth: false,
                onPressed: () => showQuoteSheet(
                  context,
                  briefId: quote.briefId,
                  existing: quote,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
