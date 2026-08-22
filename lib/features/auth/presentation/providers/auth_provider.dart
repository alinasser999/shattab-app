import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/connectivity.dart';
import '../../data/auth_repository.dart';
import '../../domain/profile.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) =>
    ref.watch(authRepositoryProvider).watchAuthState();

@Riverpod(keepAlive: true)
Session? currentSession(Ref ref) {
  final asyncAuth = ref.watch(authStateChangesProvider);
  return asyncAuth.maybeWhen(
    data: (state) => state.session,
    orElse: () => ref.watch(authRepositoryProvider).currentSession,
  );
}

@Riverpod(keepAlive: true)
class CurrentProfile extends _$CurrentProfile {
  @override
  Future<Profile?> build() async {
    // Watching connectivity makes a failed fetch self-heal: the provider
    // rebuilds on the offline→online edge, which the router relies on to
    // move a parked-on-splash user forward again.
    final online = ref.watch(connectivityProvider).value ?? true;
    final session = ref.watch(currentSessionProvider);
    if (session == null) return null;
    final repo = ref.watch(authRepositoryProvider);
    // Absorb short startup blips (up to three attempts, ~2.4s worst case)
    // rather than surfacing an error the router would have to guess about.
    // While offline, fail fast and wait for the connectivity edge instead.
    var delay = const Duration(milliseconds: 800);
    for (var attempt = 0; ; attempt++) {
      try {
        return await repo.fetchProfile(session.user.id);
      } catch (_) {
        if (attempt >= 2 || !online) rethrow;
        await Future<void>.delayed(delay);
        delay *= 2;
      }
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final session = ref.read(currentSessionProvider);
      if (session == null) return null;
      return ref.read(authRepositoryProvider).fetchProfile(session.user.id);
    });
  }
}
