import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

/// Big primary WhatsApp CTA. Opens whatsapp://send?phone=...
class WhatsAppButton extends StatelessWidget {
  const WhatsAppButton({super.key, required this.phone, this.message});

  final String phone;
  final String? message;

  Future<void> _open() async {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
      'https://wa.me/$cleaned${message != null ? '?text=${Uri.encodeComponent(message!)}' : ''}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF25D366),
      borderRadius: BatshRadius.brDefault,
      child: InkWell(
        borderRadius: BatshRadius.brDefault,
        onTap: _open,
        child: Container(
          height: BatshSpacing.minHitArea,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: 20),
              const SizedBox(width: BatshSpacing.sm),
              Text(
                'تواصل عبر واتساب',
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
    );
  }
}

/// Secondary call button. Opens tel:
class CallButton extends StatelessWidget {
  const CallButton({super.key, required this.phone});

  final String phone;

  Future<void> _open() async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _open,
      icon: const Icon(Icons.call_outlined, size: 20),
      label: const Text('اتصل'),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: BatshColors.outline),
        minimumSize: const Size.fromHeight(BatshSpacing.minHitArea),
      ),
    );
  }
}

/// Inline labelled phone display: "تليفون: +20 10 ..."
class PhoneInline extends StatelessWidget {
  const PhoneInline({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${S.appName == 'شطب' ? 'تليفون' : 'Phone'}: $phone',
      style: BatshTypography.bodyMd
          .copyWith(color: BatshColors.onSurfaceVariant),
    );
  }
}
