import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/analytics/app_analytics.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_card.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../billing/presentation/payment_flow.dart';
import '../../briefs/domain/brief.dart';
import '../../quotes/presentation/widgets/quote_status_badge.dart';
import '../domain/received_request.dart';
import 'providers/inbox_providers.dart';
import '../../quotes/presentation/providers/quotes_providers.dart';
import 'widgets/requests_page_widgets.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Contractor requests/inbox surface.
///
/// A direct request is the proof; Pro is shown only in the context of the
/// request whose protected contact details the contractor is trying to reach.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _annual = false;
  bool _checkoutLoading = false;
  bool _paywallTracked = false;

  Future<void> _startCheckout({required Brief request}) async {
    if (_checkoutLoading) return;

    setState(() => _checkoutLoading = true);
    unawaited(
      AppAnalytics.track(
        'pro_cta_tapped',
        properties: {
          'selected_plan': _annual ? 'annual' : 'monthly',
          'request_id': request.id,
          'request_city': request.city,
          'source_screen': 'contractor_requests',
        },
      ),
    );
    unawaited(
      AppAnalytics.track(
        'checkout_started',
        properties: {
          'selected_plan': _annual ? 'annual' : 'monthly',
          'request_id': request.id,
          'source_screen': 'contractor_requests',
        },
      ),
    );

    try {
      await showPaymentMethods(context, annual: _annual);
      if (!mounted) return;
      // Payment is manually confirmed by the existing billing flow. Refresh
      // the server-backed entitlement after the flow closes; never claim
      // activation from a client-side tap.
      ref.invalidate(myQuoteQuotaProvider);
    } catch (error) {
      if (!mounted) return;
      BatshSnack.error(context, context.l10n.requestsCheckoutFailed);
      unawaited(
        AppAnalytics.track(
          'checkout_failed',
          properties: {
            'selected_plan': _annual ? 'annual' : 'monthly',
            'request_id': request.id,
            'source_screen': 'contractor_requests',
          },
        ),
      );
    } finally {
      if (mounted) setState(() => _checkoutLoading = false);
    }
  }

  void _trackPaywallView(
    Brief request,
    ({bool isPro, int used, int quota})? quota,
  ) {
    if (_paywallTracked || quota?.isPro == true) return;
    _paywallTracked = true;
    unawaited(
      AppAnalytics.track(
        'requests_paywall_viewed',
        properties: {
          'subscription_state': 'free',
          'offers_used': quota?.used,
          'free_offer_limit': quota?.quota,
          'trial_eligible': quota != null,
          'request_id': request.id,
          'request_city': request.city,
          'source_screen': 'contractor_requests',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(inboxRequestsProvider);
    final quotaAsync = ref.watch(myQuoteQuotaProvider);

    return BatshScaffold(
      title: context.l10n.requestsPageTitle,
      leading: IconButton(
        tooltip: context.l10n.back,
        onPressed: () => context.go(Routes.contractorDashboard),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      padding: EdgeInsets.zero,
      animateEntrance: false,
      body: RequestsPatternBackground(
        child: requestsAsync.when(
          loading: () => const _RequestsSkeleton(),
          error: (error, _) => BatshError(
            message: ErrorMapper.map(error),
            onRetry: () => ref.invalidate(inboxRequestsProvider),
          ),
          data: (requests) {
            final quota = quotaAsync.value;
            if (requests.isNotEmpty) {
              _trackPaywallView(requests.first.brief, quota);
            }
            return _RequestsContent(
              requests: requests,
              quota: quota,
              quotaLoading: quotaAsync.isLoading,
              quotaError: quotaAsync.hasError,
              annual: _annual,
              checkoutLoading: _checkoutLoading,
              onAnnualChanged: (value) => setState(() => _annual = value),
              onCheckout: requests.isEmpty
                  ? null
                  : () => _startCheckout(request: requests.first.brief),
              onRetryQuota: () => ref.invalidate(myQuoteQuotaProvider),
              onRefresh: () async {
                ref.invalidate(inboxRequestsProvider);
                ref.invalidate(myQuoteQuotaProvider);
                await Future.wait([
                  ref.read(inboxRequestsProvider.future),
                  ref.read(myQuoteQuotaProvider.future),
                ]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _RequestsContent extends StatelessWidget {
  const _RequestsContent({
    required this.requests,
    required this.quota,
    required this.quotaLoading,
    required this.quotaError,
    required this.annual,
    required this.checkoutLoading,
    required this.onAnnualChanged,
    required this.onCheckout,
    required this.onRetryQuota,
    required this.onRefresh,
  });

  final List<ReceivedRequest> requests;
  final ({bool isPro, int used, int quota})? quota;
  final bool quotaLoading;
  final bool quotaError;
  final bool annual;
  final bool checkoutLoading;
  final ValueChanged<bool> onAnnualChanged;
  final VoidCallback? onCheckout;
  final VoidCallback onRetryQuota;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.xxl,
          BatshSpacing.md,
          BatshSpacing.xxxxl,
        ),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 420),
            child: BatshEmptyState(
              title: context.l10n.inboxEmptyTitle,
              message: context.l10n.inboxEmptyMessage,
              icon: Icons.inbox_outlined,
              action: BatshButton(
                label: context.l10n.opportunitiesTitle,
                icon: Icons.work_outline_rounded,
                onPressed: () => context.go(Routes.contractorDashboard),
              ),
            ),
          ),
        ],
      );
    }

    final featured = requests.first;
    final isPro = quota?.isPro == true;
    // The current schema exposes plan/expiry and quote quota, but not a
    // trial-consumed flag. Keep the existing configured Pro entry copy for
    // free professionals until that entitlement field exists server-side.
    final trialAvailable = quota != null && !isPro;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.sm,
          BatshSpacing.md,
          BatshSpacing.xxxxl,
        ),
        children: [
          RequestsUsageBanner(
            used: quota?.used,
            quota: quota?.quota,
            isPro: isPro,
            isLoading: quotaLoading && quota == null,
            hasError: quotaError && quota == null,
            onRetry: onRetryQuota,
          ),
          const SizedBox(height: BatshSpacing.md),
          LockedRequestCard(
            request: featured.brief,
            locked: !isPro,
            onTap: () => context.push(
              Routes.contractorRequestDetailPath(featured.brief.id),
            ),
          ),
          if (requests.length > 1) ...[
            const SizedBox(height: BatshSpacing.xl),
            _MoreRequests(requests: requests.skip(1).toList()),
          ],
          const SizedBox(height: BatshSpacing.xl),
          if (isPro)
            _ProAccessCard(
              onTap: () => context.push(
                Routes.contractorRequestDetailPath(featured.brief.id),
              ),
            )
          else
            RequestsProConversionCard(
              annual: annual,
              onAnnualChanged: onAnnualChanged,
              onSubscribe: onCheckout,
              isLoading: checkoutLoading,
              trialAvailable: trialAvailable,
            ),
        ],
      ),
    );
  }
}

class _MoreRequests extends StatelessWidget {
  const _MoreRequests({required this.requests});

  final List<ReceivedRequest> requests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.requestsOtherTitle,
          textAlign: TextAlign.end,
          style: BatshTypography.titleLg.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: BatshSpacing.sm),
        for (var i = 0; i < requests.length; i++) ...[
          _CompactRequestRow(request: requests[i]),
          if (i != requests.length - 1) const SizedBox(height: BatshSpacing.sm),
        ],
      ],
    );
  }
}

