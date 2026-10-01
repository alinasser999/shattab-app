import 'package:flutter/foundation.dart';

/// Compile-time switches for developer tooling.
///
/// Debug builds expose the tools by default so `flutter run` is enough for a
/// fast inspection loop. A define can turn them off for a focused debug run;
/// release and profile builds can never expose them.
abstract final class DebugFlags {
  /// Shows the in-app role switcher (view the app as the other role without
  /// a second account). The switch is client-side only — the database
  /// rejects real role changes (`tg_guard_profile_authority`), so this can
  /// never mutate account state.
  static const bool roleSwitcher =
      kDebugMode &&
      bool.fromEnvironment('SHATTAB_DEBUG_TOOLS', defaultValue: true);
}
