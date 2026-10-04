import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../portfolio/data/portfolio_repository.dart';
import '../../portfolio/domain/portfolio_project.dart';
import '../../reviews/data/reviews_repository.dart';
import '../../reviews/domain/review.dart';
import '../../saved/data/saved_repository.dart';
import '../data/discovery_repository.dart';
import 'contractor_listing.dart';

/// This fixture can only be reached from a debug build with an explicit flag.
/// It is not a substitute for marketplace data and never enables an auth
/// bypass in the production entry point.
const bool professionalReferenceEnabled =
    kDebugMode && bool.fromEnvironment('SHATTAB_PROFESSIONAL_REFERENCE');

/// Deterministic data used by the separately launched reference surface.
/// Every id and every media value is local to this sample namespace.
abstract final class ProfessionalReferenceFixture {
  static const String idPrefix = 'reference-professional-';
  static const String noorId = '${idPrefix}noor';

  static const String livingRoomImage =
      'assets/images/professional_reference_living.jpg';
  static const String bedroomImage =
      'assets/images/professional_reference_bedroom.jpg';
  static const String bathroomImage =
      'assets/images/professional_reference_bathroom.jpg';
  static const String avatarImage =
      'assets/images/professional_reference_avatar.png';
  static const String ahmadReviewImage =
      'assets/images/professional_reference_review_ahmed.png';
  static const String saraReviewImage =
      'assets/images/professional_reference_review_sara.png';
  static const String identityPattern =
      'assets/images/professional_reference_pattern_identity.png';
  static const String cardPatternLeft =
      'assets/images/professional_reference_pattern_card_left.png';
  static const String cardPatternRight =
      'assets/images/professional_reference_pattern_card_right.png';

  /// The screenshots expose five gallery positions, while clean recovery
  /// yielded three distinct room crops. The repeated slots intentionally reuse
  /// those recovered photos rather than inventing extra project media.
  static const List<String> _noorGalleryMedia = [
    livingRoomImage,
    bedroomImage,
    bathroomImage,
    livingRoomImage,
    bedroomImage,
  ];

  static const Set<String> allowedMediaPaths = {
    livingRoomImage,
    bedroomImage,
    bathroomImage,
    avatarImage,
    ahmadReviewImage,
    saraReviewImage,
    identityPattern,
    cardPatternLeft,
    cardPatternRight,
  };

  static bool isFixtureId(String id) => id.startsWith(idPrefix);

  static bool isAllowedMediaPath(String? value) =>
      professionalReferenceEnabled &&
      value != null &&
      allowedMediaPaths.contains(value.trim());

  static const String overview =
      'بنحوّل أفكارك لمساحات مريحة وعملية، من التصميم لحد التنفيذ.';

  static const List<String> services = [
    'تصميم داخلي متكامل',
    'تنفيذ الديكورات والتشطيبات',
    'تنسيق الأثاث والإضاءة',
  ];

  static const List<String> workSteps = [
    'معاينة المساحة وفهم الاحتياجات',
    'إعداد التصميم واعتماد الخامات',
    'تنفيذ ومتابعة مراحل العمل',
  ];

  static final ContractorListing noorListing = ContractorListing(
    id: noorId,
    fullName: 'نور',
    businessName: 'نور للديكور والتصميم',
    phone: '',
    specialties: ['design'],
    serviceAreas: ['القاهرة الجديدة', 'المعادي', 'مدينة نصر'],
    projectsCompleted: 32,
    bio: overview,
    logoUrl: avatarImage,
    coverPhotoUrl: livingRoomImage,
    headline: 'تصميم داخلي وتشطيبات',
    yearsExperience: 8,
    reviewCount: 186,
    reviewAvg: 4.903225806451613,
    verified: true,
    plan: 'pro',
    planExpiresAt: DateTime.utc(2099, 12, 31),
    isSponsored: true,
    memberSince: DateTime.utc(2018, 10, 3),
    providerKind: ProviderKind.interiorDesigner,
  );

  /// The first record is the reference professional. The remaining names are
  /// explicitly generic sample labels so they cannot be mistaken for people
  /// or businesses in the real catalogue.
  static final List<ContractorListing> listings = List.unmodifiable([
    noorListing,
    for (var number = 2; number <= 124; number++) _sampleListing(number),
  ]);

