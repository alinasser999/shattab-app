/// Local-only repositories for the empty-state development entry point.
/// The transport rejects every request, including any accidental inherited
/// repository method. No real credential or server session is installed.
library;

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/profile.dart';
import '../../briefs/data/briefs_repository.dart';
import '../../briefs/domain/brief.dart';
import '../../discovery/data/discovery_repository.dart';
import '../../discovery/domain/contractor_listing.dart';
import '../../explore/data/post_repository.dart';
import '../../explore/domain/post.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/domain/app_notification.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../../portfolio/domain/portfolio_project.dart';
import '../../quotes/data/quotes_repository.dart';
import '../../quotes/domain/quote.dart';
import '../../reviews/data/reviews_repository.dart';
import '../../reviews/domain/review.dart';
import '../../saved/data/saved_repository.dart';

class EmptyReferenceFixture {
  EmptyReferenceFixture(this.scene, {this.contractorRole}) {
    if (scene == 'A4') {
      professional = const ContractorProfile(
        profileId: userId,
        providerKind: ProviderKind.finishingCompany,
      );
    }
  }
  final String scene;
  final bool? contractorRole;
  final actions = <String>[];
  bool readFailed = false;
  int _readAttempts = 0;
  bool _writeFailed = false;
  static const userId = 'empty-reference-user';
  static const contractorId = 'empty-reference-professional';
  bool get guest => scene == 'B4' || scene == 'signin';
  bool get contractor =>
      contractorRole ?? ['A4', 'A5', 'A6', 'B7', 'C4', 'C5'].contains(scene);
  bool get readFailure => scene == 'C1' || scene == 'C2';
  bool get writeFailure => scene == 'C4';
  Profile get profile => Profile(
    id: userId,
    role: contractor ? UserRole.contractor : UserRole.homeowner,
    roleSelectionLocked: scene != 'A1',
    fullName: scene == 'C3' || scene == 'A1' ? '' : 'حساب المعاينة',
    phone: '',
    onboardingComplete: !scene.startsWith('A'),
  );
  Session get session => Session(
    accessToken: 'local-fixture-placeholder',
    refreshToken: 'local-fixture-placeholder',
    tokenType: 'bearer',
    user: const User(
      id: userId,
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-10-05T00:00:00Z',
    ),
  );
  HomeownerProfile homeowner = const HomeownerProfile(profileId: userId);
  ContractorProfile professional = const ContractorProfile(
    profileId: userId,
    businessName: 'اسم الشركة',
    providerKind: ProviderKind.finishingCompany,
  );
  static const listing = ContractorListing(
    id: contractorId,
    fullName: 'حساب مهني للمعاينة',
    businessName: 'تشطيبات',
    specialties: ['painting'],
    serviceAreas: ['القاهرة'],
    projectsCompleted: 0,
  );
  Brief get brief => Brief(
    id: 'empty-reference-brief',
    homeownerId: userId,
    apartmentType: ApartmentType.twoBedroom,
    city: 'القاهرة',
    workDescription: 'تجديد الشقة',
    photoUrls: const [],
    targetSpecialties: const ['painting'],
    status: BriefStatus.open,
    createdAt: DateTime.utc(2026, 10, 4),
    projectTitle: 'مشروع تجديد الشقة',
  );
  void record(String action) => actions.add(action);
  void read(String action) {
    record(action);
    // Discovery's bounded retry policy makes three attempts. The next manual
    // retry succeeds, so its actual retry callback can demonstrate recovery.
    if (readFailure && _readAttempts++ < 3) {
      if (scene == 'C2') throw const SocketException('Local offline fixture');
      throw StateError('Local read failure fixture');
    }
    readFailed = readFailure;
  }

  void write(String action) {
    record(action);
    if (writeFailure && !_writeFailed) {
      _writeFailed = true;
      throw StateError('Local save failure fixture');
    }
  }
}

class EmptyReferenceTransport extends http.BaseClient {
  EmptyReferenceTransport(this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    fixture.record('blocked transport: ${request.method} ${request.url.path}');
    throw StateError('Network is disabled in the empty-state fixture.');
  }
}

class EmptyReferenceAuthRepository extends AuthRepository {
  EmptyReferenceAuthRepository(super.client, this.fixture);
  final EmptyReferenceFixture fixture;
  Profile? selected;
  @override
  Future<Profile?> fetchProfile(String userId) async {
    fixture.record('fetchProfile');
    return fixture.guest ? null : selected ?? fixture.profile;
  }

  @override
  Session? get currentSession => fixture.guest ? null : fixture.session;
  @override
  Stream<AuthState> watchAuthState() =>
      Stream.value(AuthState(AuthChangeEvent.initialSession, currentSession));
  @override
  Future<void> selectOnboardingRole({
    required UserRole role,
    required String fullName,
  }) async {
    fixture.write('selectRole:$role');
    selected = fixture.profile.copyWith(
      role: role,
      fullName: fullName,
      roleSelectionLocked: true,
    );
  }

  @override
  Future<void> sendOtp(String phone) async {
    fixture.record('sendOtp');
    throw const AuthException('Local sign-in failure fixture');
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String code,
  }) async {
    fixture.record('verifyOtp');
    throw const AuthException('Local code verification failure fixture');
  }

  @override
  Future<bool> signInWithGoogle() async => false;
  @override
  Future<bool> signInWithApple() async => false;
}

