import 'package:flutter/material.dart';

/// Premium shadow system — warm-tinted for depth without harshness.
/// Shadows tinted toward terracotta for brand cohesion.
class BatshShadows {
  const BatshShadows._();

  static List<BoxShadow> get none => const [];

  /// Tiny elevation — for subtle surface separation
  static List<BoxShadow> get subtle => const [
    BoxShadow(color: Color(0x089E3D18), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Card default — soft, warm, premium
  static List<BoxShadow> get soft => [
    const BoxShadow(
      color: Color(0x0C9E3D18),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
    const BoxShadow(
      color: Color(0x089E3D18),
      offset: Offset(0, 1),
      blurRadius: 1,
    ),
  ];

  /// Mid elevation — for elevated cards
  static List<BoxShadow> get elevated => [
    const BoxShadow(
      color: Color(0x109E3D18),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
    const BoxShadow(
      color: Color(0x089E3D18),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  /// Raised — for FABs, dropdowns, sheets
  static List<BoxShadow> get raised => [
    const BoxShadow(
      color: Color(0x149E3D18),
      offset: Offset(0, 6),
      blurRadius: 12,
    ),
    const BoxShadow(
      color: Color(0x0A9E3D18),
      offset: Offset(0, 3),
      blurRadius: 6,
    ),
  ];

  /// Floating — modals, bottom sheets
  static List<BoxShadow> get floating => [
    const BoxShadow(
      color: Color(0x1E9E3D18),
      offset: Offset(0, 8),
      blurRadius: 20,
    ),
    const BoxShadow(
      color: Color(0x0C9E3D18),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  /// Numeric elevation ladder over the named shadows above.
  ///
  /// The named getters say what a surface *is* (`raised`, `floating`), which is
  /// the better thing to reach for and stays the recommended API. This exists
  /// for the cases where elevation arrives as a number rather than an intent —
  /// a list index, an animation driving depth on press, a `Material` widget
  /// whose `elevation` is being mapped across. It delegates rather than
  /// defining a second set of shadows, so the two cannot drift apart.
  ///
  /// Levels above 5 clamp to [floating]; below 0 clamp to [none].
  static List<BoxShadow> level(int level) => switch (level.clamp(0, 5)) {
    0 => none,
    1 => subtle,
    2 => soft,
    3 => elevated,
    4 => raised,
    _ => floating,
  };

  /// Modal barrier shadow
  static List<BoxShadow> get modal => [
    const BoxShadow(
      color: Color(0x289E3D18),
      offset: Offset(0, 12),
      blurRadius: 28,
    ),
    const BoxShadow(
      color: Color(0x109E3D18),
      offset: Offset(0, 6),
      blurRadius: 12,
    ),
  ];
}
