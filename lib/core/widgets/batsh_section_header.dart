import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshSectionHeader extends StatelessWidget {
  const BatshSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          EdgeInsets.only(bottom: BatshSpacing.md, top: BatshSpacing.gutter),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              borderRadius: BatshRadius.brFull,
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: BatshTypography.titleMd.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