class EmptyReferenceOnboardingRepository extends OnboardingRepository {
  EmptyReferenceOnboardingRepository(super.client, this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  Future<HomeownerProfile?> fetchHomeowner(String profileId) async =>
      fixture.homeowner;
  @override
  Future<ContractorProfile?> fetchContractor(String profileId) async =>
      fixture.professional;
  @override
  Future<void> updateFullName({
    required String profileId,
    required String fullName,
  }) async => fixture.write('updateFullName');
  @override
  Future<void> upsertHomeowner({
    required String profileId,
    ApartmentType? apartmentType,
    String? city,
    String? district,
    List<String>? renovationInterests,
  }) async {
    fixture.write('upsertHomeowner');
    fixture.homeowner = fixture.homeowner.copyWith(
      apartmentType: apartmentType,
      city: city,
      district: district,
      renovationInterests: renovationInterests,
    );
  }

  @override
  Future<void> upsertContractor({
    required String profileId,
    String? businessName,
    String? logoUrl,
    String? coverPhotoUrl,
    String? headline,
    String? bio,
    List<String>? specialties,
    List<String>? serviceAreas,
    int? yearsExperience,
    ProviderKind? providerKind,
  }) async {
    fixture.write('upsertContractor');
    fixture.professional = fixture.professional.copyWith(
      businessName: businessName,
      logoUrl: logoUrl,
      bio: bio,
      specialties: specialties,
      serviceAreas: serviceAreas,
      yearsExperience: yearsExperience,
      providerKind: providerKind,
    );
  }

  @override
  Future<bool> markOnboardingComplete() async {
    fixture.write('markComplete');
    return true;
  }

  @override
  Future<String> uploadContractorLogo({
    required String profileId,
    required File file,
  }) async {
    fixture.record('uploadLogo');
    throw StateError('Local logo upload failure fixture');
  }
}

class EmptyReferenceDiscoveryRepository extends DiscoveryRepository {
  EmptyReferenceDiscoveryRepository(super.client, this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  Future<DiscoveryPage> fetchContractorsPage(
    DiscoveryFilters filters, {
    int limit = DiscoveryRepository.pageSize,
    DiscoveryCursor? after,
  }) async {
    fixture.read('directory:${filters.searchQuery ?? "all"}');
    return DiscoveryPage(items: const [], cursor: null, requestedLimit: limit);
  }

  @override
  Future<DiscoveryPage> fetchTopRatedPage({
    int limit = DiscoveryRepository.pageSize,
    DiscoveryCursor? after,
  }) async =>
      DiscoveryPage(items: const [], cursor: null, requestedLimit: limit);
  @override
  Future<List<ContractorListing>> fetchSponsoredProfessionals({
    String? specialty,
    String? city,
  }) async => const [];
  @override
  Future<ContractorListing?> fetchContractor(String id) async =>
      EmptyReferenceFixture.listing;
}

class EmptyReferenceBriefsRepository extends BriefsRepository {
  EmptyReferenceBriefsRepository(super.client, this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  Future<List<Brief>> fetchMine(String homeownerId) async {
    fixture.record('myBriefs');
    return fixture.scene == 'B2' ? [fixture.brief] : [];
  }

  @override
  Future<Brief?> fetchById(String id) async => fixture.brief;
}

class EmptyReferenceQuotesRepository extends QuotesRepository {
  EmptyReferenceQuotesRepository(super.client, this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  Future<List<Quote>> fetchForBrief(String briefId) async {
    fixture.record('quotesForBrief:$briefId');
    return const [];
  }
}

class EmptyReferencePortfolioRepository extends PortfolioRepository {
  EmptyReferencePortfolioRepository(super.client, this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  Future<List<PortfolioProject>> fetchForContractor(String contractorId) async {
    fixture.record('portfolio:$contractorId');
    return const [];
  }

  @override
  Future<List<PortfolioProject>> fetchRecent({int limit = 12}) async =>
      const [];
}

class EmptyReferenceReviewsRepository extends ReviewsRepository {
  EmptyReferenceReviewsRepository(super.client, this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  Future<List<Review>> fetchForContractor(String contractorId) async {
    fixture.record('reviews:$contractorId');
    return const [];
  }
}

class EmptyReferenceSavedRepository extends SavedRepository {
  EmptyReferenceSavedRepository(super.client, this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  Future<SavedPage> fetchSavedPage(
    String homeownerId, {
    SavedCursor? after,
    int limit = SavedRepository.pageSize,
  }) async => SavedPage(items: const [], cursor: null, requestedLimit: limit);
  @override
  Future<Set<String>> fetchSavedIds(String homeownerId) async => {};
  @override
  Future<void> save({
    required String homeownerId,
    required String contractorId,
  }) async => fixture.record('save:$contractorId');
  @override
  Future<void> unsave({
    required String homeownerId,
    required String contractorId,
  }) async => fixture.record('unsave:$contractorId');
}

class EmptyReferenceNotificationsRepository extends NotificationsRepository {
  EmptyReferenceNotificationsRepository(super.client, this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  Stream<List<AppNotification>> watchMine({int limit = 50}) {
    fixture.record('notifications');
    return Stream.value(const []);
  }

  @override
  Future<void> markAllRead() async => fixture.record('markAllRead');
  @override
  Future<void> markRead(String id) async => fixture.record('markRead:$id');
}

class EmptyReferencePostRepository extends PostRepository {
  EmptyReferencePostRepository(super.client, this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  Future<List<Post>> fetchFeed({
    required String userId,
    int limit = 10,
    DateTime? beforeCreatedAt,
    String? beforeId,
  }) async {
    fixture.record('communityFeed');
    return const [];
  }
}
