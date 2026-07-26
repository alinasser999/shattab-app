import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/post_repository.dart';
import '../../domain/post.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'explore_providers.g.dart';

@riverpod
class ExploreFeed extends _$ExploreFeed {
  static const _pageSize = 10;
  bool _loading = false;
  bool _hasMore = true;

  /// Whether another page might exist — drives the trailing loader.
  bool get hasMore => _hasMore;

  @override
  AsyncValue<List<Post>> build() {
    _fetchPage();
    return const AsyncLoading();
  }

  /// Keyset pagination (migration 0017): [cursor] is the last post already
  /// loaded; null fetches the first page. Deterministic — no offset drift.
  Future<void> _fetchPage({Post? cursor}) async {
    try {
      final userId = ref.read(currentSessionProvider)?.user.id ?? '';
      final repo = ref.read(postRepositoryProvider);
      final posts = await repo.fetchFeed(
        userId: userId,
        limit: _pageSize,
        beforeCreatedAt: cursor?.createdAt,
        beforeId: cursor?.id,
      );
      _hasMore = posts.length == _pageSize;
      state = AsyncData(cursor == null ? posts : [...?state.value, ...posts]);
    } catch (e, st) {
      // Only surface a fresh-load failure. A page>0 failure keeps the list
      // the user already has so a flaky scroll doesn't wipe the feed.
      if (cursor == null) state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    _hasMore = true;
    state = const AsyncLoading();
    await _fetchPage();
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    final current = state.value;
    if (current == null || current.isEmpty) return;
    _loading = true;
    await _fetchPage(cursor: current.last);
    _loading = false;
  }

  /// Replaces one post in-place (optimistic like/save) without refetching —
  /// keeps scroll position and loaded pages intact.
  void patchPost(Post updated) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final p in current) p.id == updated.id ? updated : p,
    ]);
  }
}

// keepAlive: called one-shot via ref.read(...notifier); autoDispose would
// tear the controller down mid-await and its next ref use would throw.
@Riverpod(keepAlive: true)
class PostController extends _$PostController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createPost({
    required String authorId,
    required String authorRole,
    required String postType,
    required String caption,
    List<String> mediaUrls = const [],
    String? category,
    String? governorate,
    String? city,
    String? portfolioProjectId,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(postRepositoryProvider);
      await repo.create(
        authorId: authorId,
        authorRole: authorRole,
        postType: postType,
        caption: caption,
        mediaUrls: mediaUrls,
        category: category,
        governorate: governorate,
        city: city,
        portfolioProjectId: portfolioProjectId,
      );
      state = const AsyncData(null);
      ref.invalidate(exploreFeedProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> toggleLike(Post post) async {
    final userId = ref.read(currentSessionProvider)?.user.id;
    if (userId == null) return;
    final optimistic = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.likeCount + (post.isLiked ? -1 : 1),
    );
    final feed = ref.read(exploreFeedProvider.notifier);
    feed.patchPost(optimistic);
    try {
      await ref
          .read(postRepositoryProvider)
          .toggleLike(post.id, userId, optimistic.isLiked);
      ref.invalidate(postByIdProvider(post.id));
    } catch (_) {
      feed.patchPost(post); // rollback
    }
  }

  Future<void> toggleSave(Post post) async {
    final userId = ref.read(currentSessionProvider)?.user.id;
    if (userId == null) return;
    final optimistic = post.copyWith(isSaved: !post.isSaved);
    final feed = ref.read(exploreFeedProvider.notifier);
    feed.patchPost(optimistic);
    try {
      await ref
          .read(postRepositoryProvider)
          .toggleSave(post.id, userId, optimistic.isSaved);
      ref.invalidate(postByIdProvider(post.id));
      ref.invalidate(savedPostsProvider);
    } catch (_) {
      feed.patchPost(post); // rollback
    }
  }

  /// Adds a comment; throws on failure so the caller can show an error
  /// instead of a false success.
  Future<void> addComment(String postId, String content) async {
    final userId = ref.read(currentSessionProvider)?.user.id ?? '';
    await ref
        .read(postRepositoryProvider)
        .addComment(postId: postId, userId: userId, content: content);
    ref.invalidate(postCommentsProvider(postId));
    ref.invalidate(postByIdProvider(postId));
  }

  Future<void> deletePost(String postId) async {
    await ref.read(postRepositoryProvider).delete(postId);
    ref.invalidate(exploreFeedProvider);
  }
}

@riverpod
Future<List<PostComment>> postComments(Ref ref, String postId) async {
  return ref.read(postRepositoryProvider).fetchComments(postId);
}

@riverpod
Future<List<Post>> myPosts(Ref ref) async {
  final userId = ref.read(currentSessionProvider)?.user.id ?? '';
  return ref.read(postRepositoryProvider).fetchMyPosts(userId);
}

@riverpod
Future<List<Post>> savedPosts(Ref ref) async {
  final userId = ref.read(currentSessionProvider)?.user.id ?? '';
  return ref.read(postRepositoryProvider).fetchSavedPosts(userId);
}

@riverpod
Future<Post?> postById(Ref ref, String postId) async {
  final userId = ref.read(currentSessionProvider)?.user.id ?? '';
  return ref.read(postRepositoryProvider).fetchById(postId, userId);
}
