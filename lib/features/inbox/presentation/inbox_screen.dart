import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/l10n/strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_card.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/utils/error_mapper.dart';
import '../../briefs/domain/brief.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../quotes/presentation/widgets/quote_status_badge.dart';
import '../domain/received_request.dart';
import 'providers/inbox_providers.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_badge.dart';
import '../../../core/theme/batsh_motion.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inboxRequestsProvider);
    return BatshScaffold(
      title: S.inboxTitle,
      headerStyle: BatshHeaderStyle.primary,
      body: async.when(
        loading: () => const _InboxSkeleton(),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(inboxRequestsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return BatshEmptyState(
              title: S.inboxEmptyTitle,
              message: S.inboxEmptyMessage,
              icon: Icons.inbox_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(inboxRequestsProvider);
              await ref.read(inboxRequestsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: BatshSpacing.md),
              itemBuilder: (context, i) {
                final r = items[i];
                final reduced = MediaQuery.disableAnimationsOf(context);
                final card = _RequestCard(request: r);
                return reduced
                    ? card
                    : card
                          .animate()
                          .fadeIn(
                            delay: (60 * i.clamp(0, 7)).ms,
                            duration: 260.ms,
                          )
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: BatshMotion.easeOut,
                          );
              },
            ),
          );
        },
      ),
    );
  }
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.marginMobile,
        vertical: BatshSpacing.md,
      ),
      child: Column(
        children: [for (var i = 0; i < 4; i++) _SkeletonCard(index: i)],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final items = <Widget>[
      BatshShimmerBox(height: 16, width: 160, borderRadius: BatshRadius.brSm),
      const SizedBox(height: 8),
      BatshShimmerBox(height: 14, width: 240, borderRadius: BatshRadius.brSm),
      const SizedBox(height: 8),
      BatshShimmerBox(height: 14, width: 120, borderRadius: BatshRadius.brSm),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: reduced
            ? items
            : items
                  .animate(interval: 60.ms)
                  .fadeIn(duration: 280.ms, curve: BatshMotion.easeOut),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final ReceivedRequest request;

  @override
  Widget build(BuildContext context) {
    final brief = request.brief;
    final date = intl.DateFormat.yMMMd('ar').format(brief.createdAt);
    final apt =
        OnboardingCatalog.apartmentLabels[brief.apartmentType] ??
        brief.apartmentType.name;
    final place = '$apt - ${brief.city}';
    return BatshCard(
      onTap: () => context.push(Routes.contractorRequestDetailPath(brief.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  brief.workDescription,
                  style: BatshTypography.titleLg.copyWith(fontSize: 17),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              // A cancelled request is dead — surface that instead of a quote
              // badge so the contractor doesn't quote into a closed job.
              brief.status == BriefStatus.cancelled
                  ? BatshBadge(label: S.statusCancelled, compact: true)
                  : QuoteStatusBadge(status: request.quoteStatus),
            ],
          ),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: BatshIconSize.sm,
                color: BatshColors.onSurfaceVariant,
              ),
              const SizedBox(width: BatshSpacing.xs),
              Expanded(
                child: Text(
                  place,
                  style: BatshTypography.labelMd.copyWith(
                    color: BatshColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                date,
                style: BatshTypography.labelSm.copyWith(
                  color: BatshColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
