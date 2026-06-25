import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_card.dart';
import '../../../core/widgets/batsh_scaffold.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.construction_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BatshScaffold(
      title: title,
      body: Center(
        child: BatshCard(
          padding: const EdgeInsets.all(BatshSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: BatshColors.tertiary, size: 48),
              const SizedBox(height: BatshSpacing.gutter),
              Text(S.comingSoon, style: BatshTypography.titleLg),
              const SizedBox(height: BatshSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: BatshTypography.bodyMd
                    .copyWith(color: BatshColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
