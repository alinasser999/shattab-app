import 'package:flutter/foundation.dart';
import '../../discovery/domain/contractor_listing.dart';
import '../../explore/domain/post.dart';
import '../../portfolio/domain/portfolio_project.dart';

/// A local-only visual inspection switch.
///
/// The reference images are composition references, not a source of customer
/// or professional records. Keeping this switch compile-time-only makes it
/// impossible for a normal release to silently turn a screenshot fixture into
/// marketplace evidence.
const bool referenceHomePreviewEnabled =
    kDebugMode && bool.fromEnvironment('SHATTAB_REFERENCE_PREVIEW');

class ReferenceHomeProfessional {
  const ReferenceHomeProfessional({
    required this.id,
    required this.name,
    required this.specialty,
    required this.location,
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.projectsCompleted,
    this.coverPhotoUrl,
    this.verified = false,
    this.sponsored = false,
  });

  final String id;
  final String name;
  final String specialty;
  final String location;
  final String avatarUrl;
  final String? coverPhotoUrl;
  final double rating;
  final int reviewCount;
  final int projectsCompleted;
  final bool verified;
  final bool sponsored;

  factory ReferenceHomeProfessional.fromListing(ContractorListing listing) {
    final name = listing.businessName.trim().isNotEmpty
        ? listing.businessName.trim()
        : listing.fullName.trim();
    return ReferenceHomeProfessional(
      id: listing.id,
      name: name,
      specialty: listing.specialties.isEmpty
          ? listing.providerKind.name
          : listing.specialties.first,
      location: listing.serviceAreas.firstOrNull ?? '',
      avatarUrl: listing.logoUrl ?? '',
      coverPhotoUrl: listing.coverPhotoUrl,
      rating: listing.rating ?? 0,
      reviewCount: listing.reviewCount,
      projectsCompleted: listing.projectsCompleted,
      verified: listing.verified,
      sponsored: listing.isSponsored,
    );
  }
}

class ReferenceHomeProject {
  const ReferenceHomeProject({
    required this.id,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.progress,
    required this.stage,
    required this.offerCount,
    this.previewOfferAvatarPaths = const [],
    this.isPreview = false,
  });

  final String id;
  final String title;
  final String location;
  final String imageUrl;
  final double progress;
  final String stage;
  final int offerCount;
  final List<String> previewOfferAvatarPaths;
  final bool isPreview;
}

enum ReferenceHomeWorkMediaKind {
  /// A pair whose before/after roles were explicitly supplied by its source.
  verifiedBeforeAfter,

  /// Generic portfolio photos, with no implied role or chronology.
  gallery,
}

class ReferenceHomeWork {
  const ReferenceHomeWork({
    required this.id,
    required this.contractorId,
    required this.title,
    required this.category,
    required this.location,
    required this.mediaKind,
    this.beforeUrl = '',
    this.afterUrl = '',
    this.galleryUrls = const [],
    this.rating,
    this.reviewCount = 0,
    this.isPreview = false,
  });

  final String id;
  final String contractorId;
  final String title;
  final String category;
  final String location;
  final ReferenceHomeWorkMediaKind mediaKind;
  final String beforeUrl;
  final String afterUrl;
  final List<String> galleryUrls;
  final double? rating;
  final int reviewCount;
  final bool isPreview;

  factory ReferenceHomeWork.fromProject(PortfolioProject project) {
    final media = <String>{
      for (final url in [project.coverPhotoUrl, ...project.photoUrls])
        if (url.trim().isNotEmpty) url.trim(),
    }.toList(growable: false);
    return ReferenceHomeWork(
      id: project.id,
      contractorId: project.contractorId,
      title: project.title,
      category: project.category ?? '',
      location: project.location ?? '',
      mediaKind: ReferenceHomeWorkMediaKind.gallery,
      galleryUrls: media,
    );
  }
}

