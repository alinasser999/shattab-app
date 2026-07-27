import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/l10n/strings.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../quotes/domain/quote.dart';
import '../../../quotes/presentation/providers/quotes_providers.dart';
import '../../../quotes/presentation/widgets/quotes_received_section.dart';
import '../../domain/brief.dart';
import '../providers/briefs_providers.dart';
import '../widgets/completion_card.dart';
import 'create_post_screen.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../../core/widgets/batsh_dialog.dart';

/// Resolves the hired contractor so confirming completion can open the review
/// sheet for them immediately. Falls back to confirming without the prompt if
/// the quotes have not loaded — completion must not depend on a second fetch.
class _CompletionSection extends ConsumerWidget {
  const _CompletionSection({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(quotesForBriefProvider(brief.id)).value;
    final accepted = quotes
        ?.where((q) => q.status == QuoteStatus.accepted)
        .firstOrNull;
    return CompletionCard(
      brief: brief,
      role: CompletionRole.homeowner,
      acceptedContractorId: accepted?.contractorId,
    );
  }
}

class BriefDetailScreen extends ConsumerWidget {
  const BriefDetailScreen({super.key, required this.briefId});

  final String briefId;

  /// Returns true only if the user confirmed and the brief was cancelled.
  Future<bool> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await BatshDialog.confirm(
      context,
      title: S.cancelBriefTitle,
      message: S.cancelBriefMessage,
      confirmLabel: S.cancelBriefYes,
      cancelLabel: S.cancelBriefNo,
    );
    if (confirmed != true) return false;
    await ref.read(briefsControllerProvider.notifier).cancel(briefId);
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(briefByIdProvider(briefId));

    return BatshScaffold(
      title: S.briefDetailTitle,
      body: async.when(
        loading: () => const _BriefDetailSkeleton(),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(briefByIdProvider(briefId)),
        ),
        data: (brief) {
          if (brief == null) {
            return BatshError(message: S.briefNotFound);
          }
          final date = intl.DateFormat.yMMMd('ar').format(brief.createdAt);
          final children = <Widget>[
            const SizedBox(height: BatshSpacing.md),
            _StatusRow(brief: brief, date: date),
            const SizedBox(height: BatshSpacing.lg),
          ];
          if (brief.photoUrls.isNotEmpty) {
            children.addAll([
              PhotoGallery(urls: brief.photoUrls),
              const SizedBox(height: BatshSpacing.lg),
            ]);
          }
          children.addAll([
            BatshCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.workDescriptionLabel,
                    style: BatshTypography.labelMd.copyWith(
                      color: BatshColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Text(brief.workDescription, style: BatshTypography.bodyLg),
                ],
              ),
            ),
            const SizedBox(height: BatshSpacing.gutter),
            BatshCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.locationDetailsLabel,
                    style: BatshTypography.labelMd.copyWith(
                      color: BatshColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Text(
                    '${OnboardingCatalog.apartmentLabels[brief.apartmentType] ?? brief.apartmentType.name} · ${brief.city}${brief.district != null ? ' · ${brief.district}' : ''}',
                    style: BatshTypography.bodyLg,
                  ),
                ],
              ),
            ),
          ]);
          if (brief.isPost && brief.targetSpecialties.isNotEmpty) {
            children.addAll([
              const SizedBox(height: BatshSpacing.gutter),
              BatshCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.lookingForLabel,
                      style: BatshTypography.labelMd.copyWith(
                        color: BatshColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.sm),
                    Wrap(
                      spacing: BatshSpacing.xs,
                      runSpacing: BatshSpacing.xs,
                      children: brief.targetSpecialties
                          .map(
                            (s) => Text(
                              OnboardingCatalog.specialtiesCatalog[s] ?? s,
                              style: BatshTypography.bodyMd,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ]);
          }
          children.addAll([
            const SizedBox(height: BatshSpacing.xl),
            // Sits above the quotes: once someone is hired, closing out the job
            // is the homeowner's next action, not re-reading offers.
            if (brief.isHired)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.gutter,
                  vertical: BatshSpacing.sm,
                ),
                child: _CompletionSection(brief: brief),
              ),
            QuotesReceivedSection(briefId: brief.id, canAct: brief.isActive),
            const SizedBox(height: BatshSpacing.lg),
          ]);
          if (brief.isActive) {
            children.add(
              BatshButton(
                label: S.cancelButton,
                style: BatshButtonStyle.secondary,
                onPressed: () async {
                  try {
                    final cancelled = await _cancel(context, ref);
                    if (cancelled && context.mounted) context.pop();
                  } catch (_) {
                    if (context.mounted) {
                      BatshSnack.error(context, S.unknownErrorRetry);
                    }
                  }
                },
              ),
            );
          }
          children.add(const SizedBox(height: BatshSpacing.lg));

          final reduced = MediaQuery.disableAnimationsOf(context);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(briefByIdProvider(briefId)),
            child: ListView(
              children: reduced
                  ? children
                  : children
                        .animate(interval: BatshMotion.staggerBase)
                        .fadeIn(duration: BatshMotion.normal)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          curve: BatshMotion.easeOut,
                        ),
            ),
          );
        },
      ),
    );
  }
}

