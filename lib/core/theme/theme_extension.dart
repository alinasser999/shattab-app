import 'package:flutter/material.dart';

extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
}

/// Semantic roles the Modern Heritage palette needs but Material 3 does not
/// model.
///
/// Material gives us `error` and nothing else with a meaning attached, so
/// "this succeeded" and "look at this" have to borrow existing roles. The
/// mapping matches `BatshColors`: success rides on olive (secondary), warning
/// on gold (tertiary). Both swap correctly in dark mode because they resolve
/// through the scheme rather than through a `const` colour.
///
/// Defining them here rather than at each call site means a palette change
/// moves one line, and `context.colorScheme.success` reads like a first-class
/// role — which is what the call sites already assumed it was.
extension BatshColorRoles on ColorScheme {
  Color get success => secondary;
  Color get onSuccess => onSecondary;
  Color get successContainer => secondaryContainer;
  Color get onSuccessContainer => onSecondaryContainer;

  Color get warning => tertiary;
  Color get onWarning => onTertiary;
  Color get warningContainer => tertiaryContainer;
  Color get onWarningContainer => onTertiaryContainer;

  /// Material spells this `onInverseSurface`. `BatshColors` spells it
  /// `inverseOnSurface`, and so does every call site in this app.
  Color get inverseOnSurface => onInverseSurface;
}