  static final List<PortfolioProject> _projects = List.unmodifiable([
    PortfolioProject(
      id: '${idPrefix}project-fifth-settlement',
      contractorId: noorId,
      title: 'شقة في التجمع الخامس',
      description: 'تصميم وتنفيذ داخلي لشقة في القاهرة الجديدة.',
      coverPhotoUrl: livingRoomImage,
      photoUrls: [bathroomImage],
      category: 'design',
      apartmentType: 'apartment',
      location: 'القاهرة الجديدة',
      yearCompleted: 2025,
      position: 2,
      createdAt: DateTime.utc(2025, 11, 15),
    ),
    PortfolioProject(
      id: '${idPrefix}project-maadi-bedroom',
      contractorId: noorId,
      title: 'غرفة نوم في المعادي',
      description: 'تصميم هادئ لغرفة نوم في المعادي.',
      coverPhotoUrl: bedroomImage,
      photoUrls: const [],
      category: 'design',
      apartmentType: 'apartment',
      location: 'المعادي',
      yearCompleted: 2024,
      position: 1,
      createdAt: DateTime.utc(2024, 8, 20),
    ),
  ]);

  static final List<Review> _reviews = _makeReviews();

  static const Map<String, ProfessionalReferenceReviewerMetadata>
  reviewerMetadata = {
    '${idPrefix}review-001': ProfessionalReferenceReviewerMetadata(
      name: 'أحمد محمد',
      sourceName: 'AhmadMohamed',
      avatarPath: ahmadReviewImage,
    ),
    '${idPrefix}review-002': ProfessionalReferenceReviewerMetadata(
      name: 'سارة محمود',
      sourceName: 'SaraMahmoud',
      avatarPath: saraReviewImage,
    ),
  };

  /// Returns a filtered and sorted view of the deterministic 124-row sample.
  /// Its count is illustrative fixture data and is never a production total.
  static List<ContractorListing> list([
    DiscoveryFilters filters = const DiscoveryFilters(),
  ]) {
    final query = filters.searchQuery?.trim().toLowerCase() ?? '';
    final category = filters.rootSpecialty;
    final matches = listings
        .where((listing) {
          if (category != null &&
              !listing.specialties.any((value) => value == category)) {
            return false;
          }
          if (filters.city != null &&
              !listing.serviceAreas.contains(filters.city)) {
            return false;
          }
          if (filters.minimumRating != null &&
              (!listing.hasReviews ||
                  listing.reviewAvg < filters.minimumRating!)) {
            return false;
          }
          if (filters.sort == DiscoverySort.rating && !listing.hasReviews) {
            return false;
          }
          if (query.isNotEmpty) {
            final searchable = [
              listing.businessName,
              listing.fullName,
              listing.headline ?? '',
              ...listing.specialties,
              ...listing.serviceAreas,
            ].join(' ').toLowerCase();
            if (!searchable.contains(query)) return false;
          }
          return true;
        })
        .toList(growable: false);

    matches.sort((a, b) {
      final byName = _listingName(a).compareTo(_listingName(b));
      final byId = a.id.compareTo(b.id);
      return switch (filters.sort) {
        DiscoverySort.name => byName != 0 ? byName : byId,
        DiscoverySort.rating => _compareRatings(a, b, byName, byId),
        DiscoverySort.projects => _compareProjects(a, b, byName, byId),
      };
    });
    return List.unmodifiable(matches);
  }

  static DiscoveryPage page(
    DiscoveryFilters filters, {
    int limit = DiscoveryRepository.pageSize,
    DiscoveryCursor? after,
  }) {
    final boundedLimit = limit.clamp(1, 50).toInt();
    final all = list(filters);
    final cursorIndex = after == null
        ? -1
        : all.indexWhere((listing) => listing.id == after.id);
    final start = cursorIndex < 0 ? 0 : cursorIndex + 1;
    final items = all.skip(start).take(boundedLimit).toList(growable: false);
    final last = items.isEmpty ? null : items.last;
    return DiscoveryPage(
      items: items,
      cursor: last == null
          ? null
          : DiscoveryCursor(
              id: last.id,
              fullName: last.fullName,
              rating: last.reviewAvg,
              ratingCount: last.reviewCount,
              projectsCompleted: last.projectsCompleted,
            ),
      requestedLimit: boundedLimit,
    );
  }

  static List<ContractorListing> sponsored({String? specialty, String? city}) =>
      list(
        DiscoveryFilters(specialty: specialty, city: city),
      ).where((listing) => listing.isSponsored).toList(growable: false);

  static ContractorListing? listingForId(String id) {
    for (final listing in listings) {
      if (listing.id == id) return listing;
    }
    return null;
  }

  static List<PortfolioProject> projectsForId(String id) =>
      id == noorId ? _projects : const <PortfolioProject>[];

  static List<String> galleryMediaForId(String id) =>
      id == noorId ? _noorGalleryMedia : const <String>[];

  static List<Review> reviewsForId(String id) =>
      id == noorId ? _reviews : const <Review>[];

  static ProfessionalReferenceReviewerMetadata? reviewerMetadataForReviewId(
    String reviewId,
  ) => reviewerMetadata[reviewId];

