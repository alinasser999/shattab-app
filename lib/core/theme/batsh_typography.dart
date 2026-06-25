import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'batsh_colors.dart';

/// Two stacks, Arabic-first with Latin fallback so Arabic glyphs render
/// in an Arabic-native face and Latin text falls back cleanly.
class BatshTypography {
  const BatshTypography._();

  static TextStyle _headline({
    required double size,
    required FontWeight weight,
    required double lineHeight,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.notoNaskhArabic(
      fontSize: size,
      fontWeight: weight,
      height: lineHeight / size,
      letterSpacing: letterSpacing,
      color: color ?? BatshColors.onSurface,
      textBaseline: TextBaseline.alphabetic,
    ).copyWith(
      fontFamilyFallback: [
        GoogleFonts.notoSerif().fontFamily ?? 'Noto Serif',
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
    return GoogleFonts.ibmPlexSansArabic(
      fontSize: size,
      fontWeight: weight,
      height: lineHeight / size,
      letterSpacing: letterSpacing,
      color: color ?? BatshColors.onSurface,
      textBaseline: TextBaseline.alphabetic,
    ).copyWith(
      fontFamilyFallback: [
        GoogleFonts.plusJakartaSans().fontFamily ?? 'Plus Jakarta Sans',
      ],
    );
  }

  // Headlines
  static TextStyle get displayLg =>
      _headline(size: 40, weight: FontWeight.w700, lineHeight: 52);
  static TextStyle get headlineLg =>
      _headline(size: 32, weight: FontWeight.w600, lineHeight: 40);
  static TextStyle get headlineLgMobile =>
      _headline(size: 28, weight: FontWeight.w600, lineHeight: 36);
  static TextStyle get headlineMd =>
      _headline(size: 24, weight: FontWeight.w600, lineHeight: 32);

  // Body / labels
  static TextStyle get titleLg =>
      _body(size: 20, weight: FontWeight.w600, lineHeight: 28);
  static TextStyle get bodyLg =>
      _body(size: 18, weight: FontWeight.w400, lineHeight: 28);
  static TextStyle get bodyMd =>
      _body(size: 16, weight: FontWeight.w400, lineHeight: 24);
  static TextStyle get labelMd =>
      _body(size: 14, weight: FontWeight.w500, lineHeight: 20);
  static TextStyle get labelSm =>
      _body(size: 12, weight: FontWeight.w500, lineHeight: 16);

  /// Maps onto Material 3 [TextTheme] slots.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLg,
        displayMedium: headlineLg,
        displaySmall: headlineLgMobile,
        headlineLarge: headlineLg,
        headlineMedium: headlineMd,
        headlineSmall: headlineMd.copyWith(fontSize: 22, height: 30 / 22),
        titleLarge: titleLg,
        titleMedium: bodyLg.copyWith(fontWeight: FontWeight.w600),
        titleSmall: bodyMd.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: bodyLg,
        bodyMedium: bodyMd,
        bodySmall: labelMd.copyWith(color: BatshColors.onSurfaceVariant),
        labelLarge: labelMd,
        labelMedium: labelMd,
        labelSmall: labelSm,
      );
}
