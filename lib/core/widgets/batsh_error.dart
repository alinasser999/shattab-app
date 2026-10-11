import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_extension.dart';
import '../utils/connectivity.dart';

import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import 'batsh_button.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshError extends ConsumerWidget {
  const BatshError({
    super.key,
    this.message,
    this.onRetry,
    this.compact = false,
  });
  final String? message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(connectivityProvider, (previous, next) {
      if (previous?.value == false && next.value == true) onRetry?.call();
    });
    final offline = ref.watch(connectivityProvider).value == false;
    final resolved = offline
        ? context.l10n.errNetwork
        : message ?? context.l10n.unknownErrorRetry;
    final content = Padding(
      padding: EdgeInsets.all(compact ? BatshSpacing.md : BatshSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.error_outline_rounded,
              color: context.colorScheme.error,
              size: compact ? 24 : 40,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              resolved,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: BatshSpacing.sm),
            BatshButton(
              label: context.l10n.tryAgain,
              onPressed: onRetry,
              fullWidth: !compact,
              style: compact
                  ? BatshButtonStyle.ghost
                  : BatshButtonStyle.secondary,
            ),
          ],
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (compact || !constraints.hasBoundedHeight) return content;
        return Center(child: SingleChildScrollView(child: content));
      },
    );
  }
}
