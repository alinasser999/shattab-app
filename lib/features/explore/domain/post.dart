enum PostType {
  projectShowcase('project_showcase'),
  tip('tip'),
  milestone('milestone'),
  renovationUpdate('renovation_update');

  const PostType(this.dbValue);
  final String dbValue;

  static PostType fromDb(String value) {
    return PostType.values.firstWhere((e) => e.dbValue == value);
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
  });

  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatarUrl;

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
    id: json['id'] as String,
    postId: json['post_id'] as String,
    userId: json['user_id'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    userName: json['user_name'] as String?,
    userAvatarUrl: json['user_avatar_url'] as String?,
  );
}