  static ProfessionalReferenceReviewerMetadata? reviewerMetadataForHomeownerId(
    String homeownerId,
  ) {
    for (final entry in reviewerMetadata.entries) {
      final review = _reviews.firstWhere((item) => item.id == entry.key);
      if (review.homeownerId == homeownerId) return entry.value;
    }
    return null;
  }

  static int _compareRatings(
    ContractorListing a,
    ContractorListing b,
    int byName,
    int byId,
  ) {
    final byRating = b.reviewAvg.compareTo(a.reviewAvg);
    if (byRating != 0) return byRating;
    final byCount = b.reviewCount.compareTo(a.reviewCount);
    if (byCount != 0) return byCount;
    return byName != 0 ? byName : byId;
  }

  static int _compareProjects(
    ContractorListing a,
    ContractorListing b,
    int byName,
    int byId,
  ) {
    final byProjects = b.projectsCompleted.compareTo(a.projectsCompleted);
    if (byProjects != 0) return byProjects;
    return byName != 0 ? byName : byId;
  }

  static String _listingName(ContractorListing listing) =>
      (listing.businessName.trim().isNotEmpty
              ? listing.businessName
              : listing.fullName)
          .trim()
          .toLowerCase();

  static ContractorListing _sampleListing(int number) {
    const specialties = [
      'design',
      'full_reno',
      'paint',
      'electrical',
      'plumbing',
      'kitchen',
      'bathroom',
      'carpentry',
    ];
    const areas = [
      'القاهرة الجديدة',
      'المعادي',
      'مدينة نصر',
      '٦ أكتوبر',
      'الجيزة',
      'الإسكندرية',
    ];
    const providerKinds = [
      ProviderKind.interiorDesigner,
      ProviderKind.contractor,
      ProviderKind.engineer,
      ProviderKind.tradesman,
      ProviderKind.specializedProvider,
    ];

    final index = number - 2;
    final reviewCount = index % 7 == 0 ? 0 : 5 + (index % 28);
    final rating = reviewCount == 0 ? 0.0 : 4.1 + ((index * 3) % 9) / 10;
    final displayNumber = number.toString().padLeft(3, '0');
    final name = 'ورشة تجريبية $displayNumber';
    final specialty = specialties[index % specialties.length];
    final area = areas[index % areas.length];
    return ContractorListing(
      id: '$idPrefix${number.toString().padLeft(3, '0')}',
      fullName: name,
      businessName: name,
      specialties: [specialty],
      serviceAreas: [area, areas[(index + 2) % areas.length]],
      projectsCompleted: 2 + ((index * 7) % 79),
      headline: specialty,
      coverPhotoUrl: number == 2 ? bathroomImage : null,
      yearsExperience: 1 + (index % 19),
      reviewCount: reviewCount,
      reviewAvg: rating,
      verified: number % 5 == 0,
      plan: 'free',
      isSponsored: number == 2,
      memberSince: DateTime.utc(2020 + (index % 6), 1 + (index % 12), 1),
      providerKind: providerKinds[index % providerKinds.length],
    );
  }

  static List<Review> _makeReviews() => List.unmodifiable([
    for (var index = 0; index < 186; index++)
      Review(
        id: '${idPrefix}review-${(index + 1).toString().padLeft(3, '0')}',
        briefId: '${idPrefix}brief-${(index + 1).toString().padLeft(3, '0')}',
        contractorId: noorId,
        homeownerId: switch (index) {
          0 => '${idPrefix}homeowner-ahmad-mohamed',
          1 => '${idPrefix}homeowner-sara-mahmoud',
          _ => '${idPrefix}homeowner-${(index + 1).toString().padLeft(3, '0')}',
        },
        rating: index < 169
            ? 5
            : index < 185
            ? 4
            : 3,
        comment: switch (index) {
          0 => 'التزام بالمواعيد وتصميم رائع، أنصح بالتعامل معهم.',
          1 => 'متابعة ممتازة واهتمام بكل التفاصيل.',
          _ => null,
        },
        createdAt: switch (index) {
          0 => DateTime.utc(2026, 9, 20),
          1 => DateTime.utc(2026, 9, 12),
          _ => DateTime.utc(
            2026,
            9,
            6,
          ).subtract(Duration(days: (index - 2) * 3)),
        },
      ),
  ]);
}

class ProfessionalReferenceReviewerMetadata {
  const ProfessionalReferenceReviewerMetadata({
    required this.name,
    required this.sourceName,
    required this.avatarPath,
  });

  final String name;
  final String sourceName;
  final String avatarPath;
}

/// Discovery reads are fully served from the fixture and deliberately skip
/// the production repository's search analytics call.
class ProfessionalReferenceDiscoveryRepository extends DiscoveryRepository {
  ProfessionalReferenceDiscoveryRepository(super.client);

