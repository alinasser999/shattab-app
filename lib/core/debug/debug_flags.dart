import 'package:flutter/foundation.dart';

/// Compile-time switches for developer tooling.
///
/// Local debug builds expose the developer tools by default. Release review
/// login has its own explicit gate; the view-only role switcher remains
/// debug-only.
abstract final class DebugFlags {
  static const bool _previewLogin = bool.fromEnvironment(
    'SHATTAB_PREVIEW_DEBUG_LOGIN',
    defaultValue: false,
  );

  /// Shows the runtime-credential login panel in local debug builds or when
  /// explicitly enabled for a review Preview. This flag does not enable the
  /// separate view-only role switcher.
  static const bool loginVisible = kDebugMode || _previewLogin;

  /// Shows the in-app role switcher (view the app as the other role without
  /// a second account). The switch is client-side only — the database
  /// rejects real role changes (`tg_guard_profile_authority`), so this can
  /// never mutate account state.
  static const bool roleSwitcher =
      kDebugMode &&
      !_previewLogin &&
      bool.fromEnvironment('SHATTAB_DEBUG_TOOLS', defaultValue: true);
}
