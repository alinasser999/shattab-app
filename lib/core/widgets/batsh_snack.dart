import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_icon_size.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// What a piece of transient feedback is telling the user.
enum BatshSnackKind {
  /// Something the user asked for happened.
  success,

  /// Something the user asked for did not happen.
  error,

  /// Something happened that the user did not cause and cannot act on.
  info,
}

/// Transient feedback, in one place.
///
/// This replaces 77 hand-rolled `SnackBar` constructions. Each of those picked
/// its own colour, its own duration, and its own decision about whether to show
/// an icon, so a save confirmation on one screen could look like a network
/// failure on another.
///
/// It wraps Flutter's own `ScaffoldMessenger` rather than inventing a toast.
/// Users already know how a snackbar behaves, and a bespoke replacement would
/// have to re-earn the dismissal, queueing and screen-reader behaviour that
/// comes free here.
///
/// ```dart
/// BatshSnack.success(context, context.l10n.changesSaved);
/// BatshSnack.error(context, context.l10n.quoteSendFailed);
/// ```
class BatshSnack {
  const BatshSnack._();

  /// Confirms an action the user took. Short, because the user already knows
  /// what they did and is only checking that it landed.
  static void success(BuildContext context, String message) =>
      show(context, message, kind: BatshSnackKind.success);

  /// Reports a failure. Held longer than [success], because the user has to
  /// read this one to know what to do next, and haptically distinct, because a
  /// failure the user does not notice is a failure they will repeat.
  static void error(BuildContext context, String message) =>
      show(context, message, kind: BatshSnackKind.error);

  /// Neutral notice. No haptic: nothing happened that the user caused.
  static void info(BuildContext context, String message) =>
      show(context, message, kind: BatshSnackKind.info);

  /// The general form. Prefer [success] / [error] / [info].
  ///
  /// [actionLabel] adds a single trailing button. Keep it to an undo or a
  /// retry: a snackbar auto-dismisses, so anything the user must not miss does
  /// not belong in one.
  static void show(
    BuildContext context,
    String message, {
    BatshSnackKind kind = BatshSnackKind.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // A queued backlog of stale feedback is worse than no feedback. The most
    // recent message is the only one still true.
    messenger.hideCurrentSnackBar();

    switch (kind) {
      case BatshSnackKind.success:
        HapticFeedback.lightImpact();
      case BatshSnackKind.error:
        HapticFeedback.heavyImpact();
      case BatshSnackKind.info:
        break;
    }

    final (background, foreground, icon) = switch (kind) {
      BatshSnackKind.success => (
        context.colorScheme.success,
        context.colorScheme.onSuccess,
        Icons.check_circle_outline,
      ),
      BatshSnackKind.error => (
        context.colorScheme.error,
        context.colorScheme.onError,
        Icons.error_outline,
      ),
      BatshSnackKind.info => (
        context.colorScheme.inverseSurface,
        context.colorScheme.inverseOnSurface,
        Icons.info_outline,
      ),
    };

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: BatshIconSize.action, color: foreground),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: BatshTypography.bodyMd.copyWith(color: foreground),
              ),
            ),
          ],
        ),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        // Lifted clear of the bottom edge. A snackbar sitting on the tab bar
        // hides the thing the user reaches for next.
        margin: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          0,
          BatshSpacing.md,
          BatshSpacing.md,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.md,
          vertical: BatshSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BatshRadius.brDefault,
        ),
        elevation: 0,
        duration: durationFor(kind),
        dismissDirection: DismissDirection.horizontal,
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: foreground,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// How long feedback of [kind] stays up.
  ///
  /// Errors get longer because they have to be read, not just noticed.
  static Duration durationFor(BatshSnackKind kind) =>
      kind == BatshSnackKind.error
      ? const Duration(seconds: 5)
      : const Duration(seconds: 3);
}
