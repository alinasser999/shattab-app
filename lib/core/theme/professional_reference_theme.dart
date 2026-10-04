import 'package:flutter/material.dart';

/// Explicit reference scope; never applied to the global or contractor theme.
abstract final class ProfessionalReferenceTheme {
  static const navy = Color(0xff172f78);
  static const orange = Color(0xffe54b22);
  static const action = Color(0xffb53616);
  static const muted = Color(0xff59647b);
  static const legacyMuted = Color(0xff8990a3);
  static const cream = Color(0xfffffbf4);
  static const background = Color(0xfffdfcf9);
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
      primaryContainer: const Color(0xffffeee7),
      onPrimaryContainer: navy,
      secondaryContainer: cream,
      onSecondaryContainer: navy,
      surfaceContainer: Colors.white,
      surfaceContainerHighest: cream,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: cream,
      outlineVariant: const Color(0xffe7e5e0),
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'Tajawal',
      bodyColor: navy,
      displayColor: navy,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: Colors.white,
      labelStyle: text(16),
      hintStyle: text(16, color: muted),
    ),
  );
}
