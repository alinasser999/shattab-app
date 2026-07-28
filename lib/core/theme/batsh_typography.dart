import 'package:flutter/material.dart';

/// One family, sized and weighted into a scale.
///
/// This used to be two: Cairo for display, Tajawal for body. Both are
/// geometric sans, so the pairing bought no tonal contrast — only a second
/// font to fetch over an Egyptian mobile connection. Every difference the old
/// stack actually achieved came from size and weight, which one family does
/// for free.
///
/// IBM Plex Sans Arabic is humanist rather than geometric, which is where the
/// warmth comes from, and it carries Latin in the same family so there is no
/// fallback seam mid-sentence. To try a different face, change [_family] and
/// the `fonts:` block in pubspec — nothing else in the app names a font.
///
/// The four weights are bundled assets, not a `google_fonts` runtime fetch.
/// That package downloads from fonts.gstatic.com on first use, so the typeface
/// only arrived if the network cooperated; here it is in the binary.
class BatshTypography {
  const BatshTypography._();

  static const String _family = 'IBM Plex Sans Arabic';

  /// Display weights are w700, body weights stay at w600 and below. The bands
  /// never overlap; that separation is what makes one family read as two
  /// voices instead of one blurry one.
  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required double lineHeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: _family,
      fontSize: size,
      fontWeight: weight,
      height: lineHeight / size,
      // No negative tracking. Arabic is a connected script: tightening the
      // advance pulls the joins into the letterforms. Tight display tracking
      // is a Latin convention and does not transfer.
      letterSpacing: 0,
      // Deliberately null. Baking a colour here froze every style at the
      // light-theme ink, which is byte-identical to the dark theme's surface —
      // dark mode rendered invisible text. BatshTheme applies the scheme's ink
      // to the whole TextTheme instead, so both themes resolve correctly.
      color: color,
      textBaseline: TextBaseline.alphabetic,
    );
  }

  // ─── Display ───────────────────────────────────────────────────────────────
  // Leading floor of 1.40. Arabic stacks vowel marks above the letterform and
  // descends below the baseline further than Latin, so display-size text set
  // to a Latin leading ratio collides with itself.

  static TextStyle get displayLg =>
      _style(size: 40, weight: FontWeight.w700, lineHeight: 56);
  static TextStyle get displayMd =>
      _style(size: 34, weight: FontWeight.w700, lineHeight: 48);
  static TextStyle get headlineLg =>
      _style(size: 28, weight: FontWeight.w700, lineHeight: 40);
  static TextStyle get headlineLgMobile =>
      headlineLg.copyWith(fontSize: 26, height: 38 / 26);
  static TextStyle get headlineMd =>
      _style(size: 24, weight: FontWeight.w700, lineHeight: 34);
  static TextStyle get headlineSm =>
      _style(size: 20, weight: FontWeight.w700, lineHeight: 29);

  // ─── Title / Body / Label ──────────────────────────────────────────────────

  static TextStyle get titleLg =>
      _style(size: 20, weight: FontWeight.w600, lineHeight: 28);
  static TextStyle get titleMd =>
      _style(size: 18, weight: FontWeight.w600, lineHeight: 26);
  static TextStyle get bodyLg =>
      _style(size: 17, weight: FontWeight.w400, lineHeight: 26);
  static TextStyle get bodyMd =>
      _style(size: 15, weight: FontWeight.w400, lineHeight: 24);
  static TextStyle get bodySm =>
      _style(size: 13, weight: FontWeight.w400, lineHeight: 20);
  static TextStyle get labelLg =>
      _style(size: 15, weight: FontWeight.w600, lineHeight: 22);
  static TextStyle get labelMd =>
      _style(size: 13, weight: FontWeight.w500, lineHeight: 18);
  static TextStyle get labelSm =>
      _style(size: 11, weight: FontWeight.w500, lineHeight: 16);

  /// Maps onto Material 3 [TextTheme] slots.
  ///
  /// Every entry here has a null colour. [BatshTheme] calls `.apply()` on this
  /// with the active scheme's ink before handing it to `ThemeData`.
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLg,
    displayMedium: displayMd,
    displaySmall: headlineLg,
    headlineLarge: headlineLg,
    headlineMedium: headlineMd,
    headlineSmall: headlineSm,
    titleLarge: titleLg,
    titleMedium: titleMd,
    titleSmall: titleMd.copyWith(fontSize: 16, height: 22 / 16),
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm,
    labelLarge: labelLg,
    labelMedium: labelMd,
    labelSmall: labelSm,
  );
}
