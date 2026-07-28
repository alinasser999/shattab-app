import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:batsh/core/l10n/strings.dart';
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
import '../../../core/widgets/batsh_sheet.dart';
import '../../../core/widgets/batsh_snack.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Opens the payment-method chooser, then routes to the chosen flow.
/// InstaPay is functional (manual verify); Apple Pay is pending a processor.
Future<void> showPaymentMethods(
  BuildContext context, {
  required bool annual,
}) async {
  final method = await BatshSheet.show<String>(
    context,
    builder: (_) => const _MethodsSheet(),
  );
  if (!context.mounted || method == null) return;
  if (method == 'instapay') {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => InstaPayScreen(annual: annual)));
  } else if (method == 'applepay') {
    BatshSnack.info(context, context.l10n.applePaySoon);
  }
}

class _MethodsSheet extends StatelessWidget {
  const _MethodsSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.choosePaymentMethod, style: BatshTypography.titleLg),
        const SizedBox(height: BatshSpacing.md),
        _MethodTile(
          icon: Icons.swap_horiz_rounded,
          title: context.l10n.payInstapay,
          subtitle: context.l10n.payInstapaySub,
          onTap: () => Navigator.of(context).pop('instapay'),
        ),
        const SizedBox(height: BatshSpacing.sm),
        _MethodTile(
          icon: Icons.apple_rounded,
          title: context.l10n.payApplePay,
          subtitle: context.l10n.payApplePaySub,
          soon: true,
          onTap: () => Navigator.of(context).pop('applepay'),
        ),
      ],
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
    final tint = soon
        ? context.colorScheme.onSurfaceVariant
        : context.colorScheme.primary;
    return Material(
      color: context.colorScheme.surfaceContainerLow,
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
                      ? context.colorScheme.surfaceContainerHigh
                      : context.colorScheme.primaryFixed,
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
                              horizontal: BatshSpacing.xs,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  context.colorScheme.surfaceContainerHighest,
                              borderRadius: BatshRadius.brFull,
                            ),
                            child: Text(
                              context.l10n.paySoonBadge,
                              style: BatshTypography.labelSm.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: BatshTypography.bodySm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: context.colorScheme.onSurfaceVariant,
              ),
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
      BatshSnack.error(context, context.l10n.instapayProofRequired);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .submitInstapay(
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
        BatshSnack.error(context, context.l10n.instapayError);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(title: Text(context.l10n.instapayTitle)),
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
            label: context.l10n.instapayAmountLabel,
            child: Text(
              S.money(amount),
              style: BatshTypography.displayMd.copyWith(
                color: context.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          _infoCard(
            label: context.l10n.instapayNumberLabel,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    BatshPricing.instapayNumber,
                    style: BatshTypography.headlineSm.copyWith(
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      const ClipboardData(text: BatshPricing.instapayNumber),
                    );
                    BatshSnack.info(context, context.l10n.copiedToast);
                  },
                  icon: const Icon(Icons.copy_rounded, size: BatshIconSize.md),
                  label: Text(context.l10n.copyAction),
                ),
              ],
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          Text(
            context.l10n.instapayUploadLabel,
            style: BatshTypography.labelLg,
          ),
          const SizedBox(height: BatshSpacing.sm),
          PhotoPicker(
            maxPhotos: 1,
            onChanged: (photos) =>
                setState(() => _proof = photos.isEmpty ? null : photos.first),
          ),
          const SizedBox(height: BatshSpacing.lg),
          TextField(
            controller: _refController,
            decoration: InputDecoration(
              labelText: context.l10n.instapayRefLabel,
            ),
          ),
          const SizedBox(height: BatshSpacing.xl),
          BatshButton(
            label: context.l10n.instapaySubmit,
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
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        boxShadow: BatshShadows.soft,
      ),
      padding: const EdgeInsets.all(BatshSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
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
            Icon(
              Icons.check_circle_rounded,
              size: BatshIconSize.xxl,
              color: context.colorScheme.secondary,
            ),
            const SizedBox(height: BatshSpacing.lg),
            Text(
              context.l10n.instapaySubmittedTitle,
              textAlign: TextAlign.center,
              style: BatshTypography.headlineSm,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              context.l10n.instapaySubmittedBody,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: context.l10n.instapayDone,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
