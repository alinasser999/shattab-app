import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../reviews/presentation/write_review_sheet.dart';
import '../../domain/brief.dart';
import '../providers/briefs_providers.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../../core/widgets/batsh_dialog.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Which side of the job is looking at the card.
enum CompletionRole { homeowner, contractor }

/// The hire-to-completion step, rendered for whichever side is looking.
///
/// Both roles see the same state machine, but only the homeowner can advance it
/// past `completionRequested` — the contractor's action is a nudge, not proof
/// (see migration 0019). Nothing renders before a hire, since there is no work
/// to finish yet.
class CompletionCard extends ConsumerStatefulWidget {
  const CompletionCard({
    super.key,
    required this.brief,
    required this.role,
    this.acceptedContractorId,
  });

  final Brief brief;
  final CompletionRole role;

  /// Contractor holding the accepted quote. Used to open the review sheet
  /// straight after the homeowner confirms — the highest-intent moment there is
  /// for asking. When null, confirmation still works and the review is left to
  /// the quote card's own entry point.
  final String? acceptedContractorId;

  @override
  ConsumerState<CompletionCard> createState() => _CompletionCardState();
}

class _CompletionCardState extends ConsumerState<CompletionCard> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function() action,
    String successMessage, {
    VoidCallback? onSuccess,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      BatshSnack.success(context, successMessage);
      onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      BatshSnack.error(context, ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestCompletion() => _run(
    () => ref
        .read(briefsControllerProvider.notifier)
        .requestCompletion(widget.brief.id),
    context.l10n.workDoneRequested,
  );

  Future<void> _confirmCompletion() async {
    // Irreversible, and it mints a public project count, so it asks first.
    final ok = await BatshDialog.confirm(
      context,
      title: context.l10n.confirmCompletionTitle,
      message: context.l10n.confirmCompletionBody,
      confirmLabel: context.l10n.confirmWorkDone,
      cancelLabel: context.l10n.cancel,
    );
    if (ok != true) return;

    await _run(
      () => ref
          .read(briefsControllerProvider.notifier)
          .confirmCompletion(widget.brief.id),
      context.l10n.workCompletedNow,
      onSuccess: () {
        HapticFeedback.mediumImpact();
        final contractorId = widget.acceptedContractorId;
        if (contractorId == null) return;
        // Ask for the review while the job is still fresh.
        showWriteReviewSheet(
          context,
          briefId: widget.brief.id,
          contractorId: contractorId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHomeowner = widget.role == CompletionRole.homeowner;

    return switch (widget.brief.stage) {
      // Nothing to finish before anyone is hired.
      BriefStage.open => const SizedBox.shrink(),
      BriefStage.completed => _Banner(
        icon: Icons.verified_rounded,
        color: context.colorScheme.secondary,
        title: context.l10n.completedLabel,
      ),
      BriefStage.hired =>
        isHomeowner
            ? _ActionCard(
                icon: Icons.handyman_outlined,
                message: context.l10n.reviewAfterCompletionHint,
                actionLabel: context.l10n.confirmWorkDone,
                busy: _busy,
                onPressed: _confirmCompletion,
              )
            : _ActionCard(
                icon: Icons.handyman_outlined,
                message: context.l10n.markWorkDone,
                actionLabel: context.l10n.markWorkDone,
                busy: _busy,
                onPressed: _requestCompletion,
              ),
      BriefStage.completionRequested =>
        isHomeowner
            // The contractor has said they finished, so confirming becomes the
            // primary action rather than a passive option.
            ? _ActionCard(
                icon: Icons.notifications_active_outlined,
                message: context.l10n.contractorSaysDone,
                actionLabel: context.l10n.confirmWorkDone,
                emphasised: true,
                busy: _busy,
                onPressed: _confirmCompletion,
              )
            : _Banner(
                icon: Icons.hourglass_top_rounded,
                color: context.colorScheme.onSurfaceVariant,
                title: context.l10n.awaitingHomeownerConfirm,
              ),
    };
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.busy,
    required this.onPressed,
    this.emphasised = false,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final bool busy;
  final VoidCallback onPressed;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.gutter),
      decoration: BoxDecoration(
        color: emphasised
            ? context.colorScheme.secondaryContainer
            : context.colorScheme.surfaceContainerLow,
        borderRadius: BatshRadius.brCard,
        border: Border.all(
          color: emphasised
              ? context.colorScheme.secondary
              : context.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: BatshIconSize.md,
                color: emphasised
                    ? context.colorScheme.onSecondaryContainer
                    : context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: BatshTypography.bodyMd.copyWith(
                    color: emphasised
                        ? context.colorScheme.onSecondaryContainer
                        : context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          BatshButton(
            label: actionLabel,
            icon: Icons.check_rounded,
            isLoading: busy,
            style: emphasised
                ? BatshButtonStyle.primary
                : BatshButtonStyle.secondary,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.title});

  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.gutter,
        vertical: BatshSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BatshRadius.brCard,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: BatshIconSize.md, color: color),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: BatshTypography.labelLg.copyWith(
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
