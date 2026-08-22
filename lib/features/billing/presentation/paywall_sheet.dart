import 'dart:async';

import 'package:flutter/material.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_sheet.dart';
import 'payment_flow.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Pro upgrade paywall. The CTA opens the supported payment-method flow.
Future<void> showPaywallSheet(BuildContext context, {String purpose = 'pro'}) {
  return BatshSheet.show<void>(
    context,
    contentPadding: const EdgeInsets.fromLTRB(
      BatshSpacing.gutter,
      0,
      BatshSpacing.gutter,
      BatshSpacing.gutter,
    ),
    builder: (_) => _PaywallSheet(
      purpose: purpose,
      onSubscribe: () {
        Navigator.of(context).pop();
        unawaited(
          showPaymentMethods(
            context,
            annual: false,
            purpose: purpose,
            planTerm: purpose == 'sponsored' ? 'weekly' : null,
          ),
        );
      },
    ),
  );
}

class _PaywallSheet extends StatelessWidget {
  const _PaywallSheet({required this.onSubscribe, required this.purpose});

  final VoidCallback onSubscribe;
  final String purpose;

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
                    purpose == 'sponsored'
                        ? context.l10n.specialProTitle
                        : context.l10n.paywallTitle,
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    purpose == 'sponsored'
                        ? context.l10n.specialProSubtitle
                        : context.l10n.paywallSubtitle,
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
        if (purpose == 'sponsored') ...[
          _Benefit(text: context.l10n.specialProBenefit),
          _Benefit(text: context.l10n.specialProFairness),
          _Benefit(text: context.l10n.specialProNoGuarantee),
        ] else ...[
          _Benefit(text: context.l10n.proBenefitQuotes),
          _Benefit(text: context.l10n.proBenefitRequests),
          _Benefit(text: context.l10n.proBenefitRanking),
          _Benefit(text: context.l10n.proBenefitPhotos),
        ],
        const SizedBox(height: BatshSpacing.lg),
        BatshButton(
          label: purpose == 'sponsored'
              ? context.l10n.specialProCta
              : context.l10n.upgradeToProCta,
          icon: purpose == 'sponsored'
              ? Icons.campaign_outlined
              : Icons.workspace_premium_outlined,
          onPressed: onSubscribe,
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});
  final String text;

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
          Expanded(child: Text(text, style: BatshTypography.bodyMd)),
        ],
      ),
    );
  }
}
