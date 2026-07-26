import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../discovery/domain/contractor_listing.dart';
import '../domain/onboarding_models.dart';

part 'onboarding_repository.g.dart';

class OnboardingRepository {
  OnboardingRepository(this._client);
  final SupabaseClient _client;

  Future<HomeownerProfile?> fetchHomeowner(String profileId) async {
    final row = await _client
        .from('homeowner_profiles')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();
    if (row == null) return null;
    return HomeownerProfile.fromJson(row);
  }

  Future<ContractorProfile?> fetchContractor(String profileId) async {
    final row = await _client
        .from('contractor_profiles')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();
    if (row == null) return null;
    return ContractorProfile.fromJson(row);
  }

  Future<void> upsertHomeowner({
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

  Future<void> upsertContractor({
    required String profileId,
    String? businessName,
    String? logoUrl,
    String? coverPhotoUrl,
    String? headline,
    String? bio,
    List<String>? specialties,
    List<String>? serviceAreas,
    int? yearsExperience,
    ProviderKind? providerKind,
  }) async {
    final payload = <String, dynamic>{'profile_id': profileId};
    // `.wire`, not `.name`: the enum is camelCase, the CHECK constraint in 0026
    // expects snake_case.
    if (providerKind != null) payload['provider_kind'] = providerKind.wire;
    if (businessName != null) payload['business_name'] = businessName;
    if (logoUrl != null) payload['logo_url'] = logoUrl;
    if (coverPhotoUrl != null) payload['cover_photo_url'] = coverPhotoUrl;
    if (headline != null) payload['headline'] = headline;
    if (bio != null) payload['bio'] = bio;
    if (specialties != null) payload['specialties'] = specialties;
    if (serviceAreas != null) payload['service_areas'] = serviceAreas;
    if (yearsExperience != null) payload['years_experience'] = yearsExperience;
    await _client
        .from('contractor_profiles')
        .upsert(payload, onConflict: 'profile_id');
  }

  Future<void> updateFullName({
    required String profileId,
    required String fullName,
  }) async {
    await _client
        .from('profiles')
        .update({'full_name': fullName}).eq('id', profileId);
  }

  Future<void> markOnboardingComplete(String profileId) async {
    await _client
        .from('profiles')
        .update({'onboarding_complete': true}).eq('id', profileId);
  }

  Future<String> uploadContractorLogo({
    required String profileId,
    required File file,
  }) async {
    final path = '$profileId/logo.jpg';
    await _client.storage.from('contractor-logos').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('contractor-logos').getPublicUrl(path);
  }

  Future<String> uploadContractorCover({
    required String profileId,
    required File file,
  }) async {
    final path = '$profileId/cover.jpg';
    await _client.storage.from('contractor-logos').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    // Cache-bust so a re-upload to the same path refreshes in CachedNetworkImage.
    final url = _client.storage.from('contractor-logos').getPublicUrl(path);
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}

@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(Ref ref) =>
    OnboardingRepository(ref.watch(supabaseClientProvider));
