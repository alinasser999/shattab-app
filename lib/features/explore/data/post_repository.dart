import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
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

class PostRepository {
  PostRepository(this._client);
  final SupabaseClient _client;

  /// The set of post ids the user has liked / saved. One tiny query each;
  /// empty for guests. Used to fill is_liked / is_saved on non-RPC reads.
  Future<(Set<String>, Set<String>)> _userInteractions(String userId) async {
    if (userId.isEmpty) return (<String>{}, <String>{});
    final likes = await _client
        .from('post_likes')
        .select('post_id')
        .eq('user_id', userId);
    final saves = await _client
        .from('post_saves')
        .select('post_id')
        .eq('user_id', userId);
    return (
      {for (final r in likes as List) r['post_id'] as String},
      {for (final r in saves as List) r['post_id'] as String},
    );
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
    final (liked, saved) = await _userInteractions(userId);
    return _fromRow(row, liked, saved);
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
  }) async {
    final row = await _client
        .from('post_comments')
        .insert({'post_id': postId, 'user_id': userId, 'content': content})
        .select()
        .single();
    return PostComment.fromJson(row);
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('post_comments').delete().eq('id', commentId);
  }

  Future<List<PostComment>> fetchComments(String postId) async {
    final rows = await _client
        .from('post_comments')
        .select('''
          id, post_id, user_id, content, created_at,
          profiles!inner(full_name, avatar_url)
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return (rows as List).map((r) {
      final m = r as Map<String, dynamic>;
      final profile = m['profiles'] as Map<String, dynamic>?;
      return PostComment(
        id: m['id'] as String,
        postId: m['post_id'] as String,
        userId: m['user_id'] as String,
        content: m['content'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        userName: profile?['full_name'] as String?,
        userAvatarUrl: profile?['avatar_url'] as String?,
      );
    }).toList();
  }

  Future<List<Post>> fetchMyPosts(String userId) async {
    final rows = await _client
        .from('posts')
        .select(_postSelect)
        .eq('author_id', userId)
        .order('created_at', ascending: false);
    final (liked, saved) = await _userInteractions(userId);
    return (rows as List)
        .map((r) => _fromRow(r as Map<String, dynamic>, liked, saved))
        .toList();
  }

  Future<List<Post>> fetchSavedPosts(String userId) async {
    if (userId.isEmpty) return [];
    final rows = await _client
        .from('post_saves')
        .select('created_at, posts!inner($_postSelect)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final (liked, _) = await _userInteractions(userId);
    return (rows as List).map((r) {
      final post = (r as Map<String, dynamic>)['posts'] as Map<String, dynamic>;
      return _fromRow(post, liked, {post['id'] as String});
    }).toList();
  }

  Future<String> uploadImage(
    String userId,
    Uint8List bytes,
    String fileName,
  ) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('post-media').uploadBinary(path, bytes);
    return _client.storage.from('post-media').getPublicUrl(path);
  }
}

@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) {
  return PostRepository(ref.watch(supabaseClientProvider));
}
