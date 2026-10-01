import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/provider_cache.dart';
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
      sort: state.sort,
      minimumRating: state.minimumRating,
    );
  }

  void setCity(String? city) {
    state = DiscoveryFilters(
      specialty: state.specialty,
      city: city,
      searchQuery: state.searchQuery,
      sort: state.sort,
      minimumRating: state.minimumRating,
    );
  }

  void setSearch(String? q) {
    final normalized = q?.trim();
    state = DiscoveryFilters(
      specialty: state.specialty,
      city: state.city,
      searchQuery: normalized == null || normalized.isEmpty ? null : normalized,
      // The search RPC orders by match rank/name/id. Resetting the catalogue
      // sort makes that precedence explicit and prevents a stale "top rated"
      // label from describing a relevance-ordered result set.
      sort: normalized == null || normalized.isEmpty
          ? state.sort
          : DiscoverySort.name,
      minimumRating: state.minimumRating,
    );
  }

  void setSort(DiscoverySort sort) {
    if (sort == state.sort) return;
    state = DiscoveryFilters(
      specialty: state.specialty,
      city: state.city,
      searchQuery: state.searchQuery,
      sort: sort,
      minimumRating: state.minimumRating,
    );
  }

  void setMinimumRating(double? rating) {
    state = DiscoveryFilters(
      specialty: state.specialty,
      city: state.city,
      searchQuery: state.searchQuery,
      sort: state.sort,
      minimumRating: rating,
    );
  }

  void clear() => state = const DiscoveryFilters();
}

/// Paid placements are loaded independently so a slow sponsored query never
/// blocks the organic catalogue or its skeleton state.
@riverpod
Future<List<ContractorListing>> sponsoredProfessionals(
  Ref ref,
  String? specialty,
  String? city,
) {
  return ref
      .watch(discoveryRepositoryProvider)
      .fetchSponsoredProfessionals(specialty: specialty, city: city);
}

@Riverpod(retry: discoveryRetry)
class DiscoverContractors extends _$DiscoverContractors {
  bool _hasMore = true;
  bool _loadingMore = false;
  DiscoveryCursor? _cursor;
  int _filterGeneration = 0;
  int _requestSequence = 0;
  int _activeRequest = 0;

  /// Whether more pages may remain — false once a short (< pageSize) page lands.
  bool get hasMore => _hasMore;

  @override
  Future<List<ContractorListing>> build() async {
    final filters = ref.watch(discoveryFiltersControllerProvider);
    final generation = ++_filterGeneration;
    _loadingMore = false;
    _activeRequest = ++_requestSequence;
    _cursor = null;
    _hasMore = true;
    final page = await ref
        .read(discoveryRepositoryProvider)
        .fetchContractorsPage(filters);
    if (generation != _filterGeneration) return const [];
    _cursor = page.cursor;
    _hasMore = page.hasMore;
    return page.items;
  }

  /// Fetch the next page and append. No-op while in flight or exhausted, so
  /// scroll spam near the list end can't fire duplicate fetches.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;
    final generation = _filterGeneration;
    final filters = ref.read(discoveryFiltersControllerProvider);
    final request = ++_requestSequence;
    _activeRequest = request;
    _loadingMore = true;
    try {
      final page = await ref
          .read(discoveryRepositoryProvider)
          .fetchContractorsPage(filters, after: _cursor);
      final currentFilters = ref.read(discoveryFiltersControllerProvider);
      if (generation != _filterGeneration ||
          filters != currentFilters ||
          request != _activeRequest) {
        return;
      }
      _cursor = page.cursor;
      _hasMore = page.hasMore;
      final ids = current.map((item) => item.id).toSet();
      state = AsyncData([
        ...current,
        ...page.items.where((item) => ids.add(item.id)),
      ]);
    } finally {
      if (request == _activeRequest) _loadingMore = false;
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
  DiscoveryCursor? _cursor;

  bool get hasMore => _hasMore;

  @override
  Future<List<ContractorListing>> build() async {
    _hasMore = true;
    _loadingMore = false;
    final page = await ref
        .read(discoveryRepositoryProvider)
        .fetchTopRatedPage();
    _cursor = page.cursor;
    _hasMore = page.hasMore;
    return page.items;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;
    _loadingMore = true;
    try {
      final page = await ref
          .read(discoveryRepositoryProvider)
          .fetchTopRatedPage(after: _cursor);
      _cursor = page.cursor;
      _hasMore = page.hasMore;
      final ids = current.map((item) => item.id).toSet();
      state = AsyncData([
        ...current,
        ...page.items.where((item) => ids.add(item.id)),
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
  DiscoveryCursor? _cursor;

  bool get hasMore => _hasMore;

  @override
  Future<List<ContractorListing>> build() async {
    _hasMore = true;
    _loadingMore = false;
    final page = await ref
        .read(discoveryRepositoryProvider)
        .fetchContractorsPage(const DiscoveryFilters());
    _cursor = page.cursor;
    _hasMore = page.hasMore;
    return page.items;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;
    _loadingMore = true;
    try {
      final page = await ref
          .read(discoveryRepositoryProvider)
          .fetchContractorsPage(const DiscoveryFilters(), after: _cursor);
      _cursor = page.cursor;
      _hasMore = page.hasMore;
      final ids = current.map((item) => item.id).toSet();
      state = AsyncData([
        ...current,
        ...page.items.where((item) => ids.add(item.id)),
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
  DiscoveryCursor? _cursor;

  bool get hasMore => _hasMore;

  @override
  Future<List<ContractorListing>> build(String city) async {
    _hasMore = true;
    _loadingMore = false;
    final page = await ref
        .read(discoveryRepositoryProvider)
        .fetchContractorsPage(DiscoveryFilters(city: city));
    _cursor = page.cursor;
    _hasMore = page.hasMore;
    return page.items;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;
    _loadingMore = true;
    try {
      final page = await ref
          .read(discoveryRepositoryProvider)
          .fetchContractorsPage(DiscoveryFilters(city: city), after: _cursor);
      _cursor = page.cursor;
      _hasMore = page.hasMore;
      final ids = current.map((item) => item.id).toSet();
      state = AsyncData([
        ...current,
        ...page.items.where((item) => ids.add(item.id)),
      ]);
    } finally {
      _loadingMore = false;
    }
  }
}

/// One professional, by id.
///
/// Held briefly after the last listener. This is the provider a homeowner
/// re-enters most: open a profile, back to the catalogue, open the next,
/// return to the first. Without a window every one of those returns showed a
/// skeleton for a record already on the device.
///
/// `ReviewController.submit` invalidates this to refresh the aggregate rating,
/// which disposes the provider and cancels the window with it.
@Riverpod(retry: discoveryRetry)
Future<ContractorListing?> contractorById(Ref ref, String id) async {
  final listing = await ref
      .watch(discoveryRepositoryProvider)
      .fetchContractor(id);
  cacheFor(ref, cacheWindow);
  return listing;
}
