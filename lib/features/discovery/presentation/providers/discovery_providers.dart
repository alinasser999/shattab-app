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
class DiscoverContractors extends _$DiscoverContractors {
  bool _hasMore = true;
  bool _loadingMore = false;

  /// Whether more pages may remain — false once a short (< pageSize) page lands.
  bool get hasMore => _hasMore;

  @override
  Future<List<ContractorListing>> build() async {
    final filters = ref.watch(discoveryFiltersControllerProvider);
    _loadingMore = false;
    final page = await ref
        .read(discoveryRepositoryProvider)
        .fetchContractors(filters);
    _hasMore = page.length == DiscoveryRepository.pageSize;
    return page;
  }

  /// Fetch the next page and append. No-op while in flight or exhausted, so
  /// scroll spam near the list end can't fire duplicate fetches.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;
    _loadingMore = true;
    try {
      final filters = ref.read(discoveryFiltersControllerProvider);
      final next = await ref
          .read(discoveryRepositoryProvider)
          .fetchContractors(filters, offset: current.length);
      _hasMore = next.length == DiscoveryRepository.pageSize;
      state = AsyncData([...current, ...next]);
    } finally {
      _loadingMore = false;
    }
  }
}

@riverpod
Future<ContractorListing?> contractorById(Ref ref, String id) {
  return ref.watch(discoveryRepositoryProvider).fetchContractor(id);
}
