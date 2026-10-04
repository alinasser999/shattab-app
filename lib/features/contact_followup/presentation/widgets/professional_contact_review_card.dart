import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../professional_contact_review_sheet.dart';
import '../providers/professional_contact_providers.dart';

class ProfessionalContactReviewCard extends ConsumerStatefulWidget {
  const ProfessionalContactReviewCard({super.key});

  @override
  ConsumerState<ProfessionalContactReviewCard> createState() =>
      _ProfessionalContactReviewCardState();
}

class _ProfessionalContactReviewCardState
    extends ConsumerState<ProfessionalContactReviewCard> {
  bool _busy = false;

  Future<void> _resolve(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        BatshSnack.error(
          context,
          context.l10n.professionalContactReviewActionFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openReview({
    required String episodeId,
    required String contractorId,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final submitted = await showProfessionalContactReviewSheet(
        context,
        episodeId: episodeId,
        contractorId: contractorId,
      );
      if (submitted == true && mounted) {
        ref.invalidate(professionalContactEpisodeProvider);
      }
    } catch (_) {
      if (mounted) {
        BatshSnack.error(
          context,
          context.l10n.professionalContactReviewActionFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final episode = ref.watch(professionalContactEpisodeProvider).asData?.value;
    if (episode == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.gutter,
        BatshSpacing.sm,
        BatshSpacing.gutter,
        BatshSpacing.md,
      ),
      child: BatshCard(
        primary: true,
        padding: const EdgeInsets.all(BatshSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.professionalContactReviewPrompt,
                        style: BatshTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (episode.contractorName.isNotEmpty) ...[
                        const SizedBox(height: BatshSpacing.xs),
                        Text(
                          episode.contractorName,
                          style: BatshTypography.labelMd.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.professionalContactReviewDismiss,
                  onPressed: _busy
                      ? null
                      : () => _resolve(
                          () => ref
                              .read(professionalContactActionsProvider)
                              .dismiss(episode.id),
                        ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: BatshSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: BatshButton(
                    label: context.l10n.professionalContactReviewPrimaryAction,
                    onPressed: _busy
                        ? null
                        : () => _openReview(
                            episodeId: episode.id,
                            contractorId: episode.contractorId,
                          ),
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: BatshButton(
                    label: context.l10n.professionalContactReviewNotTogether,
                    style: BatshButtonStyle.secondary,
                    onPressed: _busy
                        ? null
                        : () => _resolve(
                            () => ref
                                .read(professionalContactActionsProvider)
                                .markNotWorkedTogether(episode.id),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