class ReferenceHomeCommunityPost {
  const ReferenceHomeCommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.badge,
    required this.timeLabel,
    required this.caption,
    required this.imageUrl,
    required this.likeCount,
    required this.commentCount,
    this.isPreview = false,
    this.isQuestion = false,
  });

  final String id;
  final String authorId;
  final bool isQuestion;
  final String authorName;
  final String authorAvatarUrl;
  final String badge;
  final String timeLabel;
  final String caption;
  final String imageUrl;
  final int likeCount;
  final int commentCount;
  final bool isPreview;

  factory ReferenceHomeCommunityPost.fromPost(
    Post post, {
    required String timeLabel,
  }) {
    return ReferenceHomeCommunityPost(
      id: post.id,
      isQuestion: post.isQuestion,
      authorId: post.authorId,
      authorName: post.authorName?.trim().isNotEmpty == true
          ? post.authorName!.trim()
          : 'عضو في المجتمع',
      authorAvatarUrl: post.authorAvatarUrl ?? '',
      badge: post.isQuestion ? 'سؤال من المجتمع' : 'من واقع التجربة',
      timeLabel: timeLabel,
      caption: post.caption,
      imageUrl: post.mediaUrls.firstOrNull ?? '',
      likeCount: post.likeCount,
      commentCount: post.commentCount,
    );
  }
}

