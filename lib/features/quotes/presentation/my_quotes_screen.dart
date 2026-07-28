import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_card.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/utils/error_mapper.dart';
import '../../briefs/domain/brief.dart';
import '../../briefs/presentation/widgets/completion_card.dart';
import '../domain/quote.dart';
import 'providers/quotes_providers.dart';
import 'quote_format.dart';
import 'quote_sheet.dart';
import 'widgets/quote_status_badge.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../../core/widgets/batsh_dialog.dart';
import '../../../core/theme/batsh_motion.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Contractor's own quotes across every brief — the one place a quote sent on
/// a public post stays trackable after the post leaves the opportunities feed.
class MyQuotesScreen extends ConsumerWidget {
  const MyQuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One request for the quotes *and* their briefs. Resolving the brief inside
    // the row builder made this N+1.
    final async = ref.watch(myQuotesWithBriefsProvider);
    return BatshScaffold(
      title: context.l10n.myQuotesTitle,
      body: async.when(
        loading: () => const BatshListSkeleton(count: 4),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(myQuotesWithBriefsProvider),
        ),
        data: (quotes) {
          if (quotes.isEmpty) {
            return BatshEmptyState(
              title: context.l10n.myQuotesEmptyTitle,
              message: context.l10n.myQuotesEmptyMessage,
              icon: Icons.request_quote_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myQuotesWithBriefsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(BatshSpacing.gutter),
              itemCount: quotes.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: BatshSpacing.md),
              itemBuilder: (context, i) =>
                  _QuoteRow(quote: quotes[i].quote, brief: quotes[i].brief)
                      .animate()
                      .fadeIn(delay: (60 * i.clamp(0, 8)).ms, duration: 260.ms)
                      .slideY(begin: 0.06, end: 0, curve: BatshMotion.easeOut),
            ),
          );
        },
      ),
    );
  }
}

/// Edit / withdraw for a quote you sent and that nobody has acted on yet.
///
/// "Withdraw" rather than "delete": the homeowner may already have read the
/// offer, and a quote that vanishes without a trace reads as a bug. The schema
/// already models this as `QuoteStatus.withdrawn`.
class _QuoteOwnerMenu extends ConsumerWidget {
  const _QuoteOwnerMenu({required this.quote});

  final Quote quote;

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final ok = await BatshDialog.confirm(
      context,
      title: context.l10n.withdrawQuoteTitle,
      message: context.l10n.withdrawQuoteBody,
      confirmLabel: context.l10n.withdrawQuote,
      cancelLabel: context.l10n.cancel,
      isDestructive: true,
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref
          .read(quotesControllerProvider.notifier)
          .setStatus(
            quoteId: quote.id,
            briefId: quote.briefId,
            status: QuoteStatus.withdrawn,
          );
      if (!context.mounted) return;
      BatshSnack.info(context, context.l10n.quoteWithdrawn);
    } catch (e) {
      if (!context.mounted) return;
      BatshSnack.error(context, ErrorMapper.map(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.editPost,
      icon: Icon(
        Icons.more_horiz_rounded,
        size: BatshIconSize.md,
        color: context.colorScheme.onSurfaceVariant,
      ),
      onSelected: (v) {
        if (v == 'edit') {
          // The quote sheet prefills from the existing quote and updates it.
          showQuoteSheet(context, briefId: quote.briefId);
        } else if (v == 'withdraw') {
          _withdraw(context, ref);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: BatshIconSize.md),
              const SizedBox(width: BatshSpacing.sm),
              Text(context.l10n.editQuote),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'withdraw',
          child: Row(
            children: [
              Icon(
                Icons.undo_rounded,
                size: BatshIconSize.md,
                color: context.colorScheme.error,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Text(
                context.l10n.withdrawQuote,
                style: TextStyle(color: context.colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuoteRow extends ConsumerWidget {
  const _QuoteRow({required this.quote, this.brief});
  final Quote quote;

  /// The quote's brief, embedded by the same query that fetched the quote.
  /// Null when RLS hides it — cancelled, or filtered out server-side.
  final Brief? brief;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Best-effort title; falls back to a generic label when the brief is gone.
    final title = brief?.workDescription ?? context.l10n.postDetailTitle;
    // Only the winning quote gets the completion step; the others have no work
    // to finish.
    final completionBrief = quote.status == QuoteStatus.accepted ? brief : null;
    return BatshCard(
      onTap: () => context.push(Routes.contractorPostDetailPath(quote.briefId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: BatshTypography.titleLg.copyWith(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              QuoteStatusBadge(status: quote.status),
              // Only a live offer can be pulled back. Accepted quotes are
              // locked by the lock_accepted_quote trigger (migration 0009), and
              // declined or withdrawn ones have nowhere left to go.
              if (quote.status == QuoteStatus.sent)
                _QuoteOwnerMenu(quote: quote),
            ],
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            quotePriceLabel(quote),
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
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
          Text(
            quote.note,
            style: BatshTypography.bodyMd,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (completionBrief != null && completionBrief.isHired) ...[
            const SizedBox(height: BatshSpacing.md),
            CompletionCard(
              brief: completionBrief,
              role: CompletionRole.contractor,
            ),
          ],
        ],
      ),
    );
  }
}
