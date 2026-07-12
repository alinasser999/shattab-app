import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'batsh_colors.dart';

/// Two stacks, Arabic-first with Latin fallback so Arabic glyphs render
/// in an Arabic-native face and Latin text falls back cleanly.
class BatshTypography {
  const BatshTypography._();

  // Font families
  static const String _arabicDisplay = 'Cairo';
  static const String _arabicBody = 'Tajawal';
  static const String _latinDisplay = 'Cairo';
  static const String _latinBody = 'Tajawal';

  static TextStyle _display({
    required double size,
    required FontWeight weight,
    required double lineHeight,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.getFont(
      _arabicDisplay,
      fontSize: size,
      fontWeight: weight,
      height: lineHeight / size,
      letterSpacing: letterSpacing,
      color: color ?? BatshColors.onSurface,
      textBaseline: TextBaseline.alphabetic,
    ).copyWith(
      fontFamilyFallback: [
        GoogleFonts.getFont(_latinDisplay).fontFamily ?? _latinDisplay,
      ],
    );
  }

  static TextStyle _body({
    required double size,
    required FontWeight weight,
    required double lineHeight,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.getFont(
      _arabicBody,
      fontSize: size,
      fontWeight: weight,
      height: lineHeight / size,
      letterSpacing: letterSpacing,
      color: color ?? BatshColors.onSurface,
      textBaseline: TextBaseline.alphabetic,
    ).copyWith(
      fontFamilyFallback: [
        GoogleFonts.getFont(_latinBody).fontFamily ?? _latinBody,
      ],
    );
  }

  // Display / Headlines
  static TextStyle get displayLg => _display(
        size: 40,
        weight: FontWeight.w700,
        lineHeight: 52,
        letterSpacing: -0.4,
      );
  static TextStyle get displayMd => _display(
        size: 34,
        weight: FontWeight.w600,
        lineHeight: 44,
        letterSpacing: -0.3,
      );
  static TextStyle get headlineLg => _display(
        size: 28,
        weight: FontWeight.w600,
        lineHeight: 38,
        letterSpacing: -0.2,
      );
  static TextStyle get headlineLgMobile => headlineLg.copyWith(
        fontSize: 26,
        height: 34 / 26,
      );
  static TextStyle get headlineMd => _display(
        size: 24,
        weight: FontWeight.w600,
        lineHeight: 32,
        letterSpacing: -0.1,
      );
  static TextStyle get headlineSm => _display(
        size: 20,
        weight: FontWeight.w600,
        lineHeight: 28,
        letterSpacing: 0,
      );

  // Title / Body / Label
  static TextStyle get titleLg => _body(
        size: 20,
        weight: FontWeight.w600,
        lineHeight: 28,
      );
  static TextStyle get titleMd => _body(
        size: 18,
        weight: FontWeight.w600,
        lineHeight: 26,
      );
  static TextStyle get bodyLg => _body(
        size: 17,
        weight: FontWeight.w400,
        lineHeight: 26,
      );
  static TextStyle get bodyMd => _body(
        size: 15,
        weight: FontWeight.w400,
        lineHeight: 24,
      );
  static TextStyle get bodySm => _body(
        size: 13,
        weight: FontWeight.w400,
        lineHeight: 20,
      );
  static TextStyle get labelLg => _body(
        size: 15,
        weight: FontWeight.w600,
        lineHeight: 22,
      );
  static TextStyle get labelMd => _body(
        size: 13,
        weight: FontWeight.w500,
        lineHeight: 18,
      );
  static TextStyle get labelSm => _body(
        size: 11,
        weight: FontWeight.w500,
        lineHeight: 16,
      );

  /// Maps onto Material 3 [TextTheme] slots.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLg,
        displayMedium: displayMd,
        displaySmall: headlineLg,
        headlineLarge: headlineLg,
        headlineMedium: headlineMd,
        headlineSmall: headlineSm,
        titleLarge: titleLg,
        titleMedium: titleMd,
        titleSmall: titleMd.copyWith(fontSize: 16, height: 22 / 16),
        bodyLarge: bodyLg,
        bodyMedium: bodyMd,
        bodySmall: bodySm,
        labelLarge: labelLg,
        labelMedium: labelMd,
        labelSmall: labelSm,
      );
}
