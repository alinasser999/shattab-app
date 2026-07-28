import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';
import 'batsh_snack.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Big primary WhatsApp CTA. Opens whatsapp://send?phone=...
/// How much of the screen a contact action is allowed to own.
///
/// [subdued] is the default and the right answer nearly everywhere: an
/// outlined button whose only WhatsApp green is the glyph. [brand] fills with
/// `#25D366`, and is for a surface where contacting really is the single
/// thing left to do.
enum ContactEmphasis { subdued, brand }

class WhatsAppButton extends StatelessWidget {
  const WhatsAppButton({
    super.key,
    required this.phone,
    this.message,
    this.emphasis = ContactEmphasis.subdued,
  });

  final String phone;
  final String? message;

  /// Defaults to [ContactEmphasis.subdued].
  ///
  /// This was a full-width `#25D366` fill on every screen that had one, which
  /// made Meta's brand colour the most saturated element on the page —
  /// including the contractor profile, where the hiring decision happens and
  /// the platform's own action sat underneath it in grey. A screen gets one
  /// primary action, and on a marketplace that action is not "leave for
  /// WhatsApp".
  final ContactEmphasis emphasis;

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
      BatshSnack.error(context, context.l10n.couldNotOpenApp);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The label stays visible in both emphases. An icon-only contact button
    // would be smaller and quieter, but a bare glyph is the one form users
    // reliably fail to decode, and it costs screen-reader users the action.
    return Semantics(
      button: true,
      label: context.l10n.contactViaWhatsApp,
      child: emphasis == ContactEmphasis.brand
          ? _brand(context)
          : _subdued(context),
    );
  }

  /// Outlined, sized and coloured to match [CallButton] so the two read as one
  /// pair of secondary actions rather than two unrelated controls. The green
  /// survives only in the glyph, which is enough to identify the app without
  /// handing a third party the loudest surface on the screen.
  Widget _subdued(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(
        Icons.chat_bubble_outline,
        size: BatshIconSize.md,
        color: BatshColors.whatsApp,
      ),
      // Just "واتساب" here, not "تواصل عبر واتساب". At half width on a 360dp
      // screen the full phrase leaves about 94dp for text and would truncate,
      // and a truncated label on a primary contact route is worse than a
      // terse one. The Semantics wrapper above still announces the full
      // sentence, so nothing is lost to a screen reader.
      label: Text(context.l10n.whatsappShort),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colorScheme.onSurface,
        side: BorderSide(color: context.colorScheme.outline),
        minimumSize: const Size.fromHeight(BatshSpacing.minHitArea),
      ),
    );
  }

  Widget _brand(BuildContext context) {
    return Material(
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
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: BatshIconSize.md,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Text(
                context.l10n.contactViaWhatsApp,
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
      BatshSnack.error(context, context.l10n.couldNotOpenApp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.call,
      child: OutlinedButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.call_outlined, size: BatshIconSize.md),
        label: Text(context.l10n.call),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colorScheme.primary,
          side: BorderSide(color: context.colorScheme.outline),
          minimumSize: const Size.fromHeight(BatshSpacing.minHitArea),
        ),
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
      '${context.l10n.phone}: $phone',
      style: BatshTypography.bodyMd.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
