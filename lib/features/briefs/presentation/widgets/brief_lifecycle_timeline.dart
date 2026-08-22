import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../quotes/presentation/providers/quotes_providers.dart';
import '../../domain/brief.dart';
import '../../domain/brief_lifecycle.dart';
import '../../../quotes/domain/quote.dart';

enum BriefLifecycleAudience { homeowner, contractor }

class BriefLifecycleTimeline extends ConsumerWidget {
  const BriefLifecycleTimeline({
    super.key,
    required this.brief,
    this.audience = BriefLifecycleAudience.homeowner,
    this.myQuote,
    this.quoteLoading = false,
    this.quoteFailed = false,
  });

  final Brief brief;
  final BriefLifecycleAudience audience;
  final Quote? myQuote;
  final bool quoteLoading;
  final bool quoteFailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = audience == BriefLifecycleAudience.homeowner
        ? ref.watch(quotesForBriefProvider(brief.id))
        : null;
    final hasQuotes = audience == BriefLifecycleAudience.homeowner
        ? quotes?.value?.isNotEmpty ?? false
        : myQuote != null;

    return _BriefLifecycleCard(
      brief: brief,
      audience: audience,
      myQuote: myQuote,
      hasQuotes: hasQuotes,
      quotesLoading: audience == BriefLifecycleAudience.homeowner
          ? quotes?.isLoading ?? false
          : quoteLoading,
      quotesFailed: audience == BriefLifecycleAudience.homeowner
          ? quotes?.hasError ?? false
          : quoteFailed,
    );
  }
}

class _BriefLifecycleCard extends StatelessWidget {
  const _BriefLifecycleCard({
    required this.brief,
    required this.audience,
    required this.myQuote,
    required this.hasQuotes,
    required this.quotesLoading,
    required this.quotesFailed,
  });

  final Brief brief;
  final BriefLifecycleAudience audience;
  final Quote? myQuote;
  final bool hasQuotes;
  final bool quotesLoading;
  final bool quotesFailed;

  String _contractorQuoteTitle(BuildContext context) {
    if (quotesLoading) return context.l10n.briefLifecycleQuotesLoading;
    if (quotesFailed) return context.l10n.briefLifecycleQuotesError;
    final quote = myQuote;
    if (quote == null) {
      return brief.isActive
          ? context.l10n.opportunityOpen
          : context.l10n.opportunityClosed;
    }
    return switch (quote.status) {
      QuoteStatus.sent => context.l10n.quoteStatusSent,
      QuoteStatus.accepted => context.l10n.quoteStatusAccepted,
      QuoteStatus.declined => context.l10n.quoteStatusDeclined,
      QuoteStatus.withdrawn => context.l10n.quoteStatusWithdrawn,
    };
  }

  String _contractorQuoteBody(BuildContext context) {
    if (quotesLoading) return context.l10n.briefLifecycleQuotesLoading;
    if (quotesFailed) return context.l10n.briefLifecycleQuotesError;
    final quote = myQuote;
    if (quote == null) {
      return brief.isActive
          ? context.l10n.submitYourQuote
          : context.l10n.opportunityClosed;
    }
    return switch (quote.status) {
      QuoteStatus.sent => context.l10n.quoteSentMessage,
      QuoteStatus.accepted => context.l10n.briefLifecycleWorkStartedBody,
      QuoteStatus.declined => context.l10n.quoteStatusDeclined,
      QuoteStatus.withdrawn => context.l10n.quoteStatusWithdrawn,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (brief.status == BriefStatus.cancelled) {
      return _CancelledTimeline(brief: brief);
    }

    final steps = [
      (
        step: BriefLifecycleStep.requestPosted,
        icon: Icons.assignment_turned_in_outlined,
        title: context.l10n.briefLifecycleRequestPosted,
        body: context.l10n.briefLifecycleRequestPostedBody,
      ),
      (
        step: BriefLifecycleStep.quotes,
        icon: Icons.request_quote_outlined,
        title: audience == BriefLifecycleAudience.contractor
            ? _contractorQuoteTitle(context)
            : hasQuotes
            ? context.l10n.briefLifecycleQuotesReceived
            : context.l10n.briefLifecycleWaitingForQuotes,
        body: audience == BriefLifecycleAudience.contractor
            ? _contractorQuoteBody(context)
            : hasQuotes
            ? context.l10n.briefLifecycleQuotesReceivedBody
            : quotesFailed
            ? context.l10n.briefLifecycleQuotesError
            : quotesLoading
            ? context.l10n.briefLifecycleQuotesLoading
            : context.l10n.briefLifecycleWaitingForQuotesBody,
      ),
      (
        step: BriefLifecycleStep.work,
        icon: Icons.handyman_outlined,
        title: context.l10n.briefLifecycleWorkStarted,
        body: context.l10n.briefLifecycleWorkStartedBody,
      ),
      (
        step: BriefLifecycleStep.completion,
        icon: Icons.task_alt_rounded,
        title: brief.isCompleted
            ? context.l10n.briefLifecycleCompleted
            : context.l10n.briefLifecycleConfirmCompletion,
        body: brief.isCompleted
            ? context.l10n.briefLifecycleCompletedBody
            : context.l10n.briefLifecycleConfirmCompletionBody,
      ),
    ];

    return Semantics(
      container: true,
      label: context.l10n.briefLifecycleTitle,
      child: BatshCard(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.gutter,
          BatshSpacing.md,
          BatshSpacing.gutter,
          BatshSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.briefLifecycleTitle,
              style: BatshTypography.titleMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.md),
            for (var index = 0; index < steps.length; index++)
              _TimelineStep(
                icon: steps[index].icon,
                title: steps[index].title,
                body: steps[index].body,
                state: BriefLifecycle.state(
                  brief,
                  steps[index].step,
                  hasQuotes: hasQuotes,
                ),
                isLast: index == steps.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.state,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final String body;
  final BriefLifecycleStepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isCurrent = state == BriefLifecycleStepState.current;
    final isComplete = state == BriefLifecycleStepState.complete;
    final color = isComplete
        ? scheme.secondary
        : isCurrent
        ? scheme.primary
        : scheme.outline;

    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? scheme.secondaryContainer
                        : isCurrent
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(
                    isComplete ? Icons.check_rounded : icon,
                    size: BatshIconSize.inline,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 42,
                    color: isComplete
                        ? scheme.secondary.withValues(alpha: 0.48)
                        : scheme.outlineVariant,
                  ),
              ],
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: BatshTypography.labelLg.copyWith(
                      color: isCurrent
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: isCurrent || isComplete
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (isCurrent || isComplete) ...[
                    const SizedBox(height: BatshSpacing.xxxs),
                    Text(
                      body,
                      style: BatshTypography.bodySm.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledTimeline extends StatelessWidget {
  const _CancelledTimeline({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.l10n.briefLifecycleCancelled,
      child: BatshCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block_outlined,
                color: context.colorScheme.onSurfaceVariant,
                size: BatshIconSize.md,
              ),
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.briefLifecycleCancelled,
                    style: BatshTypography.titleMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xxxs),
                  Text(
                    context.l10n.briefLifecycleCancelledBody,
                    style: BatshTypography.bodySm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
