import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/media/media_storage.dart';
import '../../../core/media/media_storage_provider.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../domain/profile.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  AuthRepository(this._client, [MediaStorageService? mediaStorage])
      : _mediaStorage = mediaStorage;
  final SupabaseClient _client;
  final MediaStorageService? _mediaStorage;

  Future<void> sendOtp(String phone) =>
      _client.auth.signInWithOtp(phone: phone);

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String code,
  }) => _client.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) => _client.auth.signInWithPassword(email: email, password: password);

  /// Primary (free) auth: phone + password. Requires Supabase "Confirm phone"
  /// to be OFF so no SMS is sent on sign-up.
  Future<AuthResponse> signInWithPhonePassword({
    required String phone,
    required String password,
  }) => _client.auth.signInWithPassword(phone: phone, password: password);

  Future<AuthResponse> signUpWithPhonePassword({
    required String phone,
    required String password,
  }) => _client.auth.signUp(phone: phone, password: password);

  /// Sets a new password for the signed-in user (used after a forgot-password
  /// SMS OTP restores the session).
  Future<UserResponse> updatePassword(String newPassword) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

  /// Social sign-in (free, no SMS). On web this redirects the page to Google
  /// and back; the session is restored from the return URL.
  Future<bool> signInWithGoogle() =>
      _client.auth.signInWithOAuth(OAuthProvider.google);

  /// Sign in with Apple.
  ///
  /// Not optional on iOS: App Store guideline 4.8 requires an equivalent
  /// privacy-preserving login option wherever a third-party social login is
  /// offered, and this app offers Google. Shipping to the App Store without
  /// this is a guaranteed rejection.
  Future<bool> signInWithApple() =>
      _client.auth.signInWithOAuth(OAuthProvider.apple);

  Future<void> signOut() => _client.auth.signOut();

  /// Permanently deletes the signed-in user and everything they own.
  ///
  /// All the work happens in the `delete_my_account` RPC: a client
  /// cannot delete its own `auth.users` row, and doing the cleanup in one
  /// server-side transaction is what stops an account ending up half-deleted.
  ///
  /// The local sign-out afterwards is belt and braces — the session's user no
  /// longer exists, so every later request would fail anyway, but clearing it
  /// returns the app to the landing screen immediately instead of showing a
  /// signed-in shell full of errors.
  Future<void> deleteAccount() async {
    // R2 is outside Postgres, so purge the user's public R2 namespace while
    // the access token is still valid. If that boundary cannot complete, do
    // not run the irreversible Supabase deletion RPC.
    await _mediaStorage?.purgeOwnedPublicMedia();
    await _client.rpc('delete_my_account');
    await _client.auth.signOut();
  }

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
    String profileId,
  ) async {
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
    await _client
        .from('profiles')
        .update({'role': role.name, 'full_name': fullName})
        .eq('id', userId);
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(
      ref.watch(supabaseClientProvider),
      ref.watch(mediaStorageProvider),
    );
