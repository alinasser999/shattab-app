import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../domain/brief.dart';

part 'briefs_repository.g.dart';

class BriefsRepository {
  BriefsRepository(this._client);
  final SupabaseClient _client;

  Future<List<Brief>> fetchMine(String homeownerId) async {
    final rows = await _client
        .from('briefs')
        .select()
        .eq('homeowner_id', homeownerId)
        .order('created_at', ascending: false);
    return rows.map(Brief.fromJson).toList();
  }

  Future<Brief?> fetchById(String id) async {
    final row =
        await _client.from('briefs').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Brief.fromJson(row);
  }

  /// Posts matching the calling contractor by specialty ∩ service_area.
  Future<List<Brief>> fetchOpportunitiesForContractor() async {
    final profile = await _client
        .from('contractor_profiles')
        .select('specialties, service_areas')
        .eq('profile_id', _uid)
        .maybeSingle();

    final specialties = (profile?['specialties'] as List?)?.cast<String>() ?? <String>[];
    final serviceAreas = (profile?['service_areas'] as List?)?.cast<String>() ?? <String>[];

    var query = _client
        .from('briefs')
        .select()
        .isFilter('target_contractor_id', null)
        .isFilter('hired_at', null) // hired jobs leave the feed (migration 0009)
        .eq('status', 'open');

    if (specialties.isNotEmpty) {
      query = query.overlaps('target_specialties', specialties);
    }
    if (serviceAreas.isNotEmpty) {
      query = query.inFilter('city', serviceAreas);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows.map(Brief.fromJson).toList();
  }

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  /// Direct briefs sent to the calling contractor.
  Future<List<Brief>> fetchDirectBriefsForContractor() async {
    final rows = await _client
        .from('briefs')
        .select()
        .not('target_contractor_id', 'is', 'null')
        .eq('target_contractor_id', _uid)
        .order('created_at', ascending: false);
    return rows.map(Brief.fromJson).toList();
  }

  Future<Brief> createBrief({
    required String homeownerId,
    String? targetContractorId,
    required ApartmentType apartmentType,
    required String city,
    String? district,
    required String workDescription,
    required List<String> photoUrls,
    required List<String> targetSpecialties,
  }) async {
    final row = await _client
        .from('briefs')
        .insert({
          'homeowner_id': homeownerId,
          'target_contractor_id': targetContractorId,
          'apartment_type': apartmentType.dbValue,
          'city': city,
          'district': district,
          'work_description': workDescription,
          'photo_urls': photoUrls,
          'target_specialties': targetSpecialties,
        })
        .select()
        .single();
    return Brief.fromJson(row);
  }

  Future<void> cancelBrief(String briefId) async {
    await _client
        .from('briefs')
        .update({'status': 'cancelled'}).eq('id', briefId);
  }

  Future<void> setPhotoUrls(String briefId, List<String> urls) async {
    await _client
        .from('briefs')
        .update({'photo_urls': urls}).eq('id', briefId);
  }

  /// Uploads a single photo to brief-photos bucket. Returns the public URL.
  /// Path: {homeowner_id}/{brief_id_or_draft_id}/{seq}.jpg
  Future<String> uploadPhoto({
    required String homeownerId,
    required String draftId,
    required int seq,
    File? file,
    Uint8List? bytes,
  }) async {
    final path = '$homeownerId/$draftId/$seq.jpg';
    final storage = _client.storage.from('brief-photos');
    if (file != null) {
      await storage.upload(path, file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    } else if (bytes != null) {
      await storage.uploadBinary(path, bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    } else {
      throw ArgumentError('uploadPhoto needs either file or bytes');
    }
    return storage.getPublicUrl(path);
  }
}

@Riverpod(keepAlive: true)
BriefsRepository briefsRepository(Ref ref) =>
    BriefsRepository(ref.watch(supabaseClientProvider));
