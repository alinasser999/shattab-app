import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/media/media_storage.dart';
import '../../../core/media/media_storage_provider.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utils/upload_policy.dart';
import '../domain/post.dart';

part 'post_repository.g.dart';

/// Embedded select used for by-id / my / saved reads (the feed itself goes
/// through the [get_for_you_feed] RPC which already computes these).
const _postSelect = '''
  id, author_id, author_role, post_type, caption, media_urls,
  category, governorate, city, portfolio_project_id, created_at,
  profiles!posts_author_id_fkey(full_name, avatar_url, phone),
  post_likes(count),
  post_comments(count)
''';

// Public profile surfaces must never hydrate a contractor's phone number.
const _communityPostSelect = '''
  id, author_id, author_role, post_type, caption, media_urls,
  category, governorate, city, portfolio_project_id, created_at,
  profiles!posts_author_id_fkey(full_name, avatar_url),
  post_likes(count),
  post_comments(count)
''';

/// Key an author identity is cached under while hydrating a page of rows.
///
/// Role is part of the key, not decoration: the same uuid can be looked up
/// through two different projections, and caching on the id alone would let a
/// contractor-facing identity satisfy a homeowner-facing row.
String authorIdentityKey(String authorId, String authorRole) =>
    '$authorId|$authorRole';

/// Attaches fetched identities to the rows that were missing one.
///
/// Split out from the fetching so it can be tested without a Supabase client.
/// This is the step where a mistake would put the wrong person's name on
/// someone else's post, so it is worth being able to exercise directly.
///
/// Rows that already carry a name keep the one they came with, order is
/// preserved, and an author the lookup could not resolve is left untouched
/// rather than blanked.
List<Map<String, dynamic>> applyAuthorIdentities(
  List<Map<String, dynamic>> rows,
  Map<String, Map<String, dynamic>> identities,
) {
  bool needsIdentity(Map<String, dynamic> row) {
    final profile = row['profiles'];
    return !(profile is Map<String, dynamic> &&
        (profile['full_name'] as String?)?.trim().isNotEmpty == true);
  }

  return [
    for (final row in rows)
      if (!needsIdentity(row))
        row
      else
        switch (identities[authorIdentityKey(
          row['author_id'] as String? ?? '',
          row['author_role'] as String? ?? '',
        )]) {
          final Map<String, dynamic> profile => {...row, 'profiles': profile},
          _ => row,
        },
  ];
}

class PostRepository {
  PostRepository(this._client, [MediaStorageService? mediaStorage])
    : _mediaStorage = mediaStorage;
  final SupabaseClient _client;
  final MediaStorageService? _mediaStorage;

  /// The set of post ids the user has liked / saved. One tiny query each;
  /// empty for guests. Used to fill is_liked / is_saved on non-RPC reads.
  Future<(Set<String>, Set<String>)> _userInteractions(
    String userId,
    Iterable<String> postIds,
  ) async {
    final ids = postIds.toList(growable: false);
    if (userId.isEmpty || ids.isEmpty) return (<String>{}, <String>{});
    final likes = await _client
        .from('post_likes')
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', ids);
    final saves = await _client
        .from('post_saves')
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', ids);
    return (
      {for (final r in likes as List) r['post_id'] as String},
      {for (final r in saves as List) r['post_id'] as String},
    );
  }

  /// Fills in author identity for rows whose embedded profile came back empty,
  /// one call per distinct author instead of one per row.
  ///
  /// `_withCommunityAuthor` is correct, but it was being mapped over rows inside
  /// a `Future.wait`, so a saved list of twenty posts by three authors issued
  /// twenty RPCs. Deduplicating by (author, role) makes that three, and a list
  /// of one author's work collapses to a single call.
  Future<List<Map<String, dynamic>>> _hydrateAuthors(
    List<Map<String, dynamic>> rows, {
    bool includePhone = true,
  }) async {
    bool needsIdentity(Map<String, dynamic> row) {
      final profile = row['profiles'];
      return !(profile is Map<String, dynamic> &&
          (profile['full_name'] as String?)?.trim().isNotEmpty == true);
    }

    final pending = rows.where(needsIdentity).toList();
    if (pending.isEmpty) return rows;

    final keys = <String, ({String id, String role})>{};
    for (final row in pending) {
      final id = row['author_id'] as String?;
      final role = row['author_role'] as String?;
      if (id != null && role != null) {
        keys[authorIdentityKey(id, role)] = (id: id, role: role);
      }
    }

    final identities = <String, Map<String, dynamic>>{};
    await Future.wait(
      keys.entries.map((entry) async {
        final resolved = await _withCommunityAuthor({
          'author_id': entry.value.id,
          'author_role': entry.value.role,
        }, includePhone: includePhone);
        final profile = resolved['profiles'];
        if (profile is Map<String, dynamic>) identities[entry.key] = profile;
      }),
    );

    return applyAuthorIdentities(rows, identities);
  }

