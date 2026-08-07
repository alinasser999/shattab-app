import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/discovery_repository.dart';
import '../../domain/contractor_listing.dart';

part 'discovery_providers.g.dart';

Duration? discoveryRetry(int retryCount, Object error) =>
    retryCount >= 2 ? null : Duration(milliseconds: 300 * (retryCount + 1));

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

@Riverpod(retry: discoveryRetry)
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

/// Full ranked collection used by the dedicated "top rated" page. This is
/// intentionally separate from [DiscoverContractors]: the discover landing
/// page is curated, while this page must be able to walk the complete rated
/// catalogue without being limited to the first landing-page batch.
@riverpod
class TopRatedProfessionals extends _$TopRatedProfessionals {
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<ContractorListing>> build() async {
    _hasMore = true;
    _loadingMore = false;
    final page = await ref.read(discoveryRepositoryProvider).fetchTopRated();
    _hasMore = page.length == DiscoveryRepository.pageSize;
    return page;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(discoveryRepositoryProvider)
          .fetchTopRated(offset: current.length);
      _hasMore = next.length == DiscoveryRepository.pageSize;
      final ids = current.map((item) => item.id).toSet();
      state = AsyncData([
        ...current,
        ...next.where((item) => ids.add(item.id)),
      ]);
    } finally {
      _loadingMore = false;
    }
  }
}

/// Unfiltered catalogue for the explicit "all professionals" collection.
@riverpod
class AllProfessionals extends _$AllProfessionals {
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<ContractorListing>> build() async {
    _hasMore = true;
    _loadingMore = false;
    final page = await ref
        .read(discoveryRepositoryProvider)
        .fetchContractors(const DiscoveryFilters());
    _hasMore = page.length == DiscoveryRepository.pageSize;
    return page;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(discoveryRepositoryProvider)
          .fetchContractors(const DiscoveryFilters(), offset: current.length);
      _hasMore = next.length == DiscoveryRepository.pageSize;
      final ids = current.map((item) => item.id).toSet();
      state = AsyncData([
        ...current,
        ...next.where((item) => ids.add(item.id)),
      ]);
    } finally {
      _loadingMore = false;
    }
  }
}

/// City-scoped collection used by the nearby shelf's dedicated page.
@riverpod
class NearbyProfessionals extends _$NearbyProfessionals {
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<ContractorListing>> build(String city) async {
    _hasMore = true;
    _loadingMore = false;
    final page = await ref
        .read(discoveryRepositoryProvider)
        .fetchContractors(DiscoveryFilters(city: city));
    _hasMore = page.length == DiscoveryRepository.pageSize;
    return page;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(discoveryRepositoryProvider)
          .fetchContractors(
            DiscoveryFilters(city: city),
            offset: current.length,
          );
      _hasMore = next.length == DiscoveryRepository.pageSize;
      final ids = current.map((item) => item.id).toSet();
      state = AsyncData([
        ...current,
        ...next.where((item) => ids.add(item.id)),
      ]);
    } finally {
      _loadingMore = false;
    }
  }
}

@Riverpod(retry: discoveryRetry)
Future<ContractorListing?> contractorById(Ref ref, String id) {
  return ref.watch(discoveryRepositoryProvider).fetchContractor(id);
}
