import 'package:flutter/material.dart';

/// Source of truth: docs/design-tokens.md (extracted from Stitch "Shattab")
/// Egyptian Modern Heritage palette — terracotta + olive + gold on warm cream.
class BatshColors {
  const BatshColors._();

  // Surfaces — deepened contrast for clear hierarchy
  static const Color surface = Color(0xFFFFF8F3);
  static const Color surfaceBright = Color(0xFFFFF8F3);
  static const Color surfaceDim = Color(0xFFE4DCCC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5EDE3);
  static const Color surfaceContainer = Color(0xFFEDE5DB);
  static const Color surfaceContainerHigh = Color(0xFFE5DDD3);
  static const Color surfaceContainerHighest = Color(0xFFDDD5CB);
  static const Color surfaceVariant = Color(0xFFDDD5CB);
  static const Color inverseSurface = Color(0xFF2D2820);
  static const Color background = Color(0xFFFFF8F3);

  // Primary — Terracotta (brand anchor)
  static const Color primary = Color(0xFF9E3D18);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color inversePrimary = Color(0xFFFFB59D);
  static const Color primaryContainer = Color(0xFFFFDBD0);
  static const Color onPrimaryContainer = Color(0xFF390C00);
  static const Color primaryFixed = Color(0xFFFFDBD0);
  static const Color primaryFixedDim = Color(0xFFFFB59D);
  static const Color onPrimaryFixed = Color(0xFF390C00);
  static const Color onPrimaryFixedVariant = Color(0xFF822803);
  static const Color surfaceTint = Color(0xFFA23F1A);

  // Brand aliases keep the identity vocabulary explicit while the Material
  // roles above remain the source used by ThemeData and dark mode.
  static const Color brandTerracotta = primary;
  static const Color brandCream = background;
  static const Color brandCharcoal = onSurface;
  static const Color brandOlive = secondary;
  static const Color brandSand = surfaceDim;
  static const Color brandGold = tertiary;

  // Secondary — Olive (trust, nature)
  static const Color secondary = Color(0xFF5C614D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE0E5CC);
  static const Color onSecondaryContainer = Color(0xFF1E2314);

  // Tertiary — Gold (warmth, craft)
  static const Color tertiary = Color(0xFF735C00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFE088);
  static const Color onTertiaryContainer = Color(0xFF231A00);
  static const Color tertiaryFixed = Color(0xFFFFE088);

  /// Rating stars. [tertiary] is the gold that stays legible *as text*; a star
  /// is a filled shape, so it reads a full step darker than a glyph of the same
  /// colour and needs its own, brighter value. Fixed across themes — a star
  /// sits on a card, not on the page.
  static const Color starGold = Color(0xFFE6AC43);

  /// Contour lines of the Shattab pattern: the terracotta drawn down to where
  /// it reads as a watermark on cream and as sand on the dark surface, so one
  /// value serves both themes.
  static const Color patternLine = Color(0xFFDDA47F);

  // Text
  static const Color onSurface = Color(0xFF1F1B14);
  static const Color onSurfaceVariant = Color(0xFF4A3630);
  static const Color inverseOnSurface = Color(0xFFF9EFE4);

  // Borders / outlines
  static const Color outline = Color(0xFF8A726A);
  static const Color outlineVariant = Color(0xFFDEC0B7);

  // Semantic
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Cards — elevated surfaces for depth
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardElevated = Color(0xFFFFFFFF);

  // Dividers
  static const Color divider = Color(0x1A4A3630);
  static const Color dividerStrong = Color(0x334A3630);

  // Derived semantics
  static const Color success = secondary;
  static const Color onSuccess = onSecondary;
  static const Color successContainer = secondaryContainer;
  static const Color warning = tertiary;
  static const Color onWarning = onTertiary;
  static const Color warningContainer = tertiaryContainer;

  // Brand-specific
  static const Color whatsApp = Color(0xFF25D366);
  static const Color whatsAppOn = Colors.white;

  // Overlay/scrim
  static const Color scrim = Color(0x991F1B14);
  static const Color modalBarrier = Color(0xBF1F1B14);

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

  // Dark scheme (for future dark mode support)
  static ColorScheme get darkScheme => const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB59D),
    onPrimary: Color(0xFF390C00),
    primaryContainer: Color(0xFF822803),
    onPrimaryContainer: Color(0xFFFFDBD0),
    secondary: Color(0xFFC4CBA8),
    onSecondary: Color(0xFF1E2314),
    secondaryContainer: Color(0xFF444936),
    onSecondaryContainer: Color(0xFFE0E5CC),
    tertiary: Color(0xFFFFD566),
    onTertiary: Color(0xFF231A00),
    tertiaryContainer: Color(0xFF594800),
    onTertiaryContainer: Color(0xFFFFE088),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1F1B14),
    onSurface: Color(0xFFF9EFE4),
    surfaceContainerLowest: Color(0xFF181510),
    surfaceContainerLow: Color(0xFF352F27),
    surfaceContainer: Color(0xFF3F3930),
    surfaceContainerHigh: Color(0xFF494339),
    surfaceContainerHighest: Color(0xFF534D43),
    surfaceDim: Color(0xFF1F1B14),
    surfaceBright: Color(0xFF534D43),
    onSurfaceVariant: Color(0xFFD6C0B4),
    outline: Color(0xFF9E857C),
    outlineVariant: Color(0xFF53463D),
    inverseSurface: Color(0xFFF9EFE4),
    onInverseSurface: Color(0xFF1F1B14),
    inversePrimary: Color(0xFF9E3D18),
    surfaceTint: Color(0xFFFFB59D),
  );
}
