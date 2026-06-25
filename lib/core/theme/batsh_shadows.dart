import 'package:flutter/material.dart';
import 'batsh_colors.dart';

/// Terracotta-tinted shadows — never pure black.
/// Tint is [BatshColors.primary] with varying alpha per level.
class BatshShadows {
  const BatshShadows._();

  static List<BoxShadow> get none => const [];

  static List<BoxShadow> get soft => const [
        BoxShadow(
          color: Color(0x0F9E3D18),
          offset: Offset(0, 2),
          blurRadius: 8,
        ),
      ];

  static List<BoxShadow> get raised => const [
        BoxShadow(
          color: Color(0x1A9E3D18),
          offset: Offset(0, 4),
          blurRadius: 16,
        ),
      ];

  static List<BoxShadow> get floating => const [
        BoxShadow(
          color: Color(0x249E3D18),
          offset: Offset(0, 8),
          blurRadius: 24,
        ),
      ];
}
