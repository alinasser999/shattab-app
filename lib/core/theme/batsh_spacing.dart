/// Spacing scale on an 8px baseline grid.
/// Use these instead of literal pixel values everywhere.
class BatshSpacing {
  const BatshSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double gutter = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xxl = 64;

  /// Side margin inside mobile screens (per Stitch spec).
  static const double marginMobile = 20;

  /// Minimum touch target per Stitch spec.
  static const double minHitArea = 48;
}
