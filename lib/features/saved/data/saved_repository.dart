import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../discovery/domain/contractor_listing.dart';

part 'saved_repository.g.dart';

class SavedRepository {
  SavedRepository(this._client);
  final SupabaseClient _client;

  Future<Set<String>> fetchSavedIds(String homeownerId) async {
    final rows = await _client
        .from('saved_contractors')
        .select('contractor_id')
        .eq('homeowner_id', homeownerId);
    return rows.map((r) => r['contractor_id'] as String).toSet();
  }

  Future<List<ContractorListing>> fetchSavedListings(
      String homeownerId) async {
    final saved = await _client
        .from('saved_contractors')
        .select(
            'contractor:profiles!contractor_id(id, full_name, phone, contractor_profiles!inner(business_name, bio, logo_url, cover_photo_url, headline, specialties, service_areas, years_experience, projects_completed, response_rate))')
        .eq('homeowner_id', homeownerId)
        .order('saved_at', ascending: false)
        // Bounded: this join pulls a full contractor profile per saved row, so
        // an unbounded read gets expensive faster than the row count suggests.
        .limit(100);
    return saved
        .map((r) => ContractorListing.fromJoined(
            r['contractor'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(
      {required String homeownerId, required String contractorId}) async {
    await _client.from('saved_contractors').upsert({
      'homeowner_id': homeownerId,
      'contractor_id': contractorId,
    }, onConflict: 'homeowner_id, contractor_id');
  }

  Future<void> unsave(
      {required String homeownerId, required String contractorId}) async {
    await _client
        .from('saved_contractors')
        .delete()
        .eq('homeowner_id', homeownerId)
        .eq('contractor_id', contractorId);
  }
}

@Riverpod(keepAlive: true)
SavedRepository savedRepository(Ref ref) =>
    SavedRepository(ref.watch(supabaseClientProvider));
