import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/error_mapper.dart';
import '../data/moderation_repository.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_dialog.dart';

String _reasonLabel(ReportReason r) => switch (r) {
  ReportReason.spam => S.reportReasonSpam,
  ReportReason.scam => S.reportReasonScam,
  ReportReason.offensive => S.reportReasonOffensive,
  ReportReason.sexual => S.reportReasonSexual,
  ReportReason.violence => S.reportReasonViolence,
  ReportReason.impersonation => S.reportReasonImpersonation,
  ReportReason.other => S.reportReasonOther,
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
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: BatshColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
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
            content: Text(filed ? S.reportSent : S.reportAlreadySent),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BatshColors.outlineVariant,
                  borderRadius: BatshRadius.brFull,
                ),
              ),
            ),
            const SizedBox(height: BatshSpacing.md),
            Text(
              S.reportTitle,
              textAlign: TextAlign.center,
              style: BatshTypography.titleLg,
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              S.reportSheetSubtitle,
              textAlign: TextAlign.center,
              style: BatshTypography.bodySm.copyWith(
                color: BatshColors.onSurfaceVariant,
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
                    _reasonLabel(reason),
                    style: BatshTypography.bodyMd,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: BatshIconSize.sm,
                    color: BatshColors.onSurfaceVariant,
                  ),
                  onTap: () => _submit(reason),
                ),
          ],
        ),
      ),
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
    title: S.blockUserTitle,
    message: S.blockUserBody,
    confirmLabel: S.blockUser,
    cancelLabel: S.cancel,
    isDestructive: true,
  );
  if (ok != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(moderationRepositoryProvider).block(userId);
    ref.invalidate(blockedIdsProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(S.userBlocked),
          behavior: SnackBarBehavior.floating,
        ),
      );
    return true;
  } catch (e) {
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
