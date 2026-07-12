import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../domain/contractor_listing.dart';

part 'discovery_repository.g.dart';

class DiscoveryFilters {
  const DiscoveryFilters({
    this.specialty,
    this.city,
    this.searchQuery,
  });

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

  // `reviews!reviews_contractor_id_fkey` disambiguates the embed — reviews has
  // two FKs to profiles (contractor_id + homeowner_id), so the contractor one
  // must be named explicitly.
  static const String _joinedColumns =
      'id, full_name, phone, contractor_profiles!inner(business_name, bio, logo_url, cover_photo_url, headline, specialties, service_areas, years_experience, projects_completed, response_rate), reviews!reviews_contractor_id_fkey(rating)';

  Future<List<ContractorListing>> fetchContractors(
      DiscoveryFilters filters) async {
    var query =
        _client.from('profiles').select(_joinedColumns).eq('role', 'contractor');

    if (filters.specialty != null) {
      query = query.contains(
          'contractor_profiles.specialties', [filters.specialty]);
    }
    if (filters.city != null) {
      query = query.contains(
          'contractor_profiles.service_areas', [filters.city]);
    }
    if (filters.searchQuery != null && filters.searchQuery!.trim().isNotEmpty) {
      final q = filters.searchQuery!.trim();
      query = query.or(
          'full_name.ilike.%$q%,contractor_profiles.business_name.ilike.%$q%');
    }

    final rows = await query.order('full_name');
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
