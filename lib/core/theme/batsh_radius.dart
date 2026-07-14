import 'package:flutter/material.dart';

/// Premium corner radius system — soft, cohesive, moderate.
/// Cards: 16px (soft but not overly round)
/// Buttons: 12px (pill-lite)
/// Chips/badges: full
/// Inputs: 12px
class BatshRadius {
  const BatshRadius._();

  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 9999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));

  // Buttons / inputs / skeletons — 12px "pill-lite" per design tokens.
  static const double defaultR = md;
  static const BorderRadius brDefault = brMd;
}
