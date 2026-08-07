import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/domain/profile.dart';
import '../env/env.dart';
import '../logging/app_logger.dart';

/// Signs into a seeded local test user only when explicitly enabled through
/// ignored `.env` values. This path is unavailable in release builds.
const bool kDebugAuth = kDebugMode;

/// Sign the seeded debug user in once at startup if there is no session yet.
Future<void> debugSignIn(SupabaseClient client) async {
  if (!kDebugAuth || !Env.debugAuthEnabled) return;
  if (client.auth.currentSession != null) return;

  final email = Env.debugAuthEmail;
  final password = Env.debugAuthPassword;
  if (email == null || password == null) {
    AppLogger.warning('debug auth skipped: credentials are not configured');
    return;
  }

  try {
    await client.auth.signInWithPassword(email: email, password: password);
  } catch (error, stackTrace) {
    AppLogger.error(
      'debug auth sign-in failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Flip the debug user's role in the DB. The caller refreshes current profile
/// so the router redirects to the new shell.
Future<void> debugSwitchRole(SupabaseClient client, UserRole role) async {
  final id = client.auth.currentUser?.id;
  if (id == null) return;
  await client.from('profiles').update({'role': role.name}).eq('id', id);
}
