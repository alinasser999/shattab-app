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
    if (filters.searchQuery != null && filters.searchQuery!.trim().isNotEmpty) {
      final q = filters.searchQuery!.trim();
      // PostgREST can't OR a base column against an embedded one in a single
      // request (parser rejects the embedded ref) — that 400 is what hung the
      // search spinner. Match the business name (the card title users type).
      // ponytail: business_name only; full_name search lands with the Phase-2
      // discover_contractors RPC (trigram, both fields server-side).
      query = query.ilike('contractor_profiles.business_name', '%$q%');
    }

    // `.range` bounds the result to one page — without it this fetches every
    // contractor row (+ embedded reviews) and OOMs the client at scale.
    final rows = await query
        .order('full_name')
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
