import 'package:flutter/material.dart';

/// Homepage appearance only: discovery and contractor surfaces keep their theme.
abstract final class HomeownerReferenceStyle {
  static const navy = Color(0xff152552);
  static const orange = Color(0xffef4b24);
  static const action = Color(0xffb93417);
  static const gutter = 16.0;
  static const sectionGap = 20.0;
  static const shelfGap = 10.0;
  static const touchTarget = 48.0;
  static const muted = Color(0xff56617c);
  static const cream = Color(0xfffff8ef);
  static const background = Color(0xfffffefd);

  static TextStyle text(
    double size, {
    Color color = navy,
    FontWeight weight = FontWeight.w500,
    double height = 1.3,
  }) => TextStyle(
    fontFamily: 'Tajawal',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static ThemeData scopedTheme(ThemeData base) => base.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: base.colorScheme.copyWith(
      primary: orange,
      onPrimary: Colors.white,
      secondary: navy,
      onSecondary: Colors.white,
      surface: background,
      onSurface: navy,
      onSurfaceVariant: muted,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'Tajawal',
      bodyColor: navy,
      displayColor: navy,
    ),
  );
}
