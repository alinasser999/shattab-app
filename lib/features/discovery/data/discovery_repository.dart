import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../domain/contractor_listing.dart';

part 'discovery_repository.g.dart';

class DiscoveryFilters {
  const DiscoveryFilters({this.specialty, this.city, this.searchQuery});

  final String? specialty;
  final String? city;
  final String? searchQuery;

  bool get isEmpty =>
      specialty == null &&
      city == null &&
      (searchQuery == null || searchQuery!.trim().isEmpty);
}

/// Cursor for a discovery page. The fields mirror the server-side ordering
/// tuple for the active collection, so a newly changed profile cannot shift
/// the next page underneath a homeowner who is scrolling.
class DiscoveryCursor {
  const DiscoveryCursor({
    required this.id,
    required this.fullName,
    this.matchRank,
    this.rating,
    this.ratingCount,
  });

  final String id;
  final String fullName;
  final int? matchRank;
  final double? rating;
  final int? ratingCount;
}

class DiscoveryPage {
  const DiscoveryPage({
    required this.items,
    required this.cursor,
    required this.requestedLimit,
  });

  final List<ContractorListing> items;
  final DiscoveryCursor? cursor;
  final int requestedLimit;

  bool get hasMore => items.length == requestedLimit;
}

class DiscoveryRepository {
  DiscoveryRepository(this._client);
  final SupabaseClient _client;

  /// Feed page size. Bounds every fetch so the client never pulls the whole
  /// contractor table — the difference between "scales to millions" and OOM.
  static const int pageSize = 20;

  Future<DiscoveryPage> fetchContractorsPage(
    DiscoveryFilters filters, {
    int limit = pageSize,
    DiscoveryCursor? after,
  }) async {
    final boundedLimit = limit.clamp(1, 50).toInt();
    final search = filters.searchQuery?.trim() ?? '';
    final rows = await _client
        .rpc(
          search.isNotEmpty
              ? 'discover_contractors_cursor'
              : 'list_contractors_cursor',
          params: search.isNotEmpty
              ? {
                  'p_query': search,
                  'p_specialty': filters.specialty,
                  'p_city': filters.city,
                  'p_limit': boundedLimit,
                  'p_after_rank': after?.matchRank,
                  'p_after_name': after?.fullName,
                  'p_after_id': after?.id,
                }
              : {
                  'p_specialty': filters.specialty,
                  'p_city': filters.city,
                  'p_limit': boundedLimit,
                  'p_sort': 'name',
                  'p_after_name': after?.fullName,
                  'p_after_id': after?.id,
                },
        )
        .timeout(const Duration(seconds: 15));
    final rawRows = (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final results = rawRows
        .map(ContractorListing.fromJoined)
        .toList(growable: false);

    // First page only, so this counts searches rather than scroll depth. The
    // query text is intentionally never sent to analytics.
    if (search.isNotEmpty && after == null) {
      unawaited(
        AppAnalytics.track(
          'contractor_search',
          properties: {
            'result_count': results.length,
            'zero_results': results.isEmpty,
            'has_specialty_filter': filters.specialty != null,
            'has_city_filter': filters.city != null,
          },
        ),
      );
    }

    return DiscoveryPage(
      items: results,
      cursor: rawRows.isEmpty ? null : _cursorFromRow(rawRows.last),
      requestedLimit: boundedLimit,
    );
  }

  /// Returns only professionals with at least one real review, ordered by
  /// the same signals homeowners see on the rating shelf. The ordering stays
  /// in PostgREST so pagination does not reshuffle between pages.
  Future<DiscoveryPage> fetchTopRatedPage({
    int limit = pageSize,
    DiscoveryCursor? after,
  }) async {
    final boundedLimit = limit.clamp(1, 50).toInt();
    final rows = await _client
        .rpc(
          'list_contractors_cursor',
          params: {
            'p_limit': boundedLimit,
            'p_sort': 'rating',
            'p_only_reviewed': true,
            'p_after_name': after?.fullName,
            'p_after_id': after?.id,
            'p_after_rating': after?.rating,
            'p_after_rating_count': after?.ratingCount,
          },
        )
        .timeout(const Duration(seconds: 15));
    final rawRows = (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    return DiscoveryPage(
      items: rawRows.map(ContractorListing.fromJoined).toList(growable: false),
      cursor: rawRows.isEmpty ? null : _cursorFromRow(rawRows.last),
      requestedLimit: boundedLimit,
    );
  }

  /// Loads the separately disclosed paid-placement shelf. Sponsored
  /// placement is intentionally not folded into the factual top-rated sort.
  Future<List<ContractorListing>> fetchSponsoredProfessionals({
    String? specialty,
    String? city,
  }) async {
    final rows = await _client
        .rpc(
          'list_sponsored_contractors',
          params: {'p_specialty': specialty, 'p_city': city, 'p_limit': 6},
        )
        .timeout(const Duration(seconds: 12));
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map(
          (row) => ContractorListing.fromJoined(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  DiscoveryCursor _cursorFromRow(Map<String, dynamic> row) {
    final raw = row['contractor_profiles'];
    final profile = (raw is List ? raw.firstOrNull : raw) as Map?;
    return DiscoveryCursor(
      id: row['id'] as String,
      fullName: (row['full_name'] as String?) ?? '',
      matchRank: (row['match_rank'] as num?)?.toInt(),
      // The server sorts missing ratings as -1. Preserve that sentinel in the
      // cursor or the next top-rated page would treat a null rating as a first
      // page and repeat the collection.
      rating: (profile?['rating_avg'] as num?)?.toDouble() ?? -1,
      ratingCount: (profile?['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<ContractorListing?> fetchContractor(String id) async {
    final rows = await _client
        // The cursor projection is public-safe and works for guests. The old
        // offset RPC is kept for released clients, but is authenticated-only
        // and must not be the profile detail path.
        .rpc(
          'list_contractors_cursor',
          params: {'p_limit': 1, 'p_contractor_id': id},
        )
        .timeout(const Duration(seconds: 15));
    if (rows is! List || rows.isEmpty) return null;
    final listing = ContractorListing.fromJoined(
      rows.first as Map<String, dynamic>,
    );

    // Contact details are intentionally a detail-level concern. The public
    // catalogue projection excludes phone; this narrow lookup only runs after
    // the user opens a professional profile and has a session. Guests can
    // still inspect the public profile without triggering an expected 401.
    if (_client.auth.currentSession == null) return listing;

    final contact = await _client
        .rpc('get_contractor_contact', params: {'p_contractor_id': id})
        .timeout(const Duration(seconds: 10));
    final phone = contact is List && contact.isNotEmpty
        ? (contact.first as Map<String, dynamic>)['phone'] as String?
        : null;
    return listing.copyWith(phone: phone ?? '');
  }
}

@Riverpod(keepAlive: true)
DiscoveryRepository discoveryRepository(Ref ref) =>
    DiscoveryRepository(ref.watch(supabaseClientProvider));
