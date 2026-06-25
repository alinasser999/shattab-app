import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'batsh_colors.dart';
import 'batsh_radius.dart';
import 'batsh_spacing.dart';
import 'batsh_typography.dart';

/// Composes color, type, and component themes into the [ThemeData] used by
/// MaterialApp. Component-level styling matches the Stitch spec — soft 16px
/// radius for cards, 8px for inputs/buttons, generous 48dp hit areas.
class BatshTheme {
  const BatshTheme._();

  static ThemeData light() {
    final colors = BatshColors.scheme;
    final textTheme = BatshTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: BatshColors.background,
      canvasColor: BatshColors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      typography: Typography.material2021(
        platform: TargetPlatform.android,
        colorScheme: colors,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: BatshColors.background,
        foregroundColor: BatshColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: BatshTypography.titleLg,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BatshColors.primary,
          foregroundColor: BatshColors.onPrimary,
          disabledBackgroundColor: BatshColors.surfaceContainerHigh,
          disabledForegroundColor: BatshColors.onSurfaceVariant,
          minimumSize: const Size.fromHeight(BatshSpacing.minHitArea),
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.lg,
            vertical: BatshSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BatshRadius.brDefault,
          ),
          textStyle: BatshTypography.labelMd.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BatshColors.primary,
          side: const BorderSide(color: BatshColors.outline),
          minimumSize: const Size.fromHeight(BatshSpacing.minHitArea),
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.lg,
            vertical: BatshSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BatshRadius.brDefault,
          ),
          textStyle:
              BatshTypography.labelMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BatshColors.primary,
          minimumSize: const Size(0, BatshSpacing.minHitArea),
          textStyle:
              BatshTypography.labelMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BatshColors.surfaceContainerLow,
        hintStyle: BatshTypography.bodyMd
            .copyWith(color: BatshColors.onSurfaceVariant),
        labelStyle: BatshTypography.bodyMd
            .copyWith(color: BatshColors.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.gutter,
          vertical: BatshSpacing.gutter,
        ),
        border: const OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide(color: BatshColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide(color: BatshColors.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: BatshColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BatshRadius.brLg,
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BatshColors.surfaceContainerLow,
        selectedItemColor: BatshColors.primary,
        unselectedItemColor: BatshColors.onSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BatshColors.surfaceContainerLow,
        indicatorColor: BatshColors.primaryFixed,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => BatshTypography.labelSm.copyWith(
            color: states.contains(WidgetState.selected)
                ? BatshColors.primary
                : BatshColors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BatshColors.surfaceContainer,
        selectedColor: BatshColors.primaryFixed,
        disabledColor: BatshColors.surfaceContainerHigh,
        labelStyle: BatshTypography.labelMd,
        secondaryLabelStyle: BatshTypography.labelMd
            .copyWith(color: BatshColors.primary, fontWeight: FontWeight.w600),
        side: const BorderSide(color: BatshColors.outlineVariant),
        shape: const RoundedRectangleBorder(
          borderRadius: BatshRadius.brFull,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.md,
          vertical: BatshSpacing.sm,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BatshColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BatshColors.inverseSurface,
        contentTextStyle:
            BatshTypography.bodyMd.copyWith(color: BatshColors.inverseOnSurface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BatshRadius.brMd,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BatshColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BatshColors.onPrimary
              : BatshColors.surfaceContainerLowest,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BatshColors.primary
              : BatshColors.surfaceContainerHighest,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BatshColors.primary
              : Colors.transparent,
        ),
        side: const BorderSide(color: BatshColors.outline, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BatshRadius.brSm,
        ),
      ),
    );
  }
}
