import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/models/draft_photo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../data/briefs_repository.dart';
import '../../domain/brief.dart';
import '../../domain/homeowner_profile_preview.dart';
import '../../domain/opportunity_experience.dart';
import 'opportunity_experience_provider.dart';

part 'briefs_providers.g.dart';

@riverpod
Future<List<Brief>> myBriefs(Ref ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return const [];
  return ref.watch(briefsRepositoryProvider).fetchMine(session.user.id);
}

@riverpod
Future<Brief?> briefById(Ref ref, String id) =>
    ref.watch(briefsRepositoryProvider).fetchById(id);

@riverpod
Future<PublicHomeownerProfile?> homeownerProfilePreview(
  Ref ref,
  String homeownerId,
) async {
  return ref
      .read(briefsRepositoryProvider)
      .fetchHomeownerPublicProfile(homeownerId);
}

/// Debounced search text for the opportunities feed. Held in a provider rather
/// than screen state so the query is part of the fetch, not a filter applied to
/// whatever page happens to be loaded.
@riverpod
class OpportunitySearch extends _$OpportunitySearch {
  @override
  String build() => '';

  void setQuery(String query) {
    final next = query.trim();
    if (next != state) state = next;
  }

  void clear() => setQuery('');
}

/// Paginated opportunities feed. Search and paging both run server-side; the
/// previous version fetched every matching open brief in one unbounded query
/// and filtered on the client.
@riverpod
class ContractorOpportunities extends _$ContractorOpportunities {
  bool _hasMore = true;
  bool _loadingMore = false;
  DateTime? _createdAfter;

  /// Whether more pages may remain — false once a short page lands.
  bool get hasMore => _hasMore;

  @override
  Future<List<Brief>> build() async {
    final query = ref.watch(opportunitySearchProvider);
    ref.watch(
      opportunityFiltersProvider.select((filters) => filters.serverQueryKey),
    );
    final filters = ref.read(opportunityFiltersProvider);
    _createdAfter = filters.serverCreatedAfter();
    ref.read(opportunityPaginationProvider.notifier).complete();
    _loadingMore = false;
    final page = await ref
        .read(briefsRepositoryProvider)
        .fetchOpportunitiesForContractor(
          searchQuery: query,
          city: filters.city,
          targetSpecialties: filters.specialties,
          createdAfter: _createdAfter,
        );
    _hasMore = page.length == BriefsRepository.pageSize;
    return page;
  }

  /// Fetch the next page and append. No-op while in flight or exhausted, so
  /// scroll spam near the list end can't fire duplicate requests.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null || current.isEmpty) return;
    _loadingMore = true;
    ref.read(opportunityPaginationProvider.notifier).begin();
    var failed = false;
    try {
      final filters = ref.read(opportunityFiltersProvider);
      final next = await ref
          .read(briefsRepositoryProvider)
          .fetchOpportunitiesForContractor(
            searchQuery: ref.read(opportunitySearchProvider),
            after: BriefCursor.fromBrief(current.last),
            city: filters.city,
            targetSpecialties: filters.specialties,
            createdAfter: _createdAfter,
          );
      _hasMore = next.length == BriefsRepository.pageSize;
      final merged = mergeUniqueOpportunityPages(current, next);
      if (merged.length != current.length) state = AsyncData(merged);
      if (next.isNotEmpty && merged.length == current.length) {
        _hasMore = false;
      }
    } catch (error) {
      failed = true;
      ref.read(opportunityPaginationProvider.notifier).fail(error);
    } finally {
      _loadingMore = false;
      if (!failed) ref.read(opportunityPaginationProvider.notifier).complete();
    }
  }
}

@riverpod
Future<List<Brief>> contractorDirectBriefs(Ref ref) =>
    ref.watch(briefsRepositoryProvider).fetchDirectBriefsForContractor();

// keepAlive: called one-shot via ref.read(...notifier); autoDispose would
// tear the controller down mid-await and its next ref use would throw.
@Riverpod(keepAlive: true)
class BriefsController extends _$BriefsController {
  bool _creating = false;

  @override
  void build() {}

  Future<Brief> createDirectRequest({
    required String contractorId,
    required ApartmentType apartmentType,
    required String city,
    String? district,
    required String workDescription,
    required List<DraftPhoto> photos,
  }) async {
    if (_creating) throw StateError('brief_creation_in_progress');
    _creating = true;
    try {
      return await _create(
        targetContractorId: contractorId,
        apartmentType: apartmentType,
        city: city,
        district: district,
        workDescription: workDescription,
        photos: photos,
        targetSpecialties: const [],
      );
    } finally {
      _creating = false;
    }
  }

