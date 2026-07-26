import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../reviews/presentation/write_review_sheet.dart';
import '../../domain/brief.dart';
import '../providers/briefs_providers.dart';

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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
        ));
      onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(ErrorMapper.map(e)),
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestCompletion() => _run(
        () => ref
            .read(briefsControllerProvider.notifier)
            .requestCompletion(widget.brief.id),
        S.workDoneRequested,
      );

  Future<void> _confirmCompletion() async {
    // Irreversible, and it mints a public project count, so it asks first.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.confirmCompletionTitle),
        content: Text(S.confirmCompletionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.confirmWorkDone),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _run(
      () => ref
          .read(briefsControllerProvider.notifier)
          .confirmCompletion(widget.brief.id),
      S.workCompletedNow,
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
          color: BatshColors.secondary,
          title: S.completedLabel,
        ),
      BriefStage.hired => isHomeowner
          ? _ActionCard(
              icon: Icons.handyman_outlined,
              message: S.reviewAfterCompletionHint,
              actionLabel: S.confirmWorkDone,
              busy: _busy,
              onPressed: _confirmCompletion,
            )
          : _ActionCard(
              icon: Icons.handyman_outlined,
              message: S.markWorkDone,
              actionLabel: S.markWorkDone,
              busy: _busy,
              onPressed: _requestCompletion,
            ),
      BriefStage.completionRequested => isHomeowner
          // The contractor has said they finished, so confirming becomes the
          // primary action rather than a passive option.
          ? _ActionCard(
              icon: Icons.notifications_active_outlined,
              message: S.contractorSaysDone,
              actionLabel: S.confirmWorkDone,
              emphasised: true,
              busy: _busy,
              onPressed: _confirmCompletion,
            )
          : _Banner(
              icon: Icons.hourglass_top_rounded,
              color: BatshColors.onSurfaceVariant,
              title: S.awaitingHomeownerConfirm,
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
            ? BatshColors.secondaryContainer
            : BatshColors.surfaceContainerLow,
        borderRadius: BatshRadius.brCard,
        border: Border.all(
          color: emphasised
              ? BatshColors.secondary
              : BatshColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: emphasised
                      ? BatshColors.onSecondaryContainer
                      : BatshColors.onSurfaceVariant),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: BatshTypography.bodyMd.copyWith(
                    color: emphasised
                        ? BatshColors.onSecondaryContainer
                        : BatshColors.onSurfaceVariant,
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
  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
  });

  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.gutter, vertical: BatshSpacing.md),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLow,
        borderRadius: BatshRadius.brCard,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Text(title,
                style: BatshTypography.labelLg
                    .copyWith(color: BatshColors.onSurface)),
          ),
        ],
      ),
    );
  }
}
