import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/profile.dart';
import 'debug_flags.dart';

/// Client-side role override for the debug role switcher.
///
/// Null means "no override — the account's real role applies". When set,
/// [DebugRoleOverride] only changes what the *router and shells* see: the
/// database still knows the truth, every RLS policy still evaluates against
/// the real account, and nothing is ever written. Browsing the other role
/// with your own account may therefore show empty contractor/homeowner
/// surfaces — that is honest, not broken.
///
/// Manual provider rather than codegen: debug-only tooling, and the codebase
/// already keeps a handful of manual core providers (theme, locale).
final debugRoleOverrideProvider =
    NotifierProvider<DebugRoleOverride, UserRole?>(DebugRoleOverride.new);

/// Returns the profile that the UI should render for the current debug view.
///
/// This is deliberately a pure, client-side transformation. The returned
/// profile is never persisted and must not be used as authorization evidence.
Profile? profileForDebugRole(Profile? profile, UserRole? override) {
  if (!DebugFlags.roleSwitcher ||
      profile == null ||
      override == null ||
      profile.role == override) {
    return profile;
  }
  return profile.copyWith(role: override);
}

class DebugRoleOverride extends Notifier<UserRole?> {
  @override
  UserRole? build() => null;

  void set(UserRole? role) => state = role;
}
