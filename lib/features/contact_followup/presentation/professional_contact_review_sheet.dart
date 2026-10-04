import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_sheet.dart';
import '../../../core/widgets/batsh_stars.dart';
import '../../../core/widgets/batsh_text_field.dart';
import 'providers/professional_contact_providers.dart';

Future<bool?> showProfessionalContactReviewSheet(
  BuildContext context, {
  required String episodeId,
  required String contractorId,
}) {
  return BatshSheet.show<bool>(
    context,
    contentPadding: EdgeInsets.zero,
    builder: (_) => _ProfessionalContactReviewSheet(
      episodeId: episodeId,
      contractorId: contractorId,
    ),
  );
}

class _ProfessionalContactReviewSheet extends ConsumerStatefulWidget {
  const _ProfessionalContactReviewSheet({
    required this.episodeId,
    required this.contractorId,
  });

  final String episodeId;
  final String contractorId;

  @override
  ConsumerState<_ProfessionalContactReviewSheet> createState() =>
      _ProfessionalContactReviewSheetState();
}

class _ProfessionalContactReviewSheetState
    extends ConsumerState<_ProfessionalContactReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_rating < 1) {
      setState(() => _error = context.l10n.selectStarsFirst);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final comment = _commentController.text.trim();
      await ref
          .read(professionalContactActionsProvider)
          .submitReview(
            episodeId: widget.episodeId,
            contractorId: widget.contractorId,
            rating: _rating,
            comment: comment.isEmpty ? null : comment,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.profileError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.marginMobile,
        BatshSpacing.xs,
        BatshSpacing.marginMobile,
        BatshSpacing.lg,
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
            context.l10n.professionalContactReviewFormIntro,
            textAlign: TextAlign.center,
            style: BatshTypography.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          BatshStarInput(
            value: _rating,
            onChanged: (value) {
              if (!_busy) setState(() => _rating = value);
            },
          ),
          const SizedBox(height: BatshSpacing.lg),
          BatshTextField(
            controller: _commentController,
            label: context.l10n.yourReview,
            hint: context.l10n.yourReviewHint,
            maxLines: 4,
            maxLength: 400,
            enabled: !_busy,
          ),
          if (_error != null) ...[
            const SizedBox(height: BatshSpacing.sm),
            Text(
              _error!,
              style: BatshTypography.labelMd.copyWith(
                color: Theme.of(context).colorScheme.error,
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