/// Presentation-only rows for local visual comparison. They are not domain
/// records, never enter a repository, and are ignored unless the explicit
/// compile-time preview switch is enabled.
abstract final class ReferenceHomePreviewData {
  static const heroImage = 'assets/images/home_clone_hero.png';
  static const projectImage = 'assets/images/home_clone_project_floorplan.png';
  static const beforeAfterImage = 'assets/images/home_clone_story_before.png';
  static const communityImage =
      'assets/images/home_clone_community_kitchen.png';
  // All rows below are local illustration data, never marketplace evidence.
  static const professionals = <ReferenceHomeProfessional>[
    ReferenceHomeProfessional(
      id: 'preview-khaled',
      name: 'خالد للمطابخ',
      specialty: 'kitchen',
      location: 'القاهرة الجديدة',
      avatarUrl: 'assets/images/home_clone_avatar_khaled.png',
      rating: 4.8,
      reviewCount: 37,
      projectsCompleted: 0,
      coverPhotoUrl: 'assets/images/home_clone_featured_khaled_cover.png',
    ),
    ReferenceHomeProfessional(
      id: 'preview-noor',
      name: 'نور للتصميم',
      specialty: 'design',
      location: 'القاهرة الجديدة',
      avatarUrl: 'assets/images/home_clone_avatar_noor.png',
      rating: 4.9,
      reviewCount: 62,
      projectsCompleted: 0,
      coverPhotoUrl: 'assets/images/home_clone_featured_noor_cover.png',
    ),
  ];
  static const nearby = <ReferenceHomeProfessional>[
    ReferenceHomeProfessional(
      id: 'preview-ahmed',
      name: 'أحمد للكهرباء',
      specialty: 'electrical',
      location: 'القاهرة الجديدة',
      avatarUrl: 'assets/images/home_clone_avatar_ahmed.png',
      rating: 4.9,
      reviewCount: 28,
      projectsCompleted: 0,
    ),
    ReferenceHomeProfessional(
      id: 'preview-omar',
      name: 'عمر للسباكة',
      specialty: 'plumbing',
      location: 'التجمع الخامس',
      avatarUrl: 'assets/images/home_clone_avatar_omar.png',
      rating: 4.9,
      reviewCount: 46,
      projectsCompleted: 0,
    ),
    ReferenceHomeProfessional(
      id: 'preview-hossam',
      name: 'حسام للنجارة',
      specialty: 'carpentry',
      location: 'القاهرة الجديدة',
      avatarUrl: 'assets/images/home_clone_avatar_hossam.png',
      rating: 0.0,
      reviewCount: 0,
      projectsCompleted: 0,
    ),
  ];
  static const topRated = <ReferenceHomeProfessional>[
    ReferenceHomeProfessional(
      id: 'preview-sara',
      name: 'سارة للديكور',
      specialty: 'design',
      location: 'القاهرة الجديدة',
      avatarUrl: 'assets/images/home_clone_avatar_sara.png',
      rating: 4.9,
      reviewCount: 48,
      projectsCompleted: 0,
    ),
    ReferenceHomeProfessional(
      id: 'preview-yasser',
      name: 'ياسر للتشطيبات',
      specialty: 'full_reno',
      location: '6 أكتوبر',
      avatarUrl: 'assets/images/home_clone_avatar_yasser.png',
      rating: 4.8,
      reviewCount: 53,
      projectsCompleted: 0,
    ),
    ReferenceHomeProfessional(
      id: 'preview-mohamed',
      name: 'محمد للدهانات',
      specialty: 'paint',
      location: 'مدينة نصر',
      avatarUrl: 'assets/images/home_clone_avatar_mohamed.png',
      rating: 4.7,
      reviewCount: 22,
      projectsCompleted: 0,
    ),
  ];
  static const kitchens = <ReferenceHomeProfessional>[
    ReferenceHomeProfessional(
      id: 'preview-mostafa',
      name: 'مصطفى للنجارة',
      specialty: 'carpentry',
      location: 'مدينة نصر',
      avatarUrl: 'assets/images/home_clone_avatar_mostafa.png',
      rating: 4.7,
      reviewCount: 26,
      projectsCompleted: 0,
      coverPhotoUrl: 'assets/images/home_clone_kitchen_mostafa_cover.png',
    ),
    ReferenceHomeProfessional(
      id: 'preview-bayt',
      name: 'بيت المطبخ',
      specialty: 'kitchen',
      location: 'القاهرة الجديدة',
      avatarUrl: 'assets/images/home_clone_avatar_noor.png',
      rating: 4.8,
      reviewCount: 31,
      projectsCompleted: 0,
      coverPhotoUrl: 'assets/images/home_clone_kitchen_bayt_cover.png',
    ),
  ];
  static const finishing = <ReferenceHomeProfessional>[
    ReferenceHomeProfessional(
      id: 'preview-finishing-ahmed',
      name: 'أحمد للتشطيب',
      specialty: 'full_reno',
      location: 'الشيخ زايد',
      avatarUrl: 'assets/images/home_clone_avatar_khaled.png',
      rating: 4.8,
      reviewCount: 38,
      projectsCompleted: 0,
      coverPhotoUrl: 'assets/images/home_clone_finishing_ahmed_cover.png',
    ),
    ReferenceHomeProfessional(
      id: 'preview-dar',
      name: 'دار للتشطيبات',
      specialty: 'full_reno',
      location: 'القاهرة الجديدة',
      avatarUrl: 'assets/images/home_clone_avatar_khaled.png',
      rating: 4.9,
      reviewCount: 55,
      projectsCompleted: 0,
      coverPhotoUrl: 'assets/images/home_clone_finishing_dar_cover.png',
    ),
  ];
  static const project = ReferenceHomeProject(
    id: 'preview-brief',
    title: 'تجديد شقة المعادي',
    location: 'المعادي، القاهرة',
    imageUrl: projectImage,
    progress: .5,
    stage: 'تنفيذ النجارة',
    offerCount: 4,
    isPreview: true,
  );
  static const work = ReferenceHomeWork(
    id: 'preview-work',
    contractorId: 'preview-khaled',
    title: 'مطبخ صغير، فرق كبير',
    category: 'مطابخ',
    location: 'القاهرة الجديدة',
    mediaKind: ReferenceHomeWorkMediaKind.verifiedBeforeAfter,
    beforeUrl: beforeAfterImage,
    afterUrl: 'assets/images/home_clone_story_after.png',
    isPreview: true,
  );
  static const communityPosts = <ReferenceHomeCommunityPost>[
    ReferenceHomeCommunityPost(
      id: 'preview-post-mahmoud',
      authorId: 'preview-homeowner-mahmoud',
      authorName: 'محمود',
      authorAvatarUrl: 'assets/images/home_clone_avatar_hossam.png',
      badge: 'سؤال من المجتمع',
      timeLabel: '',
      caption:
          'بورسلين ولا سيراميك للمطبخ؟ عايز أعرف أفضل نوع من ناحية التحمل والسعر.',
      imageUrl: '',
      likeCount: 0,
      commentCount: 0,
      isQuestion: true,
      isPreview: true,
    ),
    ReferenceHomeCommunityPost(
      id: 'preview-post-sara',
      authorId: 'preview-homeowner-sara',
      authorName: 'سارة',
      authorAvatarUrl: 'assets/images/home_clone_avatar_sara.png',
      badge: 'من واقع التجربة',
      timeLabel: '',
      caption:
          'حاجات كنت أتمنى أعرفها قبل تشطيب المطبخ. اختارنا الخامات، توزيع الإضاءة، وطول التخزين اللي فعلاً بيفرق.',
      imageUrl: communityImage,
      likeCount: 0,
      commentCount: 0,
      isPreview: true,
    ),
  ];
  static ReferenceHomeProfessional professionalForId(String id) => [
    ...professionals,
    ...nearby,
    ...topRated,
    ...kitchens,
    ...finishing,
  ].firstWhere((item) => item.id == id);
}
