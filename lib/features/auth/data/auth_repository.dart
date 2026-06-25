import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../domain/profile.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Future<void> sendOtp(String phone) =>
      _client.auth.signInWithOtp(phone: phone);

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String code,
  }) =>
      _client.auth.verifyOTP(
        phone: phone,
        token: code,
        type: OtpType.sms,
      );

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Stream<AuthState> watchAuthState() => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  Future<void> updateRole({
    required String userId,
    required UserRole role,
    required String fullName,
  }) async {
    await _client.from('profiles').update({
      'role': role.name,
      'full_name': fullName,
    }).eq('id', userId);
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(supabaseClientProvider));
