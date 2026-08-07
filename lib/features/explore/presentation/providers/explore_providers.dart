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
      if (cursor == null) {
        state = AsyncData(posts);
      } else {
        final current = state.value ?? const <Post>[];
        final ids = current.map((post) => post.id).toSet();
        state = AsyncData([
          ...current,
          ...posts.where((post) => ids.add(post.id)),
        ]);
      }
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

  /// Flips the like immediately and undoes it if the write fails.
  ///
  /// Rethrows after the rollback, like [addComment], so the caller can say so.
  /// A silent rollback is indistinguishable from a tap that never registered,
  /// and on a patchy mobile connection that is the common case, not the rare
  /// one.
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
      rethrow;
    }
  }

  /// Flips the save immediately and undoes it if the write fails.
  ///
  /// Rethrows after the rollback, for the reason given on [toggleLike].
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
      rethrow;
    }
  }

  /// Adds a comment; throws on failure so the caller can show an error
  /// instead of a false success.
  Future<void> addComment(
    String postId,
    String content, {
    String? parentCommentId,
  }) async {
    final userId = ref.read(currentSessionProvider)?.user.id ?? '';
    await ref
        .read(postRepositoryProvider)
        .addComment(
          postId: postId,
          userId: userId,
          content: content,
          parentCommentId: parentCommentId,
        );
    ref.invalidate(postCommentsProvider(postId));
    ref.invalidate(postByIdProvider(postId));
  }

  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    final userId = ref.read(currentSessionProvider)?.user.id;
    if (userId == null) return;
    await ref
        .read(postRepositoryProvider)
        .updateComment(commentId: commentId, userId: userId, content: content);
    ref.invalidate(postCommentsProvider(postId));
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final userId = ref.read(currentSessionProvider)?.user.id;
    if (userId == null) return;
    await ref
        .read(postRepositoryProvider)
        .deleteComment(commentId: commentId, userId: userId);
    ref.invalidate(postCommentsProvider(postId));
    ref.invalidate(postByIdProvider(postId));
  }

  Future<void> toggleCommentLike({
    required String postId,
    required PostComment comment,
  }) async {
    final userId = ref.read(currentSessionProvider)?.user.id;
    if (userId == null) return;
    await ref
        .read(postRepositoryProvider)
        .toggleCommentLike(
          commentId: comment.id,
          userId: userId,
          liked: !comment.isLiked,
        );
    ref.invalidate(postCommentsProvider(postId));
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

/// Public contractor-profile preview of the author's latest community posts.
/// The repository keeps the projection contact-safe and applies the viewer's
/// like/save state without changing the feed provider's pagination state.
final contractorCommunityPostsProvider = FutureProvider.autoDispose
    .family<List<Post>, String>((ref, contractorId) {
      final viewerId = ref.read(currentSessionProvider)?.user.id ?? '';
      return ref
          .read(postRepositoryProvider)
          .fetchCommunityPostsByAuthor(
            authorId: contractorId,
            viewerId: viewerId,
          );
    });

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
