import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/portfolio_repository.dart';
import '../../domain/portfolio_project.dart';

part 'portfolio_providers.g.dart';

@riverpod
Future<List<PortfolioProject>> portfolioForContractor(
  Ref ref,
  String contractorId,
) => ref.watch(portfolioRepositoryProvider).fetchForContractor(contractorId);

@riverpod
Future<PortfolioProject?> portfolioProject(Ref ref, String projectId) =>
    ref.watch(portfolioRepositoryProvider).fetchById(projectId);

/// Complete-work collection for homeowners. The discover rail stays a small
/// editorial sample; this provider owns the paginated "عرض الكل" experience.
@riverpod
class RecentWorkCollection extends _$RecentWorkCollection {
  static const pageSize = 12;

  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<PortfolioProject>> build() async {
    _hasMore = true;
    _loadingMore = false;
    final page = await ref
        .read(portfolioRepositoryProvider)
        .fetchRecentPage(limit: pageSize);
    _hasMore = page.length == pageSize;
    return page;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(portfolioRepositoryProvider)
          .fetchRecentPage(offset: current.length, limit: pageSize);
      _hasMore = next.length == pageSize;
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
