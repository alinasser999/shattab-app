import 'package:flutter/material.dart';

class BatshRadius {
  const BatshRadius._();

  static const double none = 0;
  static const double sm = 4;
  static const double defaultR = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brDefault =
      BorderRadius.all(Radius.circular(defaultR));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));
}