  Future<Brief> createPost({
    required ApartmentType apartmentType,
    required String city,
    String? district,
    required String workDescription,
    required List<String> targetSpecialties,
    required List<DraftPhoto> photos,
  }) async {
    if (_creating) throw StateError('brief_creation_in_progress');
    _creating = true;
    try {
      return await _create(
        targetContractorId: null,
        apartmentType: apartmentType,
        city: city,
        district: district,
        workDescription: workDescription,
        photos: photos,
        targetSpecialties: targetSpecialties,
      );
    } finally {
      _creating = false;
    }
  }

  Future<Brief> _create({
    required String? targetContractorId,
    required ApartmentType apartmentType,
    required String city,
    required String? district,
    required String workDescription,
    required List<DraftPhoto> photos,
    required List<String> targetSpecialties,
  }) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      throw StateError('No session — cannot create brief.');
    }
    final repo = ref.read(briefsRepositoryProvider);

    // Create brief with empty photos first to get an ID for the storage path.
    final brief = await repo.createBrief(
      homeownerId: session.user.id,
      targetContractorId: targetContractorId,
      apartmentType: apartmentType,
      city: city,
      district: district,
      workDescription: workDescription,
      photoUrls: const [],
      targetSpecialties: targetSpecialties,
    );

    if (photos.isNotEmpty) {
      try {
        // Upload in parallel — five sequential round-trips dominated brief
        // creation latency on mobile data.
        final urls = await Future.wait(<Future<String>>[
          for (var i = 0; i < photos.length; i++)
            repo.uploadPhoto(
              homeownerId: session.user.id,
              draftId: brief.id,
              seq: i,
              file: photos[i].file,
              bytes: photos[i].bytes,
            ),
        ]);
        await repo.setPhotoUrls(brief.id, urls);
      } catch (e) {
        // Compensate: a brief left open with none of its photos reads as
        // spam to every matched contractor. This brief is seconds old and
        // quote-less, so delete-or-cancel resolves to a hard delete; if the
        // network is gone entirely the brief remains visible and deletable
        // from My Requests rather than being lost.
        try {
          await repo.deleteOrCancelBrief(brief.id);
        } catch (_) {
          // Secondary failure — surface the primary upload error.
        }
        rethrow;
      }
    }

    ref.invalidate(myBriefsProvider);
    return brief;
  }

  /// Homeowner: change a brief's scope. Photos are handled separately by
  /// [BriefsRepository.setPhotoUrls], as on create.
  Future<void> updateBrief(
    String briefId, {
    required ApartmentType apartmentType,
    required String city,
    String? district,
    required String workDescription,
    required List<String> targetSpecialties,
  }) async {
    await ref
        .read(briefsRepositoryProvider)
        .updateBrief(
          briefId,
          apartmentType: apartmentType,
          city: city,
          district: district,
          workDescription: workDescription,
          targetSpecialties: targetSpecialties,
        );
    ref.invalidate(briefByIdProvider(briefId));
    ref.invalidate(myBriefsProvider);
  }

  /// Homeowner: remove a brief. Returns `'deleted'` when it was actually
  /// removed, or `'cancelled'` when contractors had already quoted and the
  /// brief was kept so their work survives.
  Future<String> deleteOrCancelBrief(String briefId) async {
    final outcome = await ref
        .read(briefsRepositoryProvider)
        .deleteOrCancelBrief(briefId);
    ref.invalidate(myBriefsProvider);
    ref.invalidate(briefByIdProvider(briefId));
    return outcome;
  }

  /// Contractor: signal the hired work is finished (migration 0019).
  Future<void> requestCompletion(String briefId) async {
    await ref.read(briefsRepositoryProvider).requestCompletion(briefId);
    ref.invalidate(briefByIdProvider(briefId));
  }

  /// Homeowner: confirm the work is done. Unlocks reviews and increments the
  /// contractor's projects_completed, so the brief list is invalidated too.
  Future<void> confirmCompletion(String briefId) async {
    await ref.read(briefsRepositoryProvider).confirmCompletion(briefId);
    ref.invalidate(briefByIdProvider(briefId));
    ref.invalidate(myBriefsProvider);
  }

  Future<void> cancel(String briefId) async {
    await ref.read(briefsRepositoryProvider).cancelBrief(briefId);
    ref.invalidate(myBriefsProvider);
    ref.invalidate(briefByIdProvider(briefId));
  }
}
