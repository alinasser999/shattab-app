import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../domain/quote.dart';
import 'providers/quotes_providers.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_sheet.dart';
import '../../../core/widgets/batsh_snack.dart';

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

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _min = TextEditingController(text: e?.priceMin?.toString() ?? '');
    _max = TextEditingController(text: e?.priceMax?.toString() ?? '');
    _duration = TextEditingController(text: e?.durationText ?? '');
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _duration.dispose();
    _note.dispose();
    super.dispose();
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
      HapticFeedback.mediumImpact();
      setState(() => _done = true);
      await Future<void>.delayed(const Duration(milliseconds: 950));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      BatshSnack.error(context, context.l10n.unknownErrorRetry);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BatshSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                padding: const EdgeInsets.all(BatshSpacing.gutter),
                decoration: BoxDecoration(
                  color: context.colorScheme.successContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: context.colorScheme.success,
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
            context.l10n.quoteSentSuccess,
            style: BatshTypography.titleLg,
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
        ],
      ),
    );
  }
}
