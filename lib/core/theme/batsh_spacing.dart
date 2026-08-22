/// 8dp spacing system — clean, consistent, premium.
/// Every value follows an 8/4 increment rhythm.
class BatshSpacing {
  const BatshSpacing._();

  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double ml = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
  static const double xxxxl = 64;
  static const double huge = 80;

  // ─── Semantic levels ───────────────────────────────────────────────────────
  //
  // Space is a grouping signal: things near each other are read as belonging
  // together, before anyone decides to read anything. So each gap has to
  // encode which kind of boundary it is, and two gaps have to differ by about
  // 1.5x before the eye registers them as different kinds at all.
  //
  //   intra    8   inside one idea      (a label and its value)
  //   inter   16   between siblings     (screen edge, list items)
  //   group   24   between groups       (card interior, section sides)
  //   section 40+  between sections
  //
  // 16 -> 24 is 1.5x, 24 -> 40 is 1.67x. Both clear.

  /// Card interiors and section sides.
  ///
  /// Was 20, which put it 1.25x from [marginMobile] at 16 — close enough that
  /// the padding inside a card and the padding at the edge of the screen read
  /// as the same distance, so nothing told the eye where one thing ended and
  /// the next began. It moved up rather than down: the premium surface is the
  /// one with more room, not less.
  static const double gutter = lg;

  /// Horizontal section insets. The same rung as [gutter] on purpose — a
  /// section's sides and a card's interior are the same kind of boundary, and
  /// giving them different values would be inventing a distinction.
  static const double sectionH = lg;

  /// Screen edges, and the gap between items in a list.
  static const double marginMobile = md;

  /// Default page gutter for content screens. Full-bleed compositions opt out
  /// explicitly; ordinary forms and lists get enough breathing room without
  /// making the mobile content column feel narrow.
  static const double pageGutter = 20;

  /// Separation between major content groups when a screen needs a wider beat
  /// than the compact card/list rhythm.
  static const double sectionGap = 28;

  // `cardPadding` and `sectionV` used to sit here with zero references between
  // them. An alias nothing calls is not a design decision, it is a suggestion
  // the codebase declined.

  // Touch
  static const double minHitArea = 48;
}
