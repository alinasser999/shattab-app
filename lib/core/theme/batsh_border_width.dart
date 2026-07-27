/// Border stroke scale.
///
/// Three widths, and each one means something. The app had 1, 1.5, 2 and 3
/// scattered across ~87 sites with no rule about which applied where — at 3x
/// density the difference between a 1px and a 1.5px hairline is visible, so
/// the same conceptual border rendered differently on adjacent screens.
///
/// The 1 vs 1.5 pair is kept deliberately: `BatshChip` already uses 1 when
/// unselected and 1.5 when selected, which is a real state distinction rather
/// than drift. It is named here so the next component makes the same choice.
class BatshBorderWidth {
  const BatshBorderWidth._();

  /// 1 — the resting border on cards, inputs, dividers, unselected controls.
  static const double hairline = 1;

  /// 1.5 — a control the user has chosen. Reads as heavier than [hairline]
  /// without the jump to a full 2px frame.
  static const double selected = 1.5;

  /// 2 — a border carrying real weight: focus rings, destructive confirms,
  /// anything that must survive being glanced at rather than looked at.
  static const double strong = 2;

  /// Keyboard focus indicator. Same stroke as [strong]; named separately
  /// because accessibility guidance pins it independently of visual taste.
  static const double focusRing = strong;
}