  Post _fromRow(Map<String, dynamic> m, Set<String> liked, Set<String> saved) {
    final profile = m['profiles'] as Map<String, dynamic>?;
    final likeAgg =
        (m['post_likes'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final commentAgg =
        (m['post_comments'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final id = m['id'] as String;
    return Post(
      id: id,
      authorId: m['author_id'] as String,
      authorRole: m['author_role'] as String,
      postType: PostType.fromDb(m['post_type'] as String),
      caption: m['caption'] as String,
      mediaUrls: (m['media_urls'] as List?)?.cast<String>() ?? const [],
      category: m['category'] as String?,
      governorate: m['governorate'] as String?,
      city: m['city'] as String?,
      portfolioProjectId: m['portfolio_project_id'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      likeCount: (likeAgg?['count'] as num?)?.toInt() ?? 0,
      commentCount: (commentAgg?['count'] as num?)?.toInt() ?? 0,
      isLiked: liked.contains(id),
      isSaved: saved.contains(id),
      authorName: profile?['full_name'] as String?,
      authorAvatarUrl: profile?['avatar_url'] as String?,
      authorPhone: profile?['phone'] as String?,
    );
  }

  /// Direct post reads can be subject to profile RLS, while the feed uses its
  /// public identity projection. Hydrate only the missing identity fields so
  /// details and saved posts match the feed without exposing homeowner phone
  /// data through the profiles table.
  Future<Map<String, dynamic>> _withCommunityAuthor(
    Map<String, dynamic> row, {
    bool includePhone = true,
  }) async {
    final profile = row['profiles'];
    final hasName =
        profile is Map<String, dynamic> &&
        (profile['full_name'] as String?)?.trim().isNotEmpty == true;
    if (hasName) return row;

    final authorId = row['author_id'] as String?;
    final authorRole = row['author_role'] as String?;
    if (authorId == null || authorRole == null) return row;

    try {
      final result = await _client.rpc(
        'get_community_author_identity',
        params: {'p_author_id': authorId, 'p_author_role': authorRole},
      );
      if (result is List && result.isNotEmpty && result.first is Map) {
        final identity = Map<String, dynamic>.from(result.first as Map);
        if (!includePhone) {
          identity.remove('phone');
        }
        return {...row, 'profiles': identity};
      }
    } catch (_) {
      // Keep the existing row usable if an older environment has not applied
      // the identity migration yet.
    }
    return row;
  }

  /// Keyset pagination (migration 0017): pass the last post the caller already
  /// holds ([beforeCreatedAt] + [beforeId]) to get strictly older rows. Null
  /// cursor = first page. Drift-free as new posts arrive mid-scroll.
  Future<List<Post>> fetchFeed({
    required String userId,
    int limit = 10,
    DateTime? beforeCreatedAt,
    String? beforeId,
  }) async {
    final rows = await _client.rpc(
      'get_for_you_feed',
      params: {
        // Guests have no uuid — null keeps is_liked/is_saved false server-side.
        'p_user_id': userId.isEmpty ? null : userId,
        'p_limit': limit,
        'p_before_created_at': beforeCreatedAt?.toIso8601String(),
        'p_before_id': beforeId,
      },
    );
    return (rows as List)
        .map((r) => Post.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Post?> fetchById(String postId, String userId) async {
    final row = await _client
        .from('posts')
        .select(_postSelect)
        .eq('id', postId)
        .maybeSingle();
    if (row == null) return null;
    final (liked, saved) = await _userInteractions(userId, [postId]);
    final hydrated = await _withCommunityAuthor(Map<String, dynamic>.from(row));
    return _fromRow(hydrated, liked, saved);
  }

  Future<Post> create({
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
    final row = await _client
        .from('posts')
        .insert({
          'author_id': authorId,
          'author_role': authorRole,
          'post_type': postType,
          'caption': caption,
          'media_urls': mediaUrls,
          'category': ?category,
          'governorate': ?governorate,
          'city': ?city,
          'portfolio_project_id': ?portfolioProjectId,
        })
        .select()
        .single();
    return Post.fromJson(row);
  }

  Future<void> update(String postId, {String? caption}) async {
    await _client.from('posts').update({'caption': ?caption}).eq('id', postId);
  }

  Future<void> delete(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  Future<void> toggleLike(String postId, String userId, bool liked) async {
    if (liked) {
      // Idempotent: a double-tap / rapid re-like hits the (post_id,user_id) PK.
      // ignoreDuplicates makes the second insert a no-op instead of a 23505.
      await _client
          .from('post_likes')
          .upsert(
            {'post_id': postId, 'user_id': userId},
            onConflict: 'post_id,user_id',
            ignoreDuplicates: true,
          );
    } else {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    }
  }

  Future<void> toggleSave(String postId, String userId, bool saved) async {
    if (saved) {
      // Idempotent for the same reason as toggleLike (see above).
      await _client
          .from('post_saves')
          .upsert(
            {'post_id': postId, 'user_id': userId},
            onConflict: 'post_id,user_id',
            ignoreDuplicates: true,
          );
    } else {
      await _client
          .from('post_saves')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    }
  }

  Future<PostComment> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    final payload = <String, dynamic>{
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'parent_comment_id': ?parentCommentId,
    };
    final row = await _client
        .from('post_comments')
        .insert(payload)
        .select()
        .single();
    return PostComment.fromJson(row);
  }

  Future<void> updateComment({
    required String commentId,
    required String userId,
    required String content,
  }) async {
    await _client
        .from('post_comments')
        .update({'content': content})
        .eq('id', commentId)
        .eq('user_id', userId);
  }

  Future<void> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    await _client
        .from('post_comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', userId);
  }

  Future<void> toggleCommentLike({
    required String commentId,
    required String userId,
    required bool liked,
  }) async {
    if (liked) {
      await _client
          .from('post_comment_likes')
          .upsert(
            {'comment_id': commentId, 'user_id': userId},
            onConflict: 'comment_id,user_id',
            ignoreDuplicates: true,
          );
    } else {
      await _client
          .from('post_comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', userId);
    }
  }

  Future<List<PostComment>> fetchComments(String postId) async {
    final rows = await _client.rpc(
      'get_post_comments',
      params: {'p_post_id': postId},
    );
    return (rows as List)
        .map((row) => PostComment.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// The caller's own posts, newest first.
  ///
  /// [limit] is not optional in spirit: an author with years of posts would
  /// otherwise pull every row they had ever written into memory to render one
  /// screen. `id` joins the sort so the order is total and a future paged
  /// caller cannot see the same row twice.
  Future<List<Post>> fetchMyPosts(String userId, {int limit = 50}) async {
    final rows = await _client
        .from('posts')
        .select(_postSelect)
        .eq('author_id', userId)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    final maps = [
      for (final r in rows as List) Map<String, dynamic>.from(r as Map),
    ];
    final (liked, saved) = await _userInteractions(
      userId,
      maps.map((m) => m['id'] as String),
    );
    return maps.map((m) => _fromRow(m, liked, saved)).toList();
  }

  /// Returns the latest public community posts authored by a contractor.
  ///
  /// This deliberately uses the narrow community projection rather than the
  /// account-owned select, so profile pages cannot leak contact information.
  Future<List<Post>> fetchCommunityPostsByAuthor({
    required String authorId,
    required String viewerId,
    int limit = 3,
  }) async {
    final rows = await _client
        .from('posts')
        .select(_communityPostSelect)
        .eq('author_id', authorId)
        .eq('author_role', 'contractor')
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    final maps = [
      for (final r in rows as List) Map<String, dynamic>.from(r as Map),
    ];
    final (liked, saved) = await _userInteractions(
      viewerId,
      maps.map((m) => m['id'] as String),
    );
    final hydrated = await _hydrateAuthors(maps, includePhone: false);
    return hydrated.map((m) => _fromRow(m, liked, saved)).toList();
  }

  /// Posts this user has saved, most recently saved first.
  ///
  /// Was the worst read in the file: no bound on the outer query, and one
  /// identity RPC per row issued concurrently inside a `Future.wait`. Someone
  /// with five hundred saved posts opened five hundred rows and up to five
  /// hundred simultaneous round trips from a single screen. Now bounded, and
  /// the identity lookups are deduplicated by author.
  ///
  /// Every row here is saved by definition, so `saved` is passed as the row's
  /// own id rather than re-queried.
  Future<List<Post>> fetchSavedPosts(String userId, {int limit = 50}) async {
    if (userId.isEmpty) return [];
    final rows = await _client
        .from('post_saves')
        .select('created_at, posts!inner($_postSelect)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    final posts = [
      for (final r in rows as List)
        Map<String, dynamic>.from((r as Map<String, dynamic>)['posts'] as Map),
    ];
    final (liked, _) = await _userInteractions(
      userId,
      posts.map((m) => m['id'] as String),
    );
    final hydrated = await _hydrateAuthors(posts);
    return hydrated
        .map((m) => _fromRow(m, liked, {m['id'] as String}))
        .toList();
  }

  Future<String> uploadImage(
    String userId,
    Uint8List bytes,
    String fileName,
  ) async {
    UploadPolicy.validateImageBytes(bytes);
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final mediaStorage = _mediaStorage;
    if (mediaStorage != null) {
      final result = await mediaStorage.uploadPublic(
        category: MediaCategory.postMedia,
        userId: userId,
        bytes: bytes,
        fileName: fileName,
        contentType: 'image/jpeg',
        supabasePath: path,
        upsert: false,
      );
      return result.url;
    }
    await _client.storage.from('post-media').uploadBinary(path, bytes);
    return _client.storage.from('post-media').getPublicUrl(path);
  }
}

@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) {
  return PostRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(mediaStorageProvider),
  );
}
