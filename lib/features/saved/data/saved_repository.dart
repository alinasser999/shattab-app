import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../discovery/domain/contractor_listing.dart';

part 'saved_repository.g.dart';

/// Stable cursor for the homeowner's saved-professionals collection.
///
/// `saved_at` is the primary ordering key and the contractor id breaks ties
/// when two saves share the same timestamp precision.
class SavedCursor {
  const SavedCursor({required this.savedAt, required this.contractorId});

  final DateTime savedAt;
  final String contractorId;

  factory SavedCursor.fromRow(Map<String, dynamic> row) {
    final rawSavedAt = row['saved_at'];
    final savedAt = rawSavedAt is DateTime
        ? rawSavedAt
        : DateTime.tryParse(rawSavedAt?.toString() ?? '');
    if (savedAt == null) {
      throw const FormatException('saved_cursor_missing_timestamp');
    }
    return SavedCursor(savedAt: savedAt, contractorId: row['id'] as String);
  }
}

class SavedRepository {
  SavedRepository(this._client);
  final SupabaseClient _client;

  static const int pageSize = 20;

  Future<SavedPage> fetchSavedPage(
    String homeownerId, {
    SavedCursor? after,
    int limit = pageSize,
  }) async {
    final boundedLimit = limit.clamp(1, 50).toInt();
    final rows = await _client
        .rpc(
          'get_saved_contractors_cursor',
          params: {
            'p_homeowner_id': homeownerId,
            'p_limit': boundedLimit,
            'p_after_saved_at': after?.savedAt.toUtc().toIso8601String(),
            'p_after_contractor_id': after?.contractorId,
          },
        )
        .timeout(const Duration(seconds: 15));
    final rawRows = (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    return SavedPage(
      items: rawRows.map(ContractorListing.fromJoined).toList(growable: false),
      cursor: rawRows.isEmpty ? null : SavedCursor.fromRow(rawRows.last),
      requestedLimit: boundedLimit,
    );
  }

  Future<Set<String>> fetchSavedIds(String homeownerId) async {
    final rows = await _client
        .from('saved_contractors')
        .select('contractor_id')
        .eq('homeowner_id', homeownerId)
        .timeout(const Duration(seconds: 10));
    return rows.map((r) => r['contractor_id'] as String).toSet();
  }

  Future<List<ContractorListing>> fetchSavedListings(String homeownerId) async {
    return (await fetchSavedPage(homeownerId)).items;
  }

  Future<void> save({
    required String homeownerId,
    required String contractorId,
  }) async {
    await _client
        .from('saved_contractors')
        .upsert({
          'homeowner_id': homeownerId,
          'contractor_id': contractorId,
        }, onConflict: 'homeowner_id, contractor_id')
        .timeout(const Duration(seconds: 15));
  }

  Future<void> unsave({
    required String homeownerId,
    required String contractorId,
  }) async {
    await _client
        .from('saved_contractors')
        .delete()
        .eq('homeowner_id', homeownerId)
        .eq('contractor_id', contractorId)
        .timeout(const Duration(seconds: 15));
  }
}

@Riverpod(keepAlive: true)
SavedRepository savedRepository(Ref ref) =>
    SavedRepository(ref.watch(supabaseClientProvider));

class SavedPage {
  const SavedPage({
    required this.items,
    required this.cursor,
    required this.requestedLimit,
  });

  final List<ContractorListing> items;
  final SavedCursor? cursor;
  final int requestedLimit;

  bool get hasMore => items.length == requestedLimit;
}
