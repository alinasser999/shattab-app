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

  /// Primary (free) auth: phone + password. Requires Supabase "Confirm phone"
  /// to be OFF so no SMS is sent on sign-up.
  Future<AuthResponse> signInWithPhonePassword({
    required String phone,
    required String password,
  }) =>
      _client.auth.signInWithPassword(phone: phone, password: password);

  Future<AuthResponse> signUpWithPhonePassword({
    required String phone,
    required String password,
  }) =>
      _client.auth.signUp(phone: phone, password: password);

  /// Sets a new password for the signed-in user (used after a forgot-password
  /// SMS OTP restores the session).
  Future<UserResponse> updatePassword(String newPassword) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

  /// Social sign-in (free, no SMS). On web this redirects the page to Google
  /// and back; the session is restored from the return URL.
  Future<bool> signInWithGoogle() =>
      _client.auth.signInWithOAuth(OAuthProvider.google);

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

  Future<({String name, String phone})?> fetchProfileNameAndPhone(
      String profileId) async {
    final row = await _client
        .from('profiles')
        .select('full_name, phone')
        .eq('id', profileId)
        .maybeSingle();
    if (row == null) return null;
    return (
      name: (row['full_name'] as String?) ?? '',
      phone: (row['phone'] as String?) ?? '',
    );
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
