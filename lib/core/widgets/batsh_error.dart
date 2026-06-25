import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import 'batsh_button.dart';

class BatshError extends StatelessWidget {
  const BatshError({
    super.key,
    this.message,
    this.onRetry,
  });

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: BatshColors.error,
              size: 48,
            ),
            const SizedBox(height: BatshSpacing.gutter),
            Text(
              message ?? S.unknownErrorRetry,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyLg,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: BatshSpacing.lg),
              BatshButton(
                label: 'حاول تاني',
                onPressed: onRetry,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
