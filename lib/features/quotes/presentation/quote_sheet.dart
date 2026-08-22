import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/services/form_draft_store.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_draft_status.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../domain/quote.dart';
import 'providers/quotes_providers.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_sheet.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../../core/widgets/shattab_pattern.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Opens the price-quote bottom sheet. Returns true if a quote was submitted.
Future<bool> showQuoteSheet(
  BuildContext context, {
  required String briefId,
  Quote? existing,
}) async {
  final result = await BatshSheet.show<bool>(
    context,
    contentPadding: EdgeInsets.zero,
    builder: (_) => _QuoteSheet(briefId: briefId, existing: existing),
  );
  return result ?? false;
}

class _QuoteSheet extends ConsumerStatefulWidget {
  const _QuoteSheet({required this.briefId, this.existing});
  final String briefId;
  final Quote? existing;

  @override
  ConsumerState<_QuoteSheet> createState() => _QuoteSheetState();
}

class _QuoteSheetState extends ConsumerState<_QuoteSheet> {
  late final TextEditingController _min;
  late final TextEditingController _max;
  late final TextEditingController _duration;
  late final TextEditingController _note;
  String? _noteError;
  String? _priceError;
  bool _submitting = false;
  bool _done = false;
  Timer? _draftTimer;
  bool _draftRestored = false;
  bool _draftSaved = false;

  String get _draftKey => 'quote:${widget.briefId}';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _min = TextEditingController(text: e?.priceMin?.toString() ?? '');
    _max = TextEditingController(text: e?.priceMax?.toString() ?? '');
    _duration = TextEditingController(text: e?.durationText ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    for (final controller in [_min, _max, _duration, _note]) {
      controller.addListener(_scheduleDraftSave);
    }
    unawaited(_restoreDraft());
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (!_done) unawaited(_persistDraft());
    for (final controller in [_min, _max, _duration, _note]) {
      controller.removeListener(_scheduleDraftSave);
    }
    _min.dispose();
    _max.dispose();
    _duration.dispose();
    _note.dispose();
    super.dispose();
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistDraft(showStatus: true));
    });
  }

  Future<void> _restoreDraft() async {
    final draft = await FormDraftStore.read(_draftKey);
    if (!mounted || draft == null || draft.isEmpty) return;
    _min.text = (draft['min'] as String?) ?? _min.text;
    _max.text = (draft['max'] as String?) ?? _max.text;
    _duration.text = (draft['duration'] as String?) ?? _duration.text;
    _note.text = (draft['note'] as String?) ?? _note.text;
    setState(() {
      _draftRestored = true;
      _draftSaved = true;
    });
  }

  Future<void> _persistDraft({bool showStatus = false}) async {
    final hasContent = [
      _min,
      _max,
      _duration,
      _note,
    ].any((controller) => controller.text.trim().isNotEmpty);
    if (!hasContent) {
      await FormDraftStore.clear(_draftKey);
      return;
    }
    await FormDraftStore.write(_draftKey, {
      'min': _min.text,
      'max': _max.text,
      'duration': _duration.text,
      'note': _note.text,
    });
    if (showStatus && mounted) setState(() => _draftSaved = true);
  }

  Future<void> _submit() async {
    final note = _note.text.trim();
    if (note.isEmpty) {
      setState(() => _noteError = context.l10n.quoteNoteRequired);
      return;
    }
    final minVal = int.tryParse(_min.text.trim());
    final maxVal = int.tryParse(_max.text.trim());
    if (minVal != null && maxVal != null && minVal > maxVal) {
      setState(() => _priceError = context.l10n.priceMinLessThanMax);
      return;
    }
    setState(() {
      _noteError = null;
      _priceError = null;
      _submitting = true;
    });
    try {
      await ref
          .read(quotesControllerProvider.notifier)
          .submit(
            briefId: widget.briefId,
            priceMin: minVal,
            priceMax: maxVal,
            durationText: _duration.text.trim().isEmpty
                ? null
                : _duration.text.trim(),
            note: note,
          );
      if (!mounted) return;
      await FormDraftStore.clear(_draftKey);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _done = true);
      await Future<void>.delayed(const Duration(milliseconds: 950));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      if (!mounted) return;
      AppLogger.error(
        'quote submission failed',
        error: error,
        stackTrace: stackTrace,
        context: {'brief_id': widget.briefId},
      );
      setState(() => _submitting = false);
      BatshSnack.error(context, ErrorMapper.map(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: BatshMotion.fast,
      padding: EdgeInsets.only(bottom: inset),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.marginMobile,
          BatshSpacing.gutter,
          BatshSpacing.marginMobile,
          BatshSpacing.lg,
        ),
        child: _done ? const _SuccessView() : _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.existing == null
              ? context.l10n.sendQuote
              : context.l10n.editQuote,
          style: BatshTypography.titleLg,
        ),
        if (_draftRestored || _draftSaved) ...[
          const SizedBox(height: BatshSpacing.xs),
          BatshDraftStatus(restored: _draftRestored),
        ],
        const SizedBox(height: BatshSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BatshTextField(
                controller: _min,
                label: context.l10n.priceFromLabel,
                hint: context.l10n.priceEgpHint,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: BatshTextField(
                controller: _max,
                label: context.l10n.priceToLabel,
                hint: context.l10n.priceEgpHint,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        if (_priceError != null)
          Padding(
            padding: const EdgeInsets.only(top: BatshSpacing.sm),
            child: Text(
              _priceError!,
              style: TextStyle(color: context.colorScheme.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: BatshSpacing.md),
        BatshTextField(
          controller: _duration,
          label: context.l10n.durationLabel,
          hint: context.l10n.durationHint,
        ),
        const SizedBox(height: BatshSpacing.md),
        BatshTextField(
          controller: _note,
          label: context.l10n.quoteNoteLabel,
          hint: context.l10n.quoteNoteHint,
          errorText: _noteError,
          maxLines: 4,
          maxLength: 500,
        ),
        const SizedBox(height: BatshSpacing.lg),
        BatshButton(
          label: context.l10n.submitQuote,
          icon: Icons.send_outlined,
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
        const SizedBox(height: BatshSpacing.sm),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brCard,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: ClipRRect(
        borderRadius: BatshRadius.brCard,
        child: Stack(
          children: [
            PositionedDirectional(
              top: -14,
              end: -8,
              width: 140,
              height: 110,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0.18,
                    child: ShattabPattern(
                      kind: ShattabPatternKind.terrazzo,
                      color: scheme.primary,
                      opacity: 0.32,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(BatshSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                        padding: const EdgeInsets.all(BatshSpacing.gutter),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: scheme.primary,
                          size: BatshIconSize.xxl,
                        ),
                      )
                      .animate()
                      .scale(
                        duration: 400.ms,
                        curve: BatshMotion.springCelebrate,
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1, 1),
                      )
                      .fadeIn(duration: 200.ms),
                  const SizedBox(height: BatshSpacing.gutter),
                  Text(
                    context.l10n.quoteSentTitle,
                    textAlign: TextAlign.center,
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                  const SizedBox(height: BatshSpacing.xs),
                  Text(
                    context.l10n.quoteSentMessage,
                    textAlign: TextAlign.center,
                    style: BatshTypography.bodyMd.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
