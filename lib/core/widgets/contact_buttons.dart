import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';
import 'batsh_snack.dart';

/// Big primary WhatsApp CTA. Opens whatsapp://send?phone=...
class WhatsAppButton extends StatelessWidget {
  const WhatsAppButton({super.key, required this.phone, this.message});

  final String phone;
  final String? message;

  Future<void> _open(BuildContext context) async {
    HapticFeedback.lightImpact();
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
      'https://wa.me/$cleaned${message != null ? '?text=${Uri.encodeComponent(message!)}' : ''}',
    );
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      BatshSnack.error(context, S.couldNotOpenApp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, label: S.contactViaWhatsApp, child: Material(
      color: BatshColors.whatsApp,
      borderRadius: BatshRadius.brDefault,
      child: InkWell(
        borderRadius: BatshRadius.brDefault,
        onTap: () => _open(context),
        child: Container(
          height: BatshSpacing.minHitArea,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: BatshIconSize.md),
              const SizedBox(width: BatshSpacing.sm),
              Text(
                S.contactViaWhatsApp,
                style: BatshTypography.labelMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

/// Secondary call button. Opens tel:
class CallButton extends StatelessWidget {
  const CallButton({super.key, required this.phone});

  final String phone;

  Future<void> _open(BuildContext context) async {
    HapticFeedback.lightImpact();
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      BatshSnack.error(context, S.couldNotOpenApp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, label: S.call, child: OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.call_outlined, size: BatshIconSize.md),
      label: Text(S.call),
      style: OutlinedButton.styleFrom(
        foregroundColor: BatshColors.primary,
        side: const BorderSide(color: BatshColors.outline),
        minimumSize: const Size.fromHeight(BatshSpacing.minHitArea),
      ),
    ));
  }
}

/// Inline labelled phone display: "تليفون: +20 10 ..."
class PhoneInline extends StatelessWidget {
  const PhoneInline({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${S.phone}: $phone',
      style: BatshTypography.bodyMd
          .copyWith(color: BatshColors.onSurfaceVariant),
    );
  }
}
