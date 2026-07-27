import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

/// A confirmation or destructive-confirmation dialog.
///
/// Replaces 25 raw `AlertDialog`/`showDialog` sites, each of which had its own
/// shape, its own button order, and its own idea of which action gets the
/// louder color. `confirm` always puts the safe action first and the
/// color-coded action last, so a user habituated to one confirm dialog reads
/// every other one the same way.
///
/// ```dart
/// final ok = await BatshDialog.confirm(
///   context,
///   title: S.signOutTitle,
///   message: S.signOutConfirmation,
///   confirmLabel: S.signOutButton,
///   isDestructive: true,
/// );
/// if (ok == true) ref.read(authRepositoryProvider).signOut();
/// ```
class BatshDialog {
  const BatshDialog._();

  /// Two-button confirm/cancel. Returns `true` if the user confirmed, `null`
  /// if dismissed (barrier tap, back button).
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BatshRadius.brXl),
        backgroundColor: BatshColors.surface,
        title: Text(title, style: BatshTypography.titleMd),
        content: Text(message, style: BatshTypography.bodyMd),
        actionsPadding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          0,
          BatshSpacing.md,
          BatshSpacing.sm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel ?? S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel ?? S.confirm,
              style: TextStyle(
                color: isDestructive ? BatshColors.error : BatshColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single-button acknowledgement. For information the user must see but
  /// cannot act on two ways — an error detail, an explanation.
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String? dismissLabel,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BatshRadius.brXl),
        backgroundColor: BatshColors.surface,
        title: Text(title, style: BatshTypography.titleMd),
        content: Text(message, style: BatshTypography.bodyMd),
        actionsPadding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          0,
          BatshSpacing.md,
          BatshSpacing.sm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(dismissLabel ?? S.ok),
          ),
        ],
      ),
    );
  }
}
