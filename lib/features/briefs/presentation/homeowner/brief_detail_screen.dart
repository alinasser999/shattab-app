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
import '../../../quotes/presentation/widgets/quotes_received_section.dart';
import '../../domain/brief.dart';
import '../providers/briefs_providers.dart';

class BriefDetailScreen extends ConsumerWidget {
  const BriefDetailScreen({super.key, required this.briefId});

  final String briefId;

  /// Returns true only if the user confirmed and the brief was cancelled.
  Future<bool> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.cancelBriefTitle),
        content: Text(S.cancelBriefMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.cancelBriefNo)),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.cancelBriefYes)),
        ],
      ),
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
                  Text(S.workDescriptionLabel,
                      style: BatshTypography.labelMd.copyWith(
                          color: BatshColors.onSurfaceVariant)),
                  const SizedBox(height: BatshSpacing.sm),
                  Text(brief.workDescription,
                      style: BatshTypography.bodyLg),
                ],
              ),
            ),
            const SizedBox(height: BatshSpacing.gutter),
            BatshCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.locationDetailsLabel,
                      style: BatshTypography.labelMd.copyWith(
                          color: BatshColors.onSurfaceVariant)),
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
                    Text(S.lookingForLabel,
                        style: BatshTypography.labelMd.copyWith(
                            color: BatshColors.onSurfaceVariant)),
                    const SizedBox(height: BatshSpacing.sm),
                    Wrap(
                      spacing: BatshSpacing.xs,
                      runSpacing: BatshSpacing.xs,
                      children: brief.targetSpecialties
                          .map((s) => Text(
                              OnboardingCatalog.specialtiesCatalog[s] ?? s,
                              style: BatshTypography.bodyMd))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ]);
          }
          children.addAll([
            const SizedBox(height: BatshSpacing.xl),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.unknownErrorRetry)),
                      );
                    }
                  }
                },
              ),
            );
          }
          children.add(const SizedBox(height: BatshSpacing.lg));

          final reduced = MediaQuery.of(context).disableAnimations;
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(briefByIdProvider(briefId)),
            child: ListView(
              children: reduced
                  ? children
                  : children
                      .animate(interval: BatshMotion.staggerBase)
                      .fadeIn(duration: BatshMotion.normal)
                      .slideY(
                          begin: 0.06,
                          end: 0,
                          curve: BatshMotion.easeOut),
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
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
          child: Row(
            children: [
              BatshShimmerBox(width: 12, height: 12, borderRadius: BatshRadius.brFull),
              const SizedBox(width: BatshSpacing.sm),
              BatshShimmerBox(width: 120, height: 14, borderRadius: BatshRadius.brSm),
              const Spacer(),
              BatshShimmerBox(width: 80, height: 12, borderRadius: BatshRadius.brSm),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
          child: BatshShimmerBox(width: double.infinity, height: 120, borderRadius: BatshRadius.brLg),
        ),
        const SizedBox(height: BatshSpacing.gutter),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
          child: BatshShimmerBox(width: double.infinity, height: 80, borderRadius: BatshRadius.brLg),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.brief, required this.date});
  final Brief brief;
  final String date;
  @override
  Widget build(BuildContext context) {
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
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: BatshSpacing.sm),
        Text(label,
            style: BatshTypography.labelMd
                .copyWith(color: color, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text(date,
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant)),
      ],
    );
  }
}
