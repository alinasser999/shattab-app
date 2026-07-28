import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_stars.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../domain/review.dart';
import 'providers/reviews_providers.dart';
import '../../../core/widgets/batsh_sheet.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Opens the rate-contractor sheet. [existing] pre-fills when editing.
Future<void> showWriteReviewSheet(
  BuildContext context, {
  required String briefId,
  required String contractorId,
  Review? existing,
}) {
  return BatshSheet.show<void>(
    context,
    contentPadding: EdgeInsets.zero,
    builder: (_) => _WriteReviewSheet(
      briefId: briefId,
      contractorId: contractorId,
      existing: existing,
    ),
  );
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  const _WriteReviewSheet({
    required this.briefId,
    required this.contractorId,
    this.existing,
  });

  final String briefId;
  final String contractorId;
  final Review? existing;

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  late int _rating = widget.existing?.rating ?? 0;
  late final TextEditingController _commentCtrl = TextEditingController(
    text: widget.existing?.comment ?? '',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _error = context.l10n.selectStarsFirst);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final comment = _commentCtrl.text.trim();
      await ref
          .read(reviewControllerProvider.notifier)
          .submit(
            briefId: widget.briefId,
            contractorId: widget.contractorId,
            rating: _rating,
            comment: comment.isEmpty ? null : comment,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.profileError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        BatshSpacing.marginMobile,
        BatshSpacing.lg,
        BatshSpacing.marginMobile,
        BatshSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.rateContractor,
            textAlign: TextAlign.center,
            style: BatshTypography.titleLg,
          ),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            context.l10n.ratingHelpsOthers,
            textAlign: TextAlign.center,
            style: BatshTypography.bodyMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          BatshStarInput(
            value: _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: BatshSpacing.lg),
          BatshTextField(
            controller: _commentCtrl,
            label: context.l10n.yourReview,
            hint: context.l10n.yourReviewHint,
            maxLines: 4,
            maxLength: 400,
          ),
          if (_error != null) ...[
            const SizedBox(height: BatshSpacing.sm),
            Text(
              _error!,
              style: BatshTypography.labelMd.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: BatshSpacing.lg),
          BatshButton(
            label: context.l10n.submitReview,
            onPressed: _busy ? null : _submit,
            isLoading: _busy,
          ),
        ],
      ),
    );
  }
}
