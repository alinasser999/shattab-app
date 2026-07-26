import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../briefs/domain/brief.dart';
import '../domain/quote.dart';

part 'quotes_repository.g.dart';

class QuotesRepository {
  QuotesRepository(this._client);
  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  /// Upper bound on any list read here.
  ///
  /// These queries were previously unbounded. A contractor two years in would
  /// download their entire quote history every time they opened the tab, and a
  /// popular brief would return every offer ever made on it. Neither list has a
  /// UI that can use more than a screenful.
  static const int maxRows = 100;

  /// Homeowner view — all quotes on a brief they own (RLS: homeowner_read).
  Future<List<Quote>> fetchForBrief(String briefId) async {
    final rows = await _client
        .from('quotes')
        .select()
        .eq('brief_id', briefId)
        .order('created_at', ascending: true)
        .limit(maxRows);
    return rows.map(Quote.fromJson).toList();
  }

  /// Contractor view — every quote I've sent (RLS: contractor_own).
  Future<List<Quote>> fetchMine() async {
    final rows = await _client
        .from('quotes')
        .select()
        .eq('contractor_id', _uid)
        .order('created_at', ascending: false)
        .limit(maxRows);
    return rows.map(Quote.fromJson).toList();
  }

  /// Contractor view — my quotes with their brief already attached.
  ///
  /// The quotes list needs each quote's brief for the title and the completion
  /// card. Resolving that per row (a `briefById` watch inside the list item
  /// builder) meant N sequential HTTP requests: 50 quotes was 50 round trips,
  /// which on mobile latency is several seconds of spinner while the database
  /// sits idle. PostgREST can embed the parent through the `brief_id` foreign
  /// key, so this is one request regardless of list length.
  ///
  /// The brief is nullable: RLS may hide it (cancelled, or filtered server-side)
  /// even when the quote itself is still readable.
  Future<List<({Quote quote, Brief? brief})>> fetchMineWithBriefs() async {
    final rows = await _client
        .from('quotes')
        .select('*, briefs(*)')
        .eq('contractor_id', _uid)
        .order('created_at', ascending: false)
        .limit(maxRows);

    return rows.map((row) {
      final embedded = row['briefs'];
      return (
        quote: Quote.fromJson(row),
        brief:
            embedded is Map<String, dynamic> ? Brief.fromJson(embedded) : null,
      );
    }).toList();
  }

  /// Contractor view — my quote on a single brief, or null if none yet.
  Future<Quote?> fetchMineForBrief(String briefId) async {
    final row = await _client
        .from('quotes')
        .select()
        .eq('brief_id', briefId)
        .eq('contractor_id', _uid)
        .maybeSingle();
    if (row == null) return null;
    return Quote.fromJson(row);
  }

  /// Insert or update my quote on a brief. Re-submitting resets status to
  /// `sent` (a freshly edited offer is pending again).
  Future<Quote> submit({
    required String briefId,
    int? priceMin,
    int? priceMax,
    String? durationText,
    required String note,
  }) async {
    final row = await _client
        .from('quotes')
        .upsert(
          {
            'brief_id': briefId,
            'contractor_id': _uid,
            'price_min': priceMin,
            'price_max': priceMax,
            'duration_text': durationText,
            'note': note,
            'status': 'sent',
          },
          onConflict: 'brief_id,contractor_id',
        )
        .select()
        .single();
    return Quote.fromJson(row);
  }

  /// Homeowner accept/decline.
  ///
  /// Accept routes through the `accept_quote` RPC (migration 0009): it flips
  /// this quote to accepted, auto-declines the brief's other pending quotes,
  /// and marks the brief hired — atomically, server-side. Decline is a plain
  /// status update (RLS: homeowner_status restricts the allowed values).
  Future<void> setStatus(String quoteId, QuoteStatus status) async {
    if (status == QuoteStatus.accepted) {
      await _client.rpc('accept_quote', params: {'p_quote_id': quoteId});
      return;
    }
    final rows = await _client
        .from('quotes')
        .update({'status': status.name}).eq('id', quoteId).select();
    if (rows.isEmpty) {
      throw StateError('Quote not found or cannot be updated.');
    }
  }
}

@Riverpod(keepAlive: true)
QuotesRepository quotesRepository(Ref ref) =>
    QuotesRepository(ref.watch(supabaseClientProvider));
