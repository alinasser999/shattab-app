/// Icon size scale.
///
/// The app previously carried 23 distinct icon sizes across 143 call sites,
/// including the run 12/13/14/15/16/17/18 — seven sizes inside a 6px band that
/// no one can tell apart in isolation, but which guarantee two icons sitting
/// side by side will not share a baseline.
///
/// Six rungs replace all of them. Sizes are chosen against the type ramp in
/// `BatshTypography`, since almost every icon in this app sits next to a label:
/// an icon reads as the same weight as its text at roughly 1.1–1.2x the text
/// size, so [sm] pairs with `labelMd` (13) and `bodySm` (13), [md] pairs with
/// `bodyMd` (15) and `labelLg` (15), and [lg] pairs with `titleMd` (18).
class BatshIconSize {
  const BatshIconSize._();

  /// 12 — dense metadata glyphs, inline with `labelSm`.
  static const double xs = 12;

  /// 16 — the default for an icon beside `labelMd` / `bodySm` text.
  static const double sm = 16;

  /// 20 — icons that carry an action: buttons, chips, tappable rows.
  static const double md = 20;

  /// 24 — Material's own default. Navigation and app-bar affordances.
  static const double lg = 24;

  /// 32 — a glyph read as an object rather than a control.
  static const double xl = 32;

  /// 48 — the largest an icon should ever be. Above this, use an illustration
  /// or a real asset; a scaled-up Material glyph starts showing its hinting.
  static const double xxl = 48;

  // ── Semantic aliases ──────────────────────────────────────────────────
  // Prefer these at call sites. They survive a change to the scale.

  /// Beside body or label text.
  static const double inline = sm;

  /// Inside a button, chip, or any tappable affordance.
  static const double action = md;

  /// Bottom nav, app bar, back buttons.
  static const double nav = lg;

  /// The glyph in an empty state or a status illustration.
  static const double empty = xxl;
}
