import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/discovery_repository.dart';
import '../../domain/contractor_listing.dart';

part 'discovery_providers.g.dart';

@riverpod
class DiscoveryFiltersController extends _$DiscoveryFiltersController {
  @override
  DiscoveryFilters build() => const DiscoveryFilters();

  void setSpecialty(String? specialty) {
    state = DiscoveryFilters(
      specialty: specialty,
      city: state.city,
      searchQuery: state.searchQuery,
    );
  }

  void setCity(String? city) {
    state = DiscoveryFilters(
      specialty: state.specialty,
      city: city,
      searchQuery: state.searchQuery,
    );
  }

  void setSearch(String? q) {
    state = DiscoveryFilters(
      specialty: state.specialty,
      city: state.city,
      searchQuery: q,
    );
  }

  void clear() => state = const DiscoveryFilters();
}

@riverpod
Future<List<ContractorListing>> discoverContractors(Ref ref) {
  final filters = ref.watch(discoveryFiltersControllerProvider);
  return ref.watch(discoveryRepositoryProvider).fetchContractors(filters);
}

@riverpod
Future<ContractorListing?> contractorById(Ref ref, String id) {
  return ref.watch(discoveryRepositoryProvider).fetchContractor(id);
}