  @override
  Future<DiscoveryPage> fetchContractorsPage(
    DiscoveryFilters filters, {
    int limit = DiscoveryRepository.pageSize,
    DiscoveryCursor? after,
  }) async =>
      ProfessionalReferenceFixture.page(filters, limit: limit, after: after);

  @override
  Future<DiscoveryPage> fetchTopRatedPage({
    int limit = DiscoveryRepository.pageSize,
    DiscoveryCursor? after,
  }) async => ProfessionalReferenceFixture.page(
    const DiscoveryFilters(sort: DiscoverySort.rating),
    limit: limit,
    after: after,
  );

  @override
  Future<List<ContractorListing>> fetchSponsoredProfessionals({
    String? specialty,
    String? city,
  }) async =>
      ProfessionalReferenceFixture.sponsored(specialty: specialty, city: city);

  @override
  Future<ContractorListing?> fetchContractor(String id) async =>
      ProfessionalReferenceFixture.listingForId(id);
}

/// Portfolio read paths used by the profile and its existing destinations.
class ProfessionalReferencePortfolioRepository extends PortfolioRepository {
  ProfessionalReferencePortfolioRepository(super.client);

  @override
  Future<List<PortfolioProject>> fetchForContractor(
    String contractorId,
  ) async => ProfessionalReferenceFixture.projectsForId(contractorId);

  @override
  Future<List<PortfolioProject>> fetchRecent({int limit = 12}) async =>
      ProfessionalReferenceFixture.projectsForId(
        ProfessionalReferenceFixture.noorId,
      ).take(limit).toList(growable: false);

  @override
  Future<List<PortfolioProject>> fetchRecentPage({
    PortfolioCursor? after,
    int limit = 12,
  }) async {
    final projects = ProfessionalReferenceFixture.projectsForId(
      ProfessionalReferenceFixture.noorId,
    );
    final index = after == null
        ? -1
        : projects.indexWhere((project) => project.id == after.id);
    return projects.skip(index < 0 ? 0 : index + 1).take(limit).toList();
  }

  @override
  Future<PortfolioProject?> fetchById(String projectId) async {
    for (final project in ProfessionalReferenceFixture.projectsForId(
      ProfessionalReferenceFixture.noorId,
    )) {
      if (project.id == projectId) return project;
    }
    return null;
  }

  @override
  Future<bool> isProjectSaved(String projectId) async => false;

  @override
  Future<void> saveProject(String projectId) async {}

  @override
  Future<void> unsaveProject(String projectId) async {}
}

/// Review reads use the complete deterministic sample, preserving its exact
/// 169/16/1/0/0 distribution. Writes are rejected before a client is touched.
class ProfessionalReferenceReviewsRepository extends ReviewsRepository {
  ProfessionalReferenceReviewsRepository(super.client);

  @override
  Future<Review?> fetchForBrief(String briefId) async => null;

  @override
  Future<List<Review>> fetchForContractor(String contractorId) async =>
      ProfessionalReferenceFixture.reviewsForId(contractorId);

  @override
  Future<Review> submit({
    required String briefId,
    required String contractorId,
    required int rating,
    String? comment,
  }) => Future.error(
    UnsupportedError('Reviews cannot be submitted from the reference fixture.'),
  );
}

/// The saved repository cannot make network reads or writes in fixture mode.
/// Saved contractor IDs are instead owned by a Riverpod in-memory store.
class ProfessionalReferenceSavedRepository extends SavedRepository {
  ProfessionalReferenceSavedRepository(super.client);

  @override
  Future<SavedPage> fetchSavedPage(
    String homeownerId, {
    SavedCursor? after,
    int limit = SavedRepository.pageSize,
  }) async => SavedPage(
    items: const [],
    cursor: null,
    requestedLimit: limit.clamp(1, 50).toInt(),
  );

  @override
  Future<Set<String>> fetchSavedIds(String homeownerId) async => <String>{};

  @override
  Future<List<ContractorListing>> fetchSavedListings(
    String homeownerId,
  ) async => const [];

  @override
  Future<void> save({
    required String homeownerId,
    required String contractorId,
  }) async {}

  @override
  Future<void> unsave({
    required String homeownerId,
    required String contractorId,
  }) async {}
}

/// Shared only by discovery and public profile while the standalone fixture
/// entry point is active. It is never persisted and sends no analytics.
final professionalReferenceSavedIdsProvider =
    NotifierProvider<ProfessionalReferenceSavedIdsController, Set<String>>(
      ProfessionalReferenceSavedIdsController.new,
    );

class ProfessionalReferenceSavedIdsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String contractorId) {
    if (!ProfessionalReferenceFixture.isFixtureId(contractorId)) return;
    final next = {...state};
    if (!next.add(contractorId)) next.remove(contractorId);
    state = next;
  }
}
