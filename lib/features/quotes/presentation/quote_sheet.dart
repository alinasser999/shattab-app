import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../domain/quote.dart';
import 'providers/quotes_providers.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_snack.dart';

/// Opens the price-quote bottom sheet. Returns true if a quote was submitted.
Future<bool> showQuoteSheet(
  BuildContext context, {
  required String briefId,
  Quote? existing,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: BatshColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(BatshRadius.xl)),
    ),
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
      setState(() => _noteError = S.quoteNoteRequired);
      return;
    }
    final minVal = int.tryParse(_min.text.trim());
    final maxVal = int.tryParse(_max.text.trim());
    if (minVal != null && maxVal != null && minVal > maxVal) {
      setState(() => _priceError = S.priceMinLessThanMax);
      return;
    }
    setState(() {
      _noteError = null;
      _priceError = null;
      _submitting = true;
    });
    try {
      await ref.read(quotesControllerProvider.notifier).submit(
            briefId: widget.briefId,
            priceMin: minVal,
            priceMax: maxVal,
            durationText:
                _duration.text.trim().isEmpty ? null : _duration.text.trim(),
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
      BatshSnack.error(context, S.unknownErrorRetry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: BatshMotion.fast,
      padding: EdgeInsets.only(bottom: inset),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(BatshSpacing.marginMobile,
            BatshSpacing.gutter, BatshSpacing.marginMobile, BatshSpacing.lg),
        child: _done ? const _SuccessView() : _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
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
        const SizedBox(height: BatshSpacing.gutter),
        Text(widget.existing == null ? S.sendQuote : S.editQuote,
            style: BatshTypography.titleLg),
        const SizedBox(height: BatshSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BatshTextField(
                controller: _min,
                label: S.priceFromLabel,
                hint: S.priceEgpHint,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: BatshTextField(
                controller: _max,
                label: S.priceToLabel,
                hint: S.priceEgpHint,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        if (_priceError != null)
          Padding(
            padding: const EdgeInsets.only(top: BatshSpacing.sm),
            child: Text(_priceError!,
                style: TextStyle(color: BatshColors.error, fontSize: 12)),
          ),
        const SizedBox(height: BatshSpacing.md),
        BatshTextField(
          controller: _duration,
          label: S.durationLabel,
          hint: S.durationHint,
        ),
        const SizedBox(height: BatshSpacing.md),
        BatshTextField(
          controller: _note,
          label: S.quoteNoteLabel,
          hint: S.quoteNoteHint,
          errorText: _noteError,
          maxLines: 4,
          maxLength: 500,
        ),
        const SizedBox(height: BatshSpacing.lg),
        BatshButton(
          label: S.submitQuote,
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
            decoration: const BoxDecoration(
              color: BatshColors.successContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: BatshColors.success, size: BatshIconSize.xxl),
          )
              .animate()
              .scale(
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1, 1))
              .fadeIn(duration: 200.ms),
          const SizedBox(height: BatshSpacing.gutter),
          Text(S.quoteSentSuccess, style: BatshTypography.titleLg)
              .animate()
              .fadeIn(delay: 150.ms, duration: 300.ms),
        ],
      ),
    );
  }
}