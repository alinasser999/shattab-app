import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'batsh_colors.dart';
import 'batsh_radius.dart';
import 'batsh_spacing.dart';
import 'batsh_typography.dart';

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
      brightness: Brightness.light,
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
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: BatshTypography.titleLg.copyWith(
          fontWeight: FontWeight.w600,
        ),
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
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.lg,
            vertical: BatshSpacing.gutter,
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
          side: const BorderSide(color: BatshColors.outline, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.lg,
            vertical: BatshSpacing.gutter,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BatshRadius.brDefault,
          ),
          textStyle: BatshTypography.labelMd.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BatshColors.primary,
          minimumSize: const Size(0, 48),
          textStyle: BatshTypography.labelMd.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BatshColors.surfaceContainerLow,
        hintStyle: BatshTypography.bodyMd.copyWith(
          color: BatshColors.onSurfaceVariant,
        ),
        labelStyle: BatshTypography.bodyMd.copyWith(
          color: BatshColors.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.gutter,
          vertical: BatshSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide(
            color: BatshColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: const BorderSide(color: BatshColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: const BorderSide(color: BatshColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: const BorderSide(color: BatshColors.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: BatshColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BatshRadius.brLg),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: BatshColors.surfaceContainerLow,
        selectedItemColor: BatshColors.primary,
        unselectedItemColor: BatshColors.onSurfaceVariant.withValues(
          alpha: 0.55,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: BatshTypography.labelSm.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: BatshTypography.labelSm.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BatshColors.surfaceContainer,
        selectedColor: BatshColors.primaryFixed,
        disabledColor: BatshColors.surfaceContainerHigh,
        labelStyle: BatshTypography.labelMd,
        secondaryLabelStyle: BatshTypography.labelMd.copyWith(
          color: BatshColors.primary,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: BatshColors.outlineVariant),
        shape: const RoundedRectangleBorder(borderRadius: BatshRadius.brFull),
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
        contentTextStyle: BatshTypography.bodyMd.copyWith(
          color: BatshColors.inverseOnSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BatshRadius.brMd),
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
        shape: const RoundedRectangleBorder(borderRadius: BatshRadius.brSm),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.all(
          BatshColors.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colors = BatshColors.darkScheme;
    final textTheme = BatshTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
      brightness: Brightness.dark,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      typography: Typography.material2021(
        platform: TargetPlatform.android,
        colorScheme: colors,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: BatshTypography.titleLg.copyWith(
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.surfaceContainerHigh,
          disabledForegroundColor: colors.onSurfaceVariant,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.lg,
            vertical: BatshSpacing.gutter,
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
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.outline, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.lg,
            vertical: BatshSpacing.gutter,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BatshRadius.brDefault,
          ),
          textStyle: BatshTypography.labelMd.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(0, 48),
          textStyle: BatshTypography.labelMd.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        hintStyle: BatshTypography.bodyMd.copyWith(
          color: colors.onSurfaceVariant,
        ),
        labelStyle: BatshTypography.bodyMd.copyWith(
          color: colors.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.gutter,
          vertical: BatshSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BatshRadius.brMd,
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BatshRadius.brLg),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLow,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLow,
        indicatorColor: colors.primaryContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => BatshTypography.labelSm.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainer,
        selectedColor: colors.primaryContainer,
        disabledColor: colors.surfaceContainerHigh,
        labelStyle: BatshTypography.labelMd,
        secondaryLabelStyle: BatshTypography.labelMd.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: colors.outlineVariant),
        shape: const RoundedRectangleBorder(borderRadius: BatshRadius.brFull),
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.md,
          vertical: BatshSpacing.sm,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: BatshTypography.bodyMd.copyWith(
          color: colors.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BatshRadius.brMd),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.surfaceContainerLowest,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceContainerHighest,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : Colors.transparent,
        ),
        side: BorderSide(color: colors.outline, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BatshRadius.brSm),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.all(
          colors.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
