import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

class BatshEmptyState extends StatelessWidget {
  const BatshEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(BatshSpacing.gutter),
              decoration: const BoxDecoration(
                color: BatshColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: BatshColors.tertiary, size: 40),
            ),
            const SizedBox(height: BatshSpacing.gutter),
            Text(title,
                textAlign: TextAlign.center,
                style: BatshTypography.titleLg),
            if (message != null) ...[
              const SizedBox(height: BatshSpacing.sm),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: BatshTypography.bodyMd
                      .copyWith(color: BatshColors.onSurfaceVariant)),
            ],
            if (action != null) ...[
              const SizedBox(height: BatshSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
