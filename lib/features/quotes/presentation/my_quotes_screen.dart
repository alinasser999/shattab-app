import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
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
import '../../briefs/presentation/providers/briefs_providers.dart';
import '../domain/quote.dart';
import 'providers/quotes_providers.dart';
import 'quote_format.dart';
import 'widgets/quote_status_badge.dart';

/// Contractor's own quotes across every brief — the one place a quote sent on
/// a public post stays trackable after the post leaves the opportunities feed.
class MyQuotesScreen extends ConsumerWidget {
  const MyQuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myQuotesProvider);
    return BatshScaffold(
      title: S.myQuotesTitle,
      body: async.when(
        loading: () => const BatshListSkeleton(count: 4),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(myQuotesProvider),
        ),
        data: (quotes) {
          if (quotes.isEmpty) {
            return BatshEmptyState(
              title: S.myQuotesEmptyTitle,
              message: S.myQuotesEmptyMessage,
              icon: Icons.request_quote_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myQuotesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(BatshSpacing.gutter),
              itemCount: quotes.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: BatshSpacing.md),
              itemBuilder: (context, i) => _QuoteRow(quote: quotes[i])
                  .animate()
                  .fadeIn(delay: (60 * i.clamp(0, 8)).ms, duration: 260.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ),
          );
        },
      ),
    );
  }
}

class _QuoteRow extends ConsumerWidget {
  const _QuoteRow({required this.quote});
  final Quote quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Best-effort brief title; falls back to a generic label if the brief is
    // no longer readable (cancelled, or filtered out server-side).
    final title = ref.watch(briefByIdProvider(quote.briefId)).maybeWhen(
          data: (b) => b?.workDescription ?? S.postDetailTitle,
          orElse: () => S.postDetailTitle,
        );
    return BatshCard(
      onTap: () =>
          context.push(Routes.contractorPostDetailPath(quote.briefId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title,
                    style: BatshTypography.titleLg.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: BatshSpacing.sm),
              QuoteStatusBadge(status: quote.status),
            ],
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(quotePriceLabel(quote),
              style: BatshTypography.labelMd.copyWith(
                  color: BatshColors.primary, fontWeight: FontWeight.w700)),
          if (quote.durationText != null) ...[
            const SizedBox(height: BatshSpacing.xs),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 15, color: BatshColors.onSurfaceVariant),
                const SizedBox(width: BatshSpacing.xs),
                Text(quote.durationText!,
                    style: BatshTypography.labelMd
                        .copyWith(color: BatshColors.onSurfaceVariant)),
              ],
            ),
          ],
          const SizedBox(height: BatshSpacing.sm),
          Text(quote.note,
              style: BatshTypography.bodyMd,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
