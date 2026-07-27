import 'package:flutter/material.dart';

import '../theme/batsh_border_width.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_icon_size.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

/// What a badge is saying about the thing it sits on.
enum BatshBadgeTone {
  /// Plain metadata. A category, a count, a type. No judgement.
  ///
  /// Also the right tone for a state that is simply over — cancelled,
  /// archived, withdrawn. Those are terminal but not wrong, and colouring a
  /// whole list of them red makes routine history look like a wall of errors.
  neutral,

  /// Something to do with Shattab itself: Pro, featured, verified.
  brand,

  /// A good state. Open, accepted, completed, active.
  success,

  /// A state worth noticing but not acting on. Pending, expiring, a rating.
  warning,

  /// A decision that went against the user. Declined, rejected, blocked.
  /// Not merely "finished" — see [neutral].
  danger,
}

/// How loudly the badge speaks.
enum BatshBadgeEmphasis {
  /// Tinted background, coloured text. The default: readable without pulling
  /// focus from the content it annotates.
  subtle,

  /// Filled background, inverted text. Reserve for the one badge on screen
  /// that has to be seen first. More than one solid badge in a view and
  /// neither of them is emphasised any more.
  solid,

  /// Border only, transparent background. For badges on a *known* surface that
  /// already carries colour — inside a tinted card, over a filled header —
  /// where a second fill would muddy it.
  ///
  /// Not for photography: transparent means the text takes whatever the photo
  /// puts behind it, and a dark photo swallows it. Use [onImage] there.
  outline,

  /// Dark scrim, white text. The only variant safe over an arbitrary photo.
  ///
  /// The scrim is heavy enough that white still clears 4.5:1 against a
  /// blown-out white sky, which is the case that defeats a hand-rolled
  /// `Colors.white24` pill: that one only works while a gradient happens to sit
  /// underneath it, and silently fails the moment the photo changes.
  onImage,
}

/// A small, non-interactive status label.
///
/// This replaces ten private classes — `_Badge`, `_Pill`, `_MiniChip`,
/// `_StatChip`, `_CountChip`, `_RatingBadge`, `_CancelledChip`, `_StatusBadge`,
/// `_VerifiedBadge`, `_ProviderKindBadge` — each of which drew the same rounded
/// label with its own padding, its own radius, and its own idea of what "open"
/// should look like.
///
/// Three lookalikes were deliberately left alone, because sharing a silhouette
/// is not the same as sharing a job:
///
/// - `_CategoryChip` (discover) and `_RatingPill` (showcase) both take an
///   `onTap`. They are controls, and folding them in here would make them
///   announce as inert to a screen reader.
/// - `_ProActivePill` is a full-width banner with a title-sized line and its
///   own icon column. Only its name suggests a badge.
///
/// This is not [BatshChip]. A chip is a control: the user taps it, it has a
/// selected state, it changes what is on screen. A badge is a fact about
/// something else on screen and does nothing when touched. Keeping the two
/// apart is what stops a status label from looking tappable.
///
/// ```dart
/// BatshBadge(label: S.statusOpen, tone: BatshBadgeTone.success)
/// BatshBadge(label: '4.8', icon: Icons.star_rounded, tone: BatshBadgeTone.warning)
/// BatshBadge(label: S.pro, tone: BatshBadgeTone.brand, emphasis: BatshBadgeEmphasis.solid)
/// ```
class BatshBadge extends StatelessWidget {
  const BatshBadge({
    super.key,
    required this.label,
    this.tone = BatshBadgeTone.neutral,
    this.emphasis = BatshBadgeEmphasis.subtle,
    this.icon,
    this.compact = false,
    this.semanticLabel,
  });

  final String label;
  final BatshBadgeTone tone;
  final BatshBadgeEmphasis emphasis;

  /// Leading glyph. Skip it unless it carries meaning the label does not — a
  /// star before a rating earns its place, a tag before a category does not.
  final IconData? icon;

  /// Denser padding and a smaller type step, for badges inside list rows and
  /// on top of imagery where vertical space is contested.
  final bool compact;

  /// Overrides what a screen reader announces. Set this when [label] is a bare
  /// number that means nothing read aloud on its own.
  final String? semanticLabel;

  /// (foreground, background, border) for this tone and emphasis.
  ///
  /// Every subtle pairing uses a container colour with its matching `on`
  /// colour rather than a transparency of the base. Transparency over a
  /// surface whose colour is not known at build time is how contrast quietly
  /// fails.
  @visibleForTesting
  (Color, Color, Color) get debugPalette => switch ((tone, emphasis)) {
    // Deliberately ignores tone. Over a photo the only job is legibility,
    // and a tinted scrim would tint the photograph rather than the badge.
    (_, BatshBadgeEmphasis.onImage) => (
      Colors.white,
      Colors.black.withValues(alpha: 0.6),
      Colors.transparent,
    ),
    (BatshBadgeTone.neutral, BatshBadgeEmphasis.solid) => (
      BatshColors.inverseOnSurface,
      BatshColors.inverseSurface,
      BatshColors.inverseSurface,
    ),
    (BatshBadgeTone.neutral, _) => (
      BatshColors.onSurfaceVariant,
      BatshColors.surfaceContainerHigh,
      BatshColors.outlineVariant,
    ),
    (BatshBadgeTone.brand, BatshBadgeEmphasis.solid) => (
      BatshColors.onPrimary,
      BatshColors.primary,
      BatshColors.primary,
    ),
    (BatshBadgeTone.brand, _) => (
      BatshColors.onPrimaryContainer,
      BatshColors.primaryContainer,
      BatshColors.primary,
    ),
    (BatshBadgeTone.success, BatshBadgeEmphasis.solid) => (
      BatshColors.onSuccess,
      BatshColors.success,
      BatshColors.success,
    ),
    (BatshBadgeTone.success, _) => (
      BatshColors.onSecondaryContainer,
      BatshColors.successContainer,
      BatshColors.success,
    ),
    (BatshBadgeTone.warning, BatshBadgeEmphasis.solid) => (
      BatshColors.onWarning,
      BatshColors.warning,
      BatshColors.warning,
    ),
    (BatshBadgeTone.warning, _) => (
      BatshColors.onTertiaryContainer,
      BatshColors.warningContainer,
      BatshColors.warning,
    ),
    (BatshBadgeTone.danger, BatshBadgeEmphasis.solid) => (
      BatshColors.onError,
      BatshColors.error,
      BatshColors.error,
    ),
    (BatshBadgeTone.danger, _) => (
      BatshColors.onErrorContainer,
      BatshColors.errorContainer,
      BatshColors.error,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (foreground, background, borderColor) = debugPalette;
    final outlined = emphasis == BatshBadgeEmphasis.outline;

    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? BatshSpacing.xs : BatshSpacing.sm,
          vertical: compact ? BatshSpacing.xxxs : BatshSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : background,
          borderRadius: BatshRadius.brFull,
          border: Border.all(
            color: outlined ? borderColor : borderColor.withValues(alpha: 0.25),
            width: BatshBorderWidth.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: compact ? BatshIconSize.xs : BatshIconSize.inline,
                color: foreground,
              ),
              SizedBox(width: compact ? BatshSpacing.xxxs : BatshSpacing.xxs),
            ],
            Text(
              label,
              style:
                  (compact ? BatshTypography.labelSm : BatshTypography.labelMd)
                      .copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
