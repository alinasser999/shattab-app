import '../../discovery/domain/contractor_listing.dart';
import '../../explore/domain/post.dart';
import '../../portfolio/domain/portfolio_project.dart';

/// A local-only visual inspection switch.
///
/// The reference images are composition references, not a source of customer
/// or professional records. Keeping this switch compile-time-only makes it
/// impossible for a normal release to silently turn a screenshot fixture into
/// marketplace evidence.
const bool referenceHomePreviewEnabled = bool.fromEnvironment(
  'SHATTAB_REFERENCE_PREVIEW',
);

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
    this.verified = false,
    this.sponsored = false,
  });

  final String id;
  final String name;
  final String specialty;
  final String location;
  final String avatarUrl;
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
  });

  final String id;
  final String authorId;
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
  static const heroImage = 'assets/images/stitch_home_hero.jpg';
  static const projectImage = 'assets/images/stitch_home_project.jpg';
  static const beforeAfterImage = 'assets/images/stitch_home_work_before.jpg';
  static const communityImage = 'assets/images/stitch_home_community_hpl.jpg';

  static const professionals = <ReferenceHomeProfessional>[
    ReferenceHomeProfessional(
      id: 'preview-karim',
      name: 'المهندس كريم شريف',
      specialty: 'تشطيبات كاملة',
      location: 'الشيخ زايد',
      avatarUrl: 'assets/images/stitch_home_featured_karim.jpg',
      rating: 4.8,
      reviewCount: 38,
      projectsCompleted: 56,
    ),
    ReferenceHomeProfessional(
      id: 'preview-rania',
      name: 'د. رانيا حمدي يسري',
      specialty: 'تصميم داخلي',
      location: '6 أكتوبر',
      avatarUrl: 'assets/images/stitch_home_featured_rania.jpg',
      rating: 4.8,
      reviewCount: 28,
      projectsCompleted: 32,
    ),
    ReferenceHomeProfessional(
      id: 'preview-noor',
      name: 'نور الديكور والتصميم',
      specialty: 'تصميم داخلي وتشطيبات',
      location: 'القاهرة الجديدة',
      avatarUrl: 'assets/images/stitch_home_featured_noor.jpg',
      rating: 4.9,
      reviewCount: 44,
      projectsCompleted: 48,
    ),
  ];

  static const topRated = <ReferenceHomeProfessional>[
    ReferenceHomeProfessional(
      id: 'preview-ahmed',
      name: 'أحمد مصطفى',
      specialty: 'تشطيبات كاملة',
      location: 'القاهرة',
      avatarUrl: 'assets/images/stitch_home_top_ahmed.jpg',
      rating: 4.9,
      reviewCount: 120,
      projectsCompleted: 84,
      verified: true,
    ),
    ReferenceHomeProfessional(
      id: 'preview-sara',
      name: 'سارة علي',
      specialty: 'تصميم داخلي',
      location: 'الشيخ زايد',
      avatarUrl: 'assets/images/stitch_home_top_sara.jpg',
      rating: 4.9,
      reviewCount: 98,
      projectsCompleted: 63,
      verified: true,
    ),
    ReferenceHomeProfessional(
      id: 'preview-mahmoud',
      name: 'محمود جابر',
      specialty: 'كهرباء وسباكة',
      location: 'أكتوبر',
      avatarUrl: 'assets/images/stitch_home_top_mahmoud.jpg',
      rating: 4.8,
      reviewCount: 87,
      projectsCompleted: 71,
    ),
  ];

  static const project = ReferenceHomeProject(
    id: 'preview-brief',
    title: 'تجديد شقة المعادي',
    location: 'المعادي، القاهرة',
    imageUrl: projectImage,
    progress: 0.5,
    stage: 'تنفيذ النجارة',
    offerCount: 4,
    previewOfferAvatarPaths: [
      'assets/images/stitch_home_contractor_badge.jpg',
      'assets/images/stitch_home_engineer_badge.jpg',
    ],
    isPreview: true,
  );

  static const work = ReferenceHomeWork(
    id: 'preview-work',
    contractorId: 'preview-ahmed',
    title: 'تجديد شقة في المعادي',
    category: 'تشطيب كامل، ديكور وتصميم',
    location: 'المعادي، القاهرة',
    mediaKind: ReferenceHomeWorkMediaKind.verifiedBeforeAfter,
    beforeUrl: beforeAfterImage,
    afterUrl: 'assets/images/stitch_home_work_after.jpg',
    rating: 4.9,
    reviewCount: 20,
    isPreview: true,
  );

  static const communityPosts = <ReferenceHomeCommunityPost>[
    ReferenceHomeCommunityPost(
      id: 'preview-post-sara',
      authorId: 'preview-homeowner-sara',
      authorName: 'سارة من المعادي',
      authorAvatarUrl: 'assets/images/stitch_home_community_sara_avatar.jpg',
      badge: 'نصيحة من واقع التجربة',
      timeLabel: 'منذ 3 ساعات',
      caption:
          'حد جرب بلاطات HPL للمطابخ؟ ممتازة بين الأناقة والمتانة .. أنصحكم بيها جداً!',
      imageUrl: communityImage,
      likeCount: 12,
      commentCount: 6,
      isPreview: true,
    ),
    ReferenceHomeCommunityPost(
      id: 'preview-post-mohamed',
      authorId: 'preview-homeowner-mohamed',
      authorName: 'محمد من الشيخ زايد',
      authorAvatarUrl: 'assets/images/stitch_home_community_mohamed_avatar.jpg',
      badge: 'تجربتي',
      timeLabel: 'منذ يومين',
      caption:
          'شطب ساعدني ألاقي فريق محترف وسهل التواصل معاهم جداً في مواعيد التسليم.',
      imageUrl: 'assets/images/stitch_home_community_lounge.jpg',
      likeCount: 18,
      commentCount: 4,
      isPreview: true,
    ),
  ];

  static ReferenceHomeProfessional professionalForId(String id) {
    for (final professional in professionals) {
      if (professional.id == id) return professional;
    }
    for (final professional in topRated) {
      if (professional.id == id) return professional;
    }
    return topRated.first;
  }
}
