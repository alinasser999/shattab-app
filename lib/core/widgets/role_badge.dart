import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

/// Marks whether a post's author is a contractor or a homeowner.
///
/// This is a trust surface, not decoration: a contractor showing work and a
/// homeowner asking for work need to read differently before the reader decides
/// whether to tap. The two roles therefore get different colour and a different
/// glyph, never colour alone — the icon and the label each carry the meaning on
/// their own, so it survives a greyscale or colour-blind read.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role, this.compact = false});

  /// Raw `author_role` from the database: `'contractor'` or `'homeowner'`.
  final String role;

  /// Tighter padding and label size for use inside a feed card.
  final bool compact;

  bool get _isContractor => role == 'contractor';

  @override
  Widget build(BuildContext context) {
    // Contractors carry the brand terracotta because they are the side being
    // evaluated. Homeowners get the calmer olive: informative, not a pitch.
    final color = _isContractor ? BatshColors.primary : BatshColors.secondary;
    final background = _isContractor
        ? BatshColors.primaryFixed.withValues(alpha: 0.35)
        : BatshColors.secondaryContainer;
    final label = _isContractor ? S.roleProfessional : S.roleHomeowner;
    final icon = _isContractor ? Icons.engineering_rounded : Icons.home_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? BatshSpacing.sm : BatshSpacing.md,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BatshRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style:
                (compact ? BatshTypography.labelSm : BatshTypography.labelMd)
                    .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