class _CompactRequestRow extends StatelessWidget {
  const _CompactRequestRow({required this.request});

  final ReceivedRequest request;

  @override
  Widget build(BuildContext context) {
    return BatshCard(
      onTap: () =>
          context.push(Routes.contractorRequestDetailPath(request.brief.id)),
      padding: const EdgeInsets.all(BatshSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.chevron_left_rounded),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  request.brief.workDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: BatshTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xxs),
                Text(
                  '${request.brief.city} • ${request.brief.apartmentType.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: BatshTypography.labelMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          if (request.quoteStatus != null)
            QuoteStatusBadge(status: request.quoteStatus!),
        ],
      ),
    );
  }
}

class _ProAccessCard extends StatelessWidget {
  const _ProAccessCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer,
        borderRadius: BatshRadius.brXxl,
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified_rounded,
            color: context.colorScheme.onSecondaryContainer,
            size: BatshIconSize.xl,
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            context.l10n.requestsProUnlocked,
            textAlign: TextAlign.center,
            style: BatshTypography.titleLg.copyWith(
              color: context.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          BatshButton(
            label: context.l10n.requestsOpenDetails,
            icon: Icons.arrow_back_rounded,
            onPressed: onTap,
            backgroundColor: context.colorScheme.secondary,
            foregroundColor: context.colorScheme.onSecondary,
          ),
        ],
      ),
    );
  }
}

class _RequestsSkeleton extends StatelessWidget {
  const _RequestsSkeleton();

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final cards = <Widget>[
      const BatshShimmerBox(
        height: 74,
        width: double.infinity,
        borderRadius: BatshRadius.brXxl,
      ),
      const SizedBox(height: BatshSpacing.md),
      const BatshShimmerBox(
        height: 390,
        width: double.infinity,
        borderRadius: BatshRadius.brXxl,
      ),
      const SizedBox(height: BatshSpacing.xl),
      const BatshShimmerBox(
        height: 620,
        width: double.infinity,
        borderRadius: BatshRadius.brXxl,
      ),
    ];
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        BatshSpacing.sm,
        BatshSpacing.md,
        BatshSpacing.xxxxl,
      ),
      children: reduced
          ? cards
          : cards
                .animate(interval: 80.ms)
                .fadeIn(duration: 260.ms, curve: BatshMotion.easeOut),
    );
    return content;
  }
}
