import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/error_mapper.dart';
import '../data/moderation_repository.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_dialog.dart';
import '../../../core/widgets/batsh_sheet.dart';
import '../../../core/theme/theme_extension.dart';

String _reasonLabel(BuildContext context, ReportReason r) => switch (r) {
  ReportReason.spam => context.l10n.reportReasonSpam,
  ReportReason.scam => context.l10n.reportReasonScam,
  ReportReason.offensive => context.l10n.reportReasonOffensive,
  ReportReason.sexual => context.l10n.reportReasonSexual,
  ReportReason.violence => context.l10n.reportReasonViolence,
  ReportReason.impersonation => context.l10n.reportReasonImpersonation,
  ReportReason.other => context.l10n.reportReasonOther,
};

/// Reason picker for reporting a piece of content.
///
/// One tap files the report — no second confirmation. Reporting costs the
/// reporter nothing and hides nothing on its own, so an extra dialog would only
/// discourage people from flagging real abuse.
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
}) {
  return BatshSheet.show<void>(
    context,
    contentPadding: const EdgeInsets.all(BatshSpacing.gutter),
    builder: (_) => _ReportSheet(target: target, targetId: targetId),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.target, required this.targetId});

  final ReportTarget target;
  final String targetId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  bool _busy = false;

  Future<void> _submit(ReportReason reason) async {
    if (_busy) return;
    setState(() => _busy = true);
    // Captured before the await: popping the sheet invalidates this context,
    // and the snackbar has to outlive it.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final filed = await ref
          .read(moderationRepositoryProvider)
          .report(
            target: widget.target,
            targetId: widget.targetId,
            reason: reason,
          );
      if (!mounted) return;
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              filed ? context.l10n.reportSent : context.l10n.reportAlreadySent,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(ErrorMapper.map(e)),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.reportTitle,
          textAlign: TextAlign.center,
          style: BatshTypography.titleLg,
        ),
        const SizedBox(height: BatshSpacing.xs),
        Text(
          context.l10n.reportSheetSubtitle,
          textAlign: TextAlign.center,
          style: BatshTypography.bodySm.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.md),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(BatshSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          for (final reason in ReportReason.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _reasonLabel(context, reason),
                style: BatshTypography.bodyMd,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: BatshIconSize.sm,
                color: context.colorScheme.onSurfaceVariant,
              ),
              onTap: () => _submit(reason),
            ),
      ],
    );
  }
}

/// Confirms, then blocks. Unlike reporting, this asks first: it immediately
/// changes what both people can see.
Future<bool> confirmAndBlock(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final ok = await BatshDialog.confirm(
    context,
    title: context.l10n.blockUserTitle,
    message: context.l10n.blockUserBody,
    confirmLabel: context.l10n.blockUser,
    cancelLabel: context.l10n.cancel,
    isDestructive: true,
  );
  if (ok != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(moderationRepositoryProvider).block(userId);
    if (!context.mounted) return false;
    ref.invalidate(blockedIdsProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.userBlocked),
          behavior: SnackBarBehavior.floating,
        ),
      );
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ErrorMapper.map(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    return false;
  }
}
