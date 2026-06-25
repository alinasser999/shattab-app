import 'package:flutter/material.dart';

/// Source of truth: docs/design-tokens.md (extracted from Stitch "Shattab")
/// Egyptian Modern Heritage palette — terracotta + olive + gold on warm cream.
class BatshColors {
  const BatshColors._();

  // Surfaces
  static const Color surface = Color(0xFFFFF8F3);
  static const Color surfaceBright = Color(0xFFFFF8F3);
  static const Color surfaceDim = Color(0xFFE2D9CE);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFCF2E7);
  static const Color surfaceContainer = Color(0xFFF6ECE1);
  static const Color surfaceContainerHigh = Color(0xFFF1E7DC);
  static const Color surfaceContainerHighest = Color(0xFFEBE1D6);
  static const Color surfaceVariant = Color(0xFFEBE1D6);
  static const Color inverseSurface = Color(0xFF353028);
  static const Color background = Color(0xFFFFF8F3);

  // Primary — Terracotta
  static const Color primary = Color(0xFF9E3D18);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFBF542E);
  static const Color onPrimaryContainer = Color(0xFFFFFBFF);
  static const Color inversePrimary = Color(0xFFFFB59D);
  static const Color primaryFixed = Color(0xFFFFDBD0);
  static const Color primaryFixedDim = Color(0xFFFFB59D);
  static const Color onPrimaryFixed = Color(0xFF390C00);
  static const Color onPrimaryFixedVariant = Color(0xFF822803);
  static const Color surfaceTint = Color(0xFFA23F1A);

  // Secondary — Olive
  static const Color secondary = Color(0xFF5C614D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE0E5CC);
  static const Color onSecondaryContainer = Color(0xFF626753);

  // Tertiary — Gold
  static const Color tertiary = Color(0xFF735C00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFCCA830);
  static const Color onTertiaryContainer = Color(0xFF4F3E00);
  static const Color tertiaryFixed = Color(0xFFFFE088);

  // Text
  static const Color onSurface = Color(0xFF1F1B14);
  static const Color onSurfaceVariant = Color(0xFF57423B);
  static const Color inverseOnSurface = Color(0xFFF9EFE4);

  // Borders / outlines
  static const Color outline = Color(0xFF8A726A);
  static const Color outlineVariant = Color(0xFFDEC0B7);

  // Semantic
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Derived semantics (not in Stitch — tied to secondary/tertiary)
  static const Color success = secondary;
  static const Color onSuccess = onSecondary;
  static const Color successContainer = secondaryContainer;
  static const Color warning = tertiary;
  static const Color onWarning = onTertiary;
  static const Color warningContainer = tertiaryContainer;

  /// Builds the Material 3 ColorScheme used by [BatshTheme].
  static ColorScheme get scheme => const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        surfaceDim: surfaceDim,
        surfaceBright: surfaceBright,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: inverseSurface,
        onInverseSurface: inverseOnSurface,
        inversePrimary: inversePrimary,
        surfaceTint: surfaceTint,
      );
}
