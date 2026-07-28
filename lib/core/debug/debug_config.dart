import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/domain/profile.dart';

/// Debug auth: sign in as a seeded real test user so EVERY feature (posting,
/// quoting, requests) works against real Supabase RLS — mocking a profile can't
/// do that because writes need a real `auth.uid()`.
///
/// Tree-shaken in release (kDebugMode = false) → the seeded creds never ship.
/// The user (auth.users id `deb00000-0000-4000-8000-000000000001`) was seeded
/// via SQL with both a contractor and homeowner sub-profile so the banner can
/// flip roles instantly. To remove: `delete from auth.users where id=...`.
const bool kDebugAuth = kDebugMode;
const String kDebugEmail = 'debug.tester@shattab.test';
const String kDebugPassword = 'Debug!2026';

/// Sign the seeded debug user in once at startup if there's no session yet.
Future<void> debugSignIn(SupabaseClient client) async {
  if (!kDebugAuth) return;
  if (client.auth.currentSession != null) return;
  try {
    await client.auth.signInWithPassword(
      email: kDebugEmail,
      password: kDebugPassword,
    );
  } catch (e) {
    debugPrint('debug sign-in failed: $e');
  }
}

/// Flip the debug user's role in the DB (both sub-profiles already exist).
/// Caller refreshes currentProfile so the router redirects to the new shell.
Future<void> debugSwitchRole(SupabaseClient client, UserRole role) async {
  final id = client.auth.currentUser?.id;
  if (id == null) return;
  await client.from('profiles').update({'role': role.name}).eq('id', id);
}
