import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final session = ref.watch(currentSessionProvider);
    if (session == null) return null;
    final repo = ref.watch(authRepositoryProvider);
    return repo.fetchProfile(session.user.id);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final session = ref.read(currentSessionProvider);
      if (session == null) return null;
      return ref.read(authRepositoryProvider).fetchProfile(session.user.id);
    });
  }
}
