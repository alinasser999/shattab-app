import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_stars.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../briefs/presentation/providers/briefs_providers.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../../reviews/presentation/providers/reviews_providers.dart';
import '../../../reviews/presentation/write_review_sheet.dart';
import '../../domain/quote.dart';
import '../providers/quotes_providers.dart';
import '../quote_format.dart';
import 'quote_status_badge.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/widgets/batsh_snack.dart';

/// Homeowner-side section listing every quote received on a brief, with
/// accept/decline actions and contact shortcuts once accepted.
class QuotesReceivedSection extends ConsumerWidget {
  const QuotesReceivedSection({
    super.key,
    required this.briefId,
    this.canAct = true,
  });
  final String briefId;

  /// Whether accept/decline is still allowed (false once the brief is hired or
  /// cancelled — the offers become read-only history).
  final bool canAct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(quotesForBriefProvider(briefId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(S.quotesSectionTitle, style: BatshTypography.titleLg),
            const SizedBox(width: BatshSpacing.sm),
            async.maybeWhen(
              data: (q) =>
                  q.isEmpty ? const SizedBox.shrink() : _CountChip(count: q.length),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.md),
        async.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: BatshSpacing.lg),
            child: Column(
              children: [
                _QuoteSkeletonCard(),
                const SizedBox(height: BatshSpacing.md),
                _QuoteSkeletonCard(),
              ],
            ),
          ),
          error: (e, _) => BatshError(
                message: ErrorMapper.map(e),
                onRetry: () =>
                    ref.invalidate(quotesForBriefProvider(briefId)),
              ),
          data: (quotes) {
            if (quotes.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(quotesForBriefProvider(briefId)),
                child: ListView(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Text(S.noQuotesYet,
                        style: BatshTypography.bodyMd.copyWith(
                            color: BatshColors.onSurfaceVariant)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(quotesForBriefProvider(briefId)),
              child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < quotes.length; i++)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: BatshSpacing.md),
                      child: _animatedQuoteCard(
                          _QuoteCard(
                              quote: quotes[i],
                              briefId: briefId,
                              canAct: canAct),
                          i),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

Widget _animatedQuoteCard(Widget card, int index) {
  return Builder(
    builder: (context) {
      if (MediaQuery.of(context).disableAnimations) return card;
      return card
          .animate()
          .fadeIn(
              delay: (80 * index.clamp(0, 6)).ms,
              duration: 280.ms)
          .slideY(
              begin: 0.08,
              end: 0,
              curve: Curves.easeOutCubic);
    },
  );
}

class _QuoteSkeletonCard extends StatelessWidget {
  const _QuoteSkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BatshShimmerBox(width: 44, height: 44, borderRadius: BatshRadius.brFull),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BatshShimmerBox(width: 140, height: 16, borderRadius: BatshRadius.brSm),
                  const SizedBox(height: 4),
                  BatshShimmerBox(width: 80, height: 14, borderRadius: BatshRadius.brSm),
                ],
              ),
            ),
            BatshShimmerBox(width: 60, height: 24, borderRadius: BatshRadius.brFull),
          ],
        ),
        const SizedBox(height: BatshSpacing.md),
        BatshShimmerBox(width: double.infinity, height: 14, borderRadius: BatshRadius.brSm),
        const SizedBox(height: BatshSpacing.md),
        Row(
          children: [
            Expanded(child: BatshShimmerBox(width: double.infinity, height: 44, borderRadius: BatshRadius.brMd)),
            const SizedBox(width: BatshSpacing.md),
            Expanded(child: BatshShimmerBox(width: double.infinity, height: 44, borderRadius: BatshRadius.brMd)),
          ],
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: BatshColors.primaryFixed,
        borderRadius: BatshRadius.brFull,
      ),
      child: Text('$count',
          style: BatshTypography.labelSm.copyWith(
              color: BatshColors.primary, fontWeight: FontWeight.w700)),
    );
  }
}

class _QuoteCard extends ConsumerWidget {
  const _QuoteCard(
      {required this.quote, required this.briefId, this.canAct = true});
  final Quote quote;
  final String briefId;
  final bool canAct;

