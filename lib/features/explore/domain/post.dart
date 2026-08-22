enum PostType {
  projectShowcase('project_showcase'),
  tip('tip'),
  milestone('milestone'),
  renovationUpdate('renovation_update');

  const PostType(this.dbValue);
  final String dbValue;

  static PostType fromDb(String value) {
    // Tolerant like every other wire enum: a newer migration adding a
    // post_type must not crash an older client's feed parsing. Unknown
    // values render as the generic showcase type rather than throwing.
    for (final e in PostType.values) {
      if (e.dbValue == value) return e;
    }
    return PostType.projectShowcase;
  }
}

/// The community composer exposes friendlier publishing choices than the
/// storage-level post types. Questions reuse the existing `tip` post type and
/// are marked through the posts.category column so this remains compatible
/// with the deployed posts check constraint.
enum CommunityPostKind {
  standard('standard', PostType.renovationUpdate),
  beforeAfter('before_after', PostType.projectShowcase),
  tips('tips', PostType.tip, categoryMarker: 'tips'),
  experiences('experiences', PostType.milestone, categoryMarker: 'experience'),
  question('question', PostType.tip, categoryMarker: 'question');

  const CommunityPostKind(
    this.routeValue,
    this.storageType, {
    this.categoryMarker,
  });

  final String routeValue;
  final PostType storageType;
  final String? categoryMarker;

  static CommunityPostKind fromQuery(String? value) {
    return CommunityPostKind.values.firstWhere(
      (kind) => kind.routeValue == value,
      orElse: () => CommunityPostKind.standard,
    );
  }
}

class Post {
  Post({
    required this.id,
    required this.authorId,
    required this.authorRole,
    required this.postType,
    required this.caption,
    this.mediaUrls = const [],
    this.category,
    this.governorate,
    this.city,
    this.portfolioProjectId,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.authorName,
    this.authorAvatarUrl,
    this.authorPhone,
  });

  final String id;
  final String authorId;
  final String authorRole;
  final PostType postType;
  final String caption;
  final List<String> mediaUrls;
  final String? category;
  final String? governorate;
  final String? city;
  final String? portfolioProjectId;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isSaved;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? authorPhone;

  bool get isQuestion => category == CommunityPostKind.question.categoryMarker;

  Post copyWith({
    String? id,
    String? authorId,
    String? authorRole,
    PostType? postType,
    String? caption,
    List<String>? mediaUrls,
    String? category,
    String? governorate,
    String? city,
    String? portfolioProjectId,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isSaved,
    String? authorName,
    String? authorAvatarUrl,
    String? authorPhone,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorRole: authorRole ?? this.authorRole,
      postType: postType ?? this.postType,
      caption: caption ?? this.caption,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      category: category ?? this.category,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      portfolioProjectId: portfolioProjectId ?? this.portfolioProjectId,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorPhone: authorPhone ?? this.authorPhone,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String,
    authorId: json['author_id'] as String,
    authorRole: json['author_role'] as String,
    postType: PostType.fromDb(json['post_type'] as String),
    caption: json['caption'] as String,
    mediaUrls:
        (json['media_urls'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    category: json['category'] as String?,
    governorate: json['governorate'] as String?,
    city: json['city'] as String?,
    portfolioProjectId: json['portfolio_project_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
    commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
    isLiked: json['is_liked'] as bool? ?? false,
    isSaved: json['is_saved'] as bool? ?? false,
    authorName: json['author_name'] as String?,
    authorAvatarUrl: json['author_avatar_url'] as String?,
    authorPhone: json['author_phone'] as String?,
  );
}

class PostComment {
  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
    this.parentCommentId,
    this.updatedAt,
    this.likeCount = 0,
    this.isLiked = false,
    this.userRole,
  });

  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatarUrl;
  final String? parentCommentId;
  final DateTime? updatedAt;
  final int likeCount;
  final bool isLiked;
  final String? userRole;

  bool get wasEdited => updatedAt != null && updatedAt!.isAfter(createdAt);

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
    id: json['id'] as String,
    postId: json['post_id'] as String,
    userId: json['user_id'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    userName: json['user_name'] as String?,
    userAvatarUrl: json['user_avatar_url'] as String?,
    parentCommentId: json['parent_comment_id'] as String?,
    updatedAt: json['updated_at'] == null
        ? null
        : DateTime.parse(json['updated_at'] as String),
    likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
    isLiked: json['is_liked'] as bool? ?? false,
    userRole: json['user_role'] as String?,
  );
}
