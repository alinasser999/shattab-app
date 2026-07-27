import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/theme/batsh_icon_size.dart';

/// Pro upgrade paywall. Presentational STUB: benefits + subscribe button.
/// The button is inert until Paymob is wired (create-payment edge fn) -- it
/// surfaces a "coming soon" notice for now. When keys exist, replace the
/// onPressed body with the Paymob checkout launch (open CheckoutWebview with
/// the URL from the create-payment edge function).
Future<void> showPaywallSheet(BuildContext context, {String purpose = 'pro'}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PaywallSheet(),
  );
}

class _PaywallSheet extends StatelessWidget {
  const _PaywallSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: BatshColors.surfaceContainerLowest,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(BatshRadius.xl)),
        ),
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.gutter,
          BatshSpacing.lg,
          BatshSpacing.gutter,
          BatshSpacing.gutter,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(BatshSpacing.sm),
                  decoration: BoxDecoration(
                    color: BatshColors.primaryFixed,
                    borderRadius: BatshRadius.brMd,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: BatshColors.primary),
                ),
                const SizedBox(width: BatshSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.paywallTitle,
                          style: BatshTypography.titleLg
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(S.paywallSubtitle,
                          style: BatshTypography.bodySm.copyWith(
                              color: BatshColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BatshSpacing.lg),
            const _Benefit(getter: 0),
            const _Benefit(getter: 1),
            const _Benefit(getter: 2),
            const _Benefit(getter: 3),
            const SizedBox(height: BatshSpacing.lg),
            BatshButton(
              label: S.upgradeToProCta,
              icon: Icons.workspace_premium_outlined,
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.paymentComingSoon)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.getter});
  final int getter;

  String get _text => switch (getter) {
        0 => S.proBenefitQuotes,
        1 => S.proBenefitRequests,
        2 => S.proBenefitRanking,
        _ => S.proBenefitPhotos,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              size: BatshIconSize.md, color: BatshColors.primary),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(child: Text(_text, style: BatshTypography.bodyMd)),
        ],
      ),
    );
  }
}