  Future<void> _confirmAndSet(
      BuildContext context, WidgetRef ref, QuoteStatus status) async {
    final ok = await showDialog<bool>(
      context: context,
      // Pop with the dialog's own context: the card's context resolves to the
      // shell branch navigator and would pop the screen, not the dialog.
      builder: (ctx) => AlertDialog(
        title: Text(status == QuoteStatus.accepted
            ? S.quoteAcceptConfirm
            : S.quoteDeclineConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(S.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(S.confirm)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(quotesControllerProvider.notifier).setStatus(
          quoteId: quote.id, briefId: briefId, status: status);
      if (status == QuoteStatus.accepted) HapticFeedback.mediumImpact();
    } catch (_) {
      if (context.mounted) {
        BatshSnack.error(context, S.unknownErrorRetry);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractor =
        ref.watch(contractorByIdProvider(quote.contractorId)).value;
    final name = contractor == null
        ? '...'
        : (contractor.businessName.isNotEmpty
            ? contractor.businessName
            : contractor.fullName);
    return BatshCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(url: contractor?.logoUrl),
              const SizedBox(width: BatshSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: BatshTypography.titleLg.copyWith(fontSize: 17),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(quotePriceLabel(quote),
                        style: BatshTypography.labelMd.copyWith(
                            color: BatshColors.primary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              QuoteStatusBadge(status: quote.status),
            ],
          ),
          if (quote.durationText != null) ...[
            const SizedBox(height: BatshSpacing.md),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: BatshIconSize.sm, color: BatshColors.onSurfaceVariant),
                const SizedBox(width: BatshSpacing.xs),
                Text(quote.durationText!,
                    style: BatshTypography.labelMd
                        .copyWith(color: BatshColors.onSurfaceVariant)),
              ],
            ),
          ],
          const SizedBox(height: BatshSpacing.sm),
          Text(quote.note, style: BatshTypography.bodyMd),
          const SizedBox(height: BatshSpacing.md),
          if (quote.status == QuoteStatus.sent && canAct)
            Row(
              children: [
                Expanded(
                  child: BatshButton(
                    label: S.quoteAccept,
                    icon: Icons.check,
                    style: BatshButtonStyle.primary,
                    backgroundColor: BatshColors.success,
                    onPressed: () =>
                        _confirmAndSet(context, ref, QuoteStatus.accepted),
                  ),
                ),
                const SizedBox(width: BatshSpacing.md),
                Expanded(
                  child: BatshButton(
                    label: S.quoteDecline,
                    style: BatshButtonStyle.ghost,
                    foregroundColor: BatshColors.error,
                    onPressed: () =>
                        _confirmAndSet(context, ref, QuoteStatus.declined),
                  ),
                ),
              ],
            ),
          if (quote.status == QuoteStatus.accepted &&
              contractor != null &&
              contractor.phone.isNotEmpty) ...[
            WhatsAppButton(phone: contractor.phone),
            const SizedBox(height: BatshSpacing.sm),
            CallButton(phone: contractor.phone),
          ],
          if (quote.status == QuoteStatus.accepted)
            _ReviewBlock(briefId: briefId, contractorId: quote.contractorId),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => context.push(
                  Routes.homeownerContractorProfilePath(quote.contractorId)),
              icon: const Icon(Icons.person_outline, size: BatshIconSize.md),
              label: Text(S.viewContractorProfile),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainer,
        shape: BoxShape.circle,
        image: hasUrl
            ? DecorationImage(
                image: CachedNetworkImageProvider(url!), fit: BoxFit.cover)
            : null,
      ),
      child: hasUrl
          ? null
          : const Icon(Icons.handyman_outlined,
              color: BatshColors.onSurfaceVariant, size: BatshIconSize.md),
    );
  }
}

/// Rate-the-contractor affordance, shown once a quote is accepted. Displays
/// the existing review (with an edit shortcut) or a prompt to write one.
class _ReviewBlock extends ConsumerWidget {
  const _ReviewBlock({required this.briefId, required this.contractorId});
  final String briefId;
  final String contractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = ref.watch(reviewForBriefProvider(briefId)).value;
    if (existing == null) {
      // Migration 0019 requires briefs.completed_at for the review insert, so
      // offering the button before completion would show a form the database
      // rejects. Reviews follow finished work, not hiring.
      final brief = ref.watch(briefByIdProvider(briefId)).value;
      if (brief == null || !brief.canBeReviewed) {
        return Padding(
          padding: const EdgeInsets.only(top: BatshSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: BatshIconSize.sm, color: BatshColors.onSurfaceVariant),
              const SizedBox(width: BatshSpacing.xs),
              Expanded(
                child: Text(
                  S.reviewAfterCompletionHint,
                  style: BatshTypography.labelSm
                      .copyWith(color: BatshColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: BatshSpacing.sm),
        child: BatshButton(
          label: S.rateContractor,
          style: BatshButtonStyle.secondary,
          icon: Icons.star_outline,
          onPressed: () => showWriteReviewSheet(context,
              briefId: briefId, contractorId: contractorId),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: BatshSpacing.sm),
      child: Row(
        children: [
          BatshStars(rating: existing.rating.toDouble(), size: 18),
          const SizedBox(width: BatshSpacing.sm),
          Text(S.yourReview,
              style: BatshTypography.labelMd
                  .copyWith(color: BatshColors.onSurfaceVariant)),
          const Spacer(),
          TextButton(
            onPressed: () => showWriteReviewSheet(context,
                briefId: briefId,
                contractorId: contractorId,
                existing: existing),
            child: Text(S.editReview),
          ),
        ],
      ),
    );
  }
}