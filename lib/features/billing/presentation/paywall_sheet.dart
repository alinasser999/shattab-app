import 'package:flutter/material.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_sheet.dart';
import '../../../core/widgets/batsh_snack.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Pro upgrade paywall. Presentational STUB: benefits + subscribe button.
/// The button is inert until Paymob is wired (create-payment edge fn) -- it
/// surfaces a "coming soon" notice for now. When keys exist, replace the
/// onPressed body with the Paymob checkout launch (open CheckoutWebview with
/// the URL from the create-payment edge function).
Future<void> showPaywallSheet(BuildContext context, {String purpose = 'pro'}) {
  return BatshSheet.show<void>(
    context,
    contentPadding: const EdgeInsets.fromLTRB(
      BatshSpacing.gutter,
      0,
      BatshSpacing.gutter,
      BatshSpacing.gutter,
    ),
    builder: (_) => const _PaywallSheet(),
  );
}

class _PaywallSheet extends StatelessWidget {
  const _PaywallSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(BatshSpacing.sm),
              decoration: BoxDecoration(
                color: context.colorScheme.primaryFixed,
                borderRadius: BatshRadius.brMd,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: context.colorScheme.primary,
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.paywallTitle,
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.l10n.paywallSubtitle,
                    style: BatshTypography.bodySm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
          label: context.l10n.upgradeToProCta,
          icon: Icons.workspace_premium_outlined,
          onPressed: () {
            Navigator.of(context).pop();
            BatshSnack.info(context, context.l10n.paymentComingSoon);
          },
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.getter});
  final int getter;

  String get _text => switch (getter) {
    0 => 'Quotes',
    1 => 'Requests',
    2 => 'Ranking',
    _ => 'Photos',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: BatshIconSize.md,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(child: Text(_text, style: BatshTypography.bodyMd)),
        ],
      ),
    );
  }
}
