import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../billing/presentation/paywall_sheet.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../domain/quote.dart';
import '../providers/quotes_providers.dart';
import '../quote_format.dart';
import '../quote_sheet.dart';
import 'quote_status_badge.dart';

/// Contractor-side CTA on a brief/post: "send a quote", or a summary card with
/// an edit action when a quote already exists.
class ContractorQuoteCta extends ConsumerWidget {
  const ContractorQuoteCta({super.key, required this.briefId});
  final String briefId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myQuoteForBriefProvider(briefId));
    // Lead-gate: only active-Pro contractors get the send-quote action; free
    // ones get the paywall CTA. The DB also rejects their inserts (RLS), so
    // this is UX, not the security boundary.
    final isPro = ref.watch(contractorProfileProvider).value?.isPro ?? false;
    Widget sendCta() => isPro
        ? BatshButton(
            label: S.sendQuote,
            icon: Icons.request_quote_outlined,
            onPressed: () => showQuoteSheet(context, briefId: briefId),
          )
        : BatshButton(
            label: S.upgradeToProShort,
            icon: Icons.workspace_premium_outlined,
            onPressed: () => showPaywallSheet(context),
          );

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
              Text(S.yourQuote,
                  style: BatshTypography.labelMd
                      .copyWith(color: BatshColors.onSurfaceVariant)),
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
                const Icon(Icons.schedule,
                    size: 16, color: BatshColors.onSurfaceVariant),
                const SizedBox(width: BatshSpacing.xs),
                Text(quote.durationText!,
                    style: BatshTypography.labelMd
                        .copyWith(color: BatshColors.onSurfaceVariant)),
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
                label: S.editQuote,
                icon: Icons.edit_outlined,
                style: BatshButtonStyle.ghost,
                fullWidth: false,
                onPressed: () => showQuoteSheet(context,
                    briefId: quote.briefId, existing: quote),
              ),
            ),
          ],
        ],
      ),
    );
  }
}