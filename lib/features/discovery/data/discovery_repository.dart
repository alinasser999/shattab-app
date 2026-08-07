import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class DiscoveryRepository {
  DiscoveryRepository(this._client);
  final SupabaseClient _client;

  /// Feed page size. Bounds every fetch so the client never pulls the whole
  /// contractor table — the difference between "scales to millions" and OOM.
  static const int pageSize = 20;

  // rating_avg/rating_count are denormalized on contractor_profiles by the
  // reviews_rollup trigger — reads two ints instead of embedding every review
  // row per card (fanout death at scale).
  static const String _joinedColumns =
      'id, full_name, phone, contractor_profiles!inner(business_name, bio, logo_url, cover_photo_url, headline, specialties, service_areas, years_experience, projects_completed, response_rate, rating_avg, rating_count, verified, plan, provider_kind, created_at)';

  Future<List<ContractorListing>> fetchContractors(
    DiscoveryFilters filters, {
    int offset = 0,
    int limit = pageSize,
  }) async {
    final search = filters.searchQuery?.trim() ?? '';
    if (search.isNotEmpty) {
      // Search runs through the `discover_contractors` RPC rather than
      // PostgREST, because two things it needs cannot be expressed here: an OR
      // across a base column (`full_name`) and an embedded one
      // (`business_name`), which the PostgREST parser rejects; and Arabic
      // folding, so `احمد` finds `أحمد` and `فاطمه` finds `فاطمة`.
      //
      // The RPC returns rows in the same shape as the embed below, so
      // `fromJoined` parses either path without knowing which one ran.
      final rows = await _client.rpc(
        'discover_contractors',
        params: {
          'p_query': search,
          'p_specialty': filters.specialty,
          'p_city': filters.city,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return (rows as List)
          .map(
            (row) => ContractorListing.fromJoined(row as Map<String, dynamic>),
          )
          .toList();
    }

    var query = _client
        .from('profiles')
        .select(_joinedColumns)
        .eq('role', 'contractor');

    if (filters.specialty != null) {
      query = query.contains('contractor_profiles.specialties', [
        filters.specialty,
      ]);
    }
    if (filters.city != null) {
      query = query.contains('contractor_profiles.service_areas', [
        filters.city,
      ]);
    }

    // `.range` bounds the result to one page — without it this fetches every
    // contractor row (+ embedded reviews) and OOMs the client at scale.
    final rows = await query
        .order('full_name')
        .range(offset, offset + limit - 1);
    return rows.map(ContractorListing.fromJoined).toList();
  }

  /// Returns only professionals with at least one real review, ordered by
  /// the same signals homeowners see on the rating shelf. The ordering stays
  /// in PostgREST so pagination does not reshuffle between pages.
  Future<List<ContractorListing>> fetchTopRated({
    int offset = 0,
    int limit = pageSize,
  }) async {
    final rows = await _client
        .from('profiles')
        .select(_joinedColumns)
        .eq('role', 'contractor')
        .gt('contractor_profiles.rating_count', 0)
        .order(
          'rating_avg',
          referencedTable: 'contractor_profiles',
          ascending: false,
        )
        .order(
          'rating_count',
          referencedTable: 'contractor_profiles',
          ascending: false,
        )
        .order('full_name', ascending: true)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
    return rows.map(ContractorListing.fromJoined).toList();
  }

  Future<ContractorListing?> fetchContractor(String id) async {
    final row = await _client
        .from('profiles')
        .select(_joinedColumns)
        .eq('id', id)
        .eq('role', 'contractor')
        .maybeSingle();
    if (row == null) return null;
    return ContractorListing.fromJoined(row);
  }
}

@Riverpod(keepAlive: true)
DiscoveryRepository discoveryRepository(Ref ref) =>
    DiscoveryRepository(ref.watch(supabaseClientProvider));
