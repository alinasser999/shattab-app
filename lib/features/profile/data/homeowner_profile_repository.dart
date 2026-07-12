import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../onboarding/domain/onboarding_models.dart';

part 'homeowner_profile_repository.g.dart';

class HomeownerProfileRepository {
  HomeownerProfileRepository(this._client);
  final SupabaseClient _client;

  Future<String> uploadAvatar({
    required String profileId,
    required File file,
  }) async {
    final path = '$profileId/avatar.jpg';
    await _client.storage.from('avatars').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    final url = _client.storage.from('avatars').getPublicUrl(path);
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updateProfile({
    required String profileId,
    String? fullName,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    if (payload.isEmpty) return;
    await _client.from('profiles').update(payload).eq('id', profileId);
  }

  Future<void> upsertHomeownerFields({
    required String profileId,
    ApartmentType? apartmentType,
    String? city,
    String? district,
    List<String>? renovationInterests,
  }) async {
    final payload = <String, dynamic>{'profile_id': profileId};
    if (apartmentType != null) payload['apartment_type'] = apartmentType.dbValue;
    if (city != null) payload['city'] = city;
    if (district != null) payload['district'] = district;
    if (renovationInterests != null) {
      payload['renovation_interests'] = renovationInterests;
    }
    await _client
        .from('homeowner_profiles')
        .upsert(payload, onConflict: 'profile_id');
  }
}

@Riverpod(keepAlive: true)
HomeownerProfileRepository homeownerProfileRepository(Ref ref) =>
    HomeownerProfileRepository(ref.watch(supabaseClientProvider));
