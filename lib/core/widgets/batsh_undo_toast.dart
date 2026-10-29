import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_typography.dart';

/// Production-grade reversible feedback toast (Pattern 5: Undo Toasts).
/// Displays a clear confirmation with an immediate "تراجع" (Undo) action.
class BatshUndoToast {
  const BatshUndoToast._();

  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    String? undoLabel,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: BatshTypography.bodyMd.copyWith(color: BatshColors.inverseOnSurface),
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BatshRadius.brMd),
        backgroundColor: BatshColors.inverseSurface,
        action: SnackBarAction(
          label: undoLabel ?? S.undo,
          textColor: BatshColors.inversePrimary,
          onPressed: onUndo,
        ),
      ),
    );
  }
}
