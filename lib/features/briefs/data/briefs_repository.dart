import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../domain/brief.dart';

part 'briefs_repository.g.dart';

/// Cursor for keyset pagination over the opportunities feed.
///
/// `(created_at, id)` is used as the sort tuple rather than `created_at` alone
/// so same-second briefs get a stable order across pages.
class BriefCursor {
  const BriefCursor({required this.createdAt, required this.id});

  factory BriefCursor.fromBrief(Brief brief) =>
      BriefCursor(createdAt: brief.createdAt, id: brief.id);

  final DateTime createdAt;
  final String id;
}

class BriefsRepository {
  BriefsRepository(this._client);
  final SupabaseClient _client;

  /// Page size for the opportunities feed. Bounds every fetch — the previous
  /// query had no limit at all and pulled every matching open brief.
  static const int pageSize = 20;

  Future<List<Brief>> fetchMine(String homeownerId) async {
    final rows = await _client
        .from('briefs')
        .select()
        .eq('homeowner_id', homeownerId)
        .order('created_at', ascending: false);
    return rows.map(Brief.fromJson).toList();
  }

  Future<Brief?> fetchById(String id) async {
    final row = await _client
        .from('briefs')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Brief.fromJson(row);
  }

  /// Posts matching the calling contractor by specialty ∩ service_area.
  ///
  /// Bounded to [limit] rows and filtered server-side. Pass [after] (the last
  /// brief already held) to get the next page, and [searchQuery] to narrow by
  /// work description.
  ///
  /// Search covers `work_description` only: the description is where the words
  /// a contractor types actually live, and keeping it to one column avoids an
  /// `or(...)` that would collide with the cursor's. City and district stay on
  /// the filter sheet.
  Future<List<Brief>> fetchOpportunitiesForContractor({
    String? searchQuery,
    BriefCursor? after,
    int limit = pageSize,
  }) async {
    final profile = await _client
        .from('contractor_profiles')
        .select('specialties, service_areas')
        .eq('profile_id', _uid)
        .maybeSingle();

    final specialties =
        (profile?['specialties'] as List?)?.cast<String>() ?? <String>[];
    final serviceAreas =
        (profile?['service_areas'] as List?)?.cast<String>() ?? <String>[];

    var query = _client
        .from('briefs')
        .select()
        .isFilter('target_contractor_id', null)
        .isFilter(
          'hired_at',
          null,
        ) // hired jobs leave the feed (migration 0009)
        .eq('status', 'open');

    if (specialties.isNotEmpty) {
      query = query.overlaps('target_specialties', specialties);
    }
    if (serviceAreas.isNotEmpty) {
      query = query.inFilter('city', serviceAreas);
    }

    final q = sanitizeLikePattern(searchQuery);
    if (q != null) {
      query = query.ilike('work_description', '%$q%');
    }

    if (after != null) {
      // Strictly older than the cursor on the (created_at, id) tuple. Keyset,
      // not offset: briefs posted while a contractor scrolls would otherwise
      // shift the window and duplicate or skip rows (the same defect migration
      // 0017 fixed for the social feed).
      final iso = after.createdAt.toUtc().toIso8601String();
      query = query.or(
        'created_at.lt.$iso,and(created_at.eq.$iso,id.lt.${after.id})',
      );
    }

    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    return rows.map(Brief.fromJson).toList();
  }

  /// Edits a brief's scope. The database stamps `edited_at` and rejects the
  /// update outright once the brief is hired (migration 0020), so the client
  /// cannot quietly rewrite work that is already underway.
  Future<void> updateBrief(
    String briefId, {
    required ApartmentType apartmentType,
    required String city,
    String? district,
    required String workDescription,
    required List<String> targetSpecialties,
  }) async {
    await _client
        .from('briefs')
        .update({
          'apartment_type': apartmentType.name,
          'city': city,
          'district': district,
          'work_description': workDescription,
          'target_specialties': targetSpecialties,
        })
        .eq('id', briefId);
  }

  /// Removes a brief, degrading to cancel when contractors have already quoted.
  ///
  /// Returns `'deleted'` or `'cancelled'` so the caller can tell the user what
  /// actually happened. The decision is made server-side (migration 0020)
  /// because checking for quotes here and deleting afterwards would race a
  /// quote arriving in between — and losing that race destroys a contractor's
  /// work through the `on delete cascade`.
  Future<String> deleteOrCancelBrief(String briefId) async {
    final result = await _client.rpc(
      'delete_or_cancel_brief',
      params: {'p_brief_id': briefId},
    );
    return result as String? ?? 'cancelled';
  }

  /// Contractor signals the hired work is finished (migration 0019).
  ///
  /// A nudge, not a completion: only the homeowner can complete the job. The
  /// RPC owns authorization (caller must hold the accepted quote) and is
  /// idempotent, so a double tap cannot re-notify.
  Future<void> requestCompletion(String briefId) async {
    await _client.rpc('request_completion', params: {'p_brief_id': briefId});
  }

  /// Homeowner confirms the work is done (migration 0019).
  ///
  /// This is the transition that unlocks reviews and increments the
  /// contractor's `projects_completed`. Idempotent in SQL, so a retry after a
  /// dropped connection cannot double-count.
  Future<void> confirmCompletion(String briefId) async {
    await _client.rpc('confirm_completion', params: {'p_brief_id': briefId});
  }

  /// Strips LIKE metacharacters so a user typing `%` doesn't turn their search
  /// into a match-everything wildcard. Returns null for a blank query.
  ///
  /// Visible for testing.
  static String? sanitizeLikePattern(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final cleaned = trimmed.replaceAll(RegExp(r'[%_*]'), ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
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
        .neq('status', 'cancelled') // a cancelled request must leave the inbox
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
        .update({'status': 'cancelled'})
        .eq('id', briefId);
  }

  Future<void> setPhotoUrls(String briefId, List<String> urls) async {
    await _client.from('briefs').update({'photo_urls': urls}).eq('id', briefId);
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
      await storage.upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
    } else if (bytes != null) {
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
    } else {
      throw ArgumentError('uploadPhoto needs either file or bytes');
    }
    return storage.getPublicUrl(path);
  }
}

@Riverpod(keepAlive: true)
BriefsRepository briefsRepository(Ref ref) =>
    BriefsRepository(ref.watch(supabaseClientProvider));
