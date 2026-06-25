import 'package:flutter/animation.dart';

class BatshMotion {
  const BatshMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve smooth = Curves.easeOutCubic;
  static const Curve spring = Curves.elasticOut;
}
