import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/models/draft_photo.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/photo_picker.dart';
import '../data/payment_repository.dart';
import '../pricing.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_snack.dart';

/// Opens the payment-method chooser, then routes to the chosen flow.
/// InstaPay is functional (manual verify); Apple Pay is pending a processor.
Future<void> showPaymentMethods(BuildContext context,
    {required bool annual}) async {
  final method = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MethodsSheet(),
  );
  if (!context.mounted || method == null) return;
  if (method == 'instapay') {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InstaPayScreen(annual: annual)),
    );
  } else if (method == 'applepay') {
    BatshSnack.info(context, S.applePaySoon);
  }
}

class _MethodsSheet extends StatelessWidget {
  const _MethodsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: BatshColors.surfaceContainerLowest,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(BatshRadius.xl)),
        ),
        padding: const EdgeInsets.fromLTRB(BatshSpacing.gutter, BatshSpacing.md,
            BatshSpacing.gutter, BatshSpacing.gutter),
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
            const SizedBox(height: BatshSpacing.lg),
            Text(S.choosePaymentMethod, style: BatshTypography.titleLg),
            const SizedBox(height: BatshSpacing.md),
            _MethodTile(
              icon: Icons.swap_horiz_rounded,
              title: S.payInstapay,
              subtitle: S.payInstapaySub,
              onTap: () => Navigator.of(context).pop('instapay'),
            ),
            const SizedBox(height: BatshSpacing.sm),
            _MethodTile(
              icon: Icons.apple_rounded,
              title: S.payApplePay,
              subtitle: S.payApplePaySub,
              soon: true,
              onTap: () => Navigator.of(context).pop('applepay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.soon = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    final tint = soon ? BatshColors.onSurfaceVariant : BatshColors.primary;
    return Material(
      color: BatshColors.surfaceContainerLow,
      borderRadius: BatshRadius.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.all(BatshSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: soon
                      ? BatshColors.surfaceContainerHigh
                      : BatshColors.primaryFixed,
                  borderRadius: BatshRadius.brMd,
                ),
                child: Icon(icon, color: tint),
              ),
              const SizedBox(width: BatshSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: BatshTypography.titleMd),
                        if (soon) ...[
                          const SizedBox(width: BatshSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: BatshSpacing.xs, vertical: 1),
                            decoration: BoxDecoration(
                              color: BatshColors.surfaceContainerHighest,
                              borderRadius: BatshRadius.brFull,
                            ),
                            child: Text(S.paySoonBadge,
                                style: BatshTypography.labelSm.copyWith(
                                    color: BatshColors.onSurfaceVariant)),
                          ),
                        ],
                      ],
                    ),
                    Text(subtitle,
                        style: BatshTypography.bodySm.copyWith(
                            color: BatshColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded,
                  color: BatshColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── InstaPay flow ────────────────────────────────────────────────────────────

class InstaPayScreen extends ConsumerStatefulWidget {
  const InstaPayScreen({super.key, required this.annual});
  final bool annual;

  @override
  ConsumerState<InstaPayScreen> createState() => _InstaPayScreenState();
}

class _InstaPayScreenState extends ConsumerState<InstaPayScreen> {
  final _refController = TextEditingController();
  DraftPhoto? _proof;
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_proof == null) {
      BatshSnack.error(context, S.instapayProofRequired);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(paymentRepositoryProvider).submitInstapay(
            purpose: 'pro',
            planTerm: widget.annual ? 'annual' : 'monthly',
            amountEgp: BatshPricing.proPrice(annual: widget.annual),
            proofFile: _proof!.file,
            proofBytes: _proof!.bytes,
            reference: _refController.text.trim().isEmpty
                ? null
                : _refController.text.trim(),
          );
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        BatshSnack.error(context, S.instapayError);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BatshColors.surface,
      appBar: AppBar(title: Text(S.instapayTitle)),
      body: _submitted ? _success() : _form(),
    );
  }

  Widget _form() {
    final amount = BatshPricing.proPrice(annual: widget.annual);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BatshSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoCard(
            label: S.instapayAmountLabel,
            child: Text(S.money(amount),
                style: BatshTypography.displayMd
                    .copyWith(color: BatshColors.primary)),
          ),
          const SizedBox(height: BatshSpacing.md),
          _infoCard(
            label: S.instapayNumberLabel,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    BatshPricing.instapayNumber,
                    style: BatshTypography.headlineSm
                        .copyWith(letterSpacing: 1.5),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(
                        text: BatshPricing.instapayNumber));
                    BatshSnack.info(context, S.copiedToast);
                  },
                  icon: const Icon(Icons.copy_rounded, size: BatshIconSize.md),
                  label: Text(S.copyAction),
                ),
              ],
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          Text(S.instapayUploadLabel, style: BatshTypography.labelLg),
          const SizedBox(height: BatshSpacing.sm),
          PhotoPicker(
            maxPhotos: 1,
            onChanged: (photos) =>
                setState(() => _proof = photos.isEmpty ? null : photos.first),
          ),
          const SizedBox(height: BatshSpacing.lg),
          TextField(
            controller: _refController,
            decoration: InputDecoration(labelText: S.instapayRefLabel),
          ),
          const SizedBox(height: BatshSpacing.xl),
          BatshButton(
            label: S.instapaySubmit,
            icon: Icons.send_rounded,
            isLoading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String label, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        boxShadow: BatshShadows.soft,
      ),
      padding: const EdgeInsets.all(BatshSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: BatshTypography.labelMd
                  .copyWith(color: BatshColors.onSurfaceVariant)),
          const SizedBox(height: BatshSpacing.xs),
          child,
        ],
      ),
    );
  }

  Widget _success() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: BatshIconSize.xxl, color: BatshColors.secondary),
            const SizedBox(height: BatshSpacing.lg),
            Text(S.instapaySubmittedTitle,
                textAlign: TextAlign.center,
                style: BatshTypography.headlineSm),
            const SizedBox(height: BatshSpacing.sm),
            Text(S.instapaySubmittedBody,
                textAlign: TextAlign.center,
                style: BatshTypography.bodyMd
                    .copyWith(color: BatshColors.onSurfaceVariant)),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.instapayDone,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
