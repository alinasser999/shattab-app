import 'package:flutter/material.dart';

import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// A bottom sheet with the drag handle, shape, and padding fixed in one
/// place.
///
/// Replaces 8 raw `showModalBottomSheet` sites, each of which set
/// `isScrollControlled` and the corner shape independently — a couple forgot
/// the handle entirely, which is the one visual cue that tells a user the
/// sheet is draggable rather than just another screen.
///
/// [contentPadding] wraps [child]; leave it null for sheets that manage their
/// own scroll padding (a `ListView` that needs edge-to-edge dividers, for
/// instance).
///
/// ```dart
/// final result = await BatshSheet.show<bool>(
///   context,
///   builder: (ctx) => QuoteSheetContent(brief: brief),
/// );
/// ```
class BatshSheet {
  const BatshSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    EdgeInsetsGeometry? contentPadding = const EdgeInsets.all(BatshSpacing.md),
    bool isDismissible = true,
    bool enableDrag = true,
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (ctx) => _BatshSheetChrome(
        contentPadding: contentPadding,
        child: builder(ctx),
      ),
    );
  }
}

class _BatshSheetChrome extends StatelessWidget {
  const _BatshSheetChrome({required this.child, required this.contentPadding});

  final Widget child;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BatshRadius.xxl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: contentPadding ?? EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: BatshSpacing.xs),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BatshRadius.brFull,
                ),
              ),
              const SizedBox(height: BatshSpacing.sm),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
