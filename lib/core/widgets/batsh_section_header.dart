import 'package:flutter/material.dart';

import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// How loudly a section announces itself.
///
/// A screen where every header is identical is a screen with no hierarchy —
/// the eye is told nine times that something is equally important and gives up
/// ranking them. [major] is for the one or two sections a screen is actually
/// about; it earns its weight from type size rather than from another
/// decoration.
enum BatshSectionEmphasis {
  /// Accent rule + `titleMd`. The default, and what every existing call site
  /// renders.
  standard,

  /// `headlineSm`, no rule. Bigger type is the emphasis, so keeping the accent
  /// bar as well would be saying it twice.
  major,
}

class BatshSectionHeader extends StatelessWidget {
  const BatshSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
    this.emphasis = BatshSectionEmphasis.standard,
    this.color,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets? padding;
  final BatshSectionEmphasis emphasis;

  /// Overrides the title colour, for a header sitting on a surface that is not
  /// the page's own. Null keeps `onSurface`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isMajor = emphasis == BatshSectionEmphasis.major;
    return Padding(
      padding:
          padding ??
          EdgeInsets.only(bottom: BatshSpacing.md, top: BatshSpacing.gutter),
      child: Row(
        children: [
          if (!isMajor) ...[
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: context.colorScheme.primary,
                borderRadius: BatshRadius.brFull,
              ),
            ),
            const SizedBox(width: BatshSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (isMajor
                          ? BatshTypography.headlineSm
                          : BatshTypography.titleMd)
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        color: color ?? context.colorScheme.onSurface,
                      ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