class _BriefDetailSkeleton extends StatelessWidget {
  const _BriefDetailSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: BatshSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: Row(
            children: [
              BatshShimmerBox(
                width: 12,
                height: 12,
                borderRadius: BatshRadius.brFull,
              ),
              const SizedBox(width: BatshSpacing.sm),
              BatshShimmerBox(
                width: 120,
                height: 14,
                borderRadius: BatshRadius.brSm,
              ),
              const Spacer(),
              BatshShimmerBox(
                width: 80,
                height: 12,
                borderRadius: BatshRadius.brSm,
              ),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: BatshShimmerBox(
            width: double.infinity,
            height: 120,
            borderRadius: BatshRadius.brLg,
          ),
        ),
        const SizedBox(height: BatshSpacing.gutter),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: BatshShimmerBox(
            width: double.infinity,
            height: 80,
            borderRadius: BatshRadius.brLg,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends ConsumerWidget {
  const _StatusRow({required this.brief, required this.date});
  final Brief brief;
  final String date;

  /// Removes the brief, or cancels it when contractors have already quoted.
  /// The server decides which (migration 0020) — checking here and deleting
  /// afterwards would race a quote arriving in between, and losing that race
  /// destroys a contractor's work via the cascade.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final quotes = ref.read(quotesForBriefProvider(brief.id)).value;
    final willCancel = (quotes?.isNotEmpty ?? false) || brief.isHired;

    final ok = await BatshDialog.confirm(
      context,
      title: S.deleteBriefTitle,
      message: willCancel ? S.deleteBriefWithQuotesBody : S.deleteBriefBody,
      confirmLabel: S.deletePost,
      cancelLabel: S.cancel,
      isDestructive: true,
    );
    if (ok != true || !context.mounted) return;

    try {
      final outcome = await ref
          .read(briefsControllerProvider.notifier)
          .deleteOrCancelBrief(brief.id);
      if (!context.mounted) return;
      BatshSnack.success(
        context,
        outcome == 'deleted' ? S.briefDeleted : S.briefCancelledInstead,
      );
      // The row is gone when it was truly deleted; stay put when cancelled so
      // the homeowner can still see the quotes that survived.
      if (outcome == 'deleted') Navigator.of(context).maybePop();
    } catch (e) {
      if (!context.mounted) return;
      BatshSnack.error(context, ErrorMapper.map(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPost = brief.isPost;
    final isCancelled = brief.status == BriefStatus.cancelled;
    final color = isCancelled
        ? BatshColors.onSurfaceVariant
        : (isPost ? BatshColors.tertiary : BatshColors.primary);
    final label = isCancelled
        ? S.statusCancelled
        : (isPost ? S.statusPost : S.statusDirectRequest);
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: BatshIconSize.xs),
        const SizedBox(width: BatshSpacing.sm),
        Text(
          label,
          style: BatshTypography.labelMd.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (brief.isEdited) ...[
          const SizedBox(width: BatshSpacing.sm),
          // Contractors see this too: a quote written against the original
          // wording may no longer fit the scope.
          Text(
            '· ${S.editedMarker}',
            style: BatshTypography.labelSm.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        Text(
          date,
          style: BatshTypography.labelMd.copyWith(
            color: BatshColors.onSurfaceVariant,
          ),
        ),
        if (!isCancelled)
          PopupMenuButton<String>(
            tooltip: S.editPost,
            icon: const Icon(
              Icons.more_horiz_rounded,
              size: BatshIconSize.md,
              color: BatshColors.onSurfaceVariant,
            ),
            onSelected: (v) {
              if (v == 'delete') {
                _delete(context, ref);
              } else if (v == 'edit') {
                // Pushed rather than routed: the edit form is the create form
                // with a brief attached, and it has no shareable URL of its own.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(editing: brief),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              // Editing is offered only while the scope can still change. The
              // database rejects it after hiring, so hiding it here keeps the
              // UI and the rule in agreement.
              if (brief.canBeEdited)
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: BatshIconSize.md),
                      const SizedBox(width: BatshSpacing.sm),
                      Text(S.editBriefTitle),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: BatshIconSize.md,
                      color: BatshColors.error,
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    Text(
                      S.deletePost,
                      style: const TextStyle(color: BatshColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
