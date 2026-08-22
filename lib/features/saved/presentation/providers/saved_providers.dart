import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/analytics/app_analytics.dart';
import '../../../discovery/domain/contractor_listing.dart';
import '../../data/saved_repository.dart';

part 'saved_providers.g.dart';

@riverpod
Future<Set<String>> savedContractorIds(Ref ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return <String>{};
  return ref.watch(savedRepositoryProvider).fetchSavedIds(session.user.id);
}

@riverpod
class SavedContractors extends _$SavedContractors {
  static const pageSize = SavedRepository.pageSize;

  SavedCursor? _cursor;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get isLoadingMore => _loadingMore;

  @override
  Future<SavedContractorsState> build() async {
    _cursor = null;
    _hasMore = true;
    _loadingMore = false;
    final session = ref.watch(currentSessionProvider);
    if (session == null) return const SavedContractorsState();

    final page = await ref
        .read(savedRepositoryProvider)
        .fetchSavedPage(session.user.id, limit: pageSize);
    _cursor = page.cursor;
    _hasMore = page.hasMore;
    return SavedContractorsState(items: page.items, hasMore: _hasMore);
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    final session = ref.read(currentSessionProvider);
    if (current == null || session == null) return;

    _loadingMore = true;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    try {
      final page = await ref
          .read(savedRepositoryProvider)
          .fetchSavedPage(session.user.id, after: _cursor, limit: pageSize);
      final ids = current.items.map((item) => item.id).toSet();
      final nextItems = page.items.where((item) => ids.add(item.id));
      _cursor = page.cursor;
      _hasMore = page.hasMore;
      if (ref.mounted) {
        state = AsyncData(
          SavedContractorsState(
            items: [...current.items, ...nextItems],
            hasMore: _hasMore,
          ),
        );
      }
    } catch (error) {
      if (ref.mounted) {
        state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreError: error),
        );
      }
    } finally {
      _loadingMore = false;
    }
  }
}

class SavedContractorsState {
  const SavedContractorsState({
    this.items = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<ContractorListing> items;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? loadMoreError;

  SavedContractorsState copyWith({
    List<ContractorListing>? items,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) => SavedContractorsState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreError: clearLoadMoreError
        ? null
        : loadMoreError ?? this.loadMoreError,
  );
}

// keepAlive: called one-shot via ref.read(...notifier); autoDispose would
// tear the controller down mid-await and its next ref use would throw.
@Riverpod(keepAlive: true)
class SavedController extends _$SavedController {
  @override
  void build() {}

  Future<void> toggle(String contractorId) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) return;
    final ids = await ref.read(savedContractorIdsProvider.future);
    final repo = ref.read(savedRepositoryProvider);
    final shouldSave = !ids.contains(contractorId);
    if (!shouldSave) {
      await repo.unsave(
        homeownerId: session.user.id,
        contractorId: contractorId,
      );
    } else {
      await repo.save(homeownerId: session.user.id, contractorId: contractorId);
    }
    unawaited(
      AppAnalytics.track(
        'professional_saved',
        properties: {'saved': shouldSave},
      ),
    );
    if (ref.mounted) {
      ref.invalidate(savedContractorIdsProvider);
      ref.invalidate(savedContractorsProvider);
    }
  }
}
