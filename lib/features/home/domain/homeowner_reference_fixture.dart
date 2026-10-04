import 'package:flutter_riverpod/misc.dart' show Override;
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/connectivity.dart';
import '../../auth/domain/profile.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../briefs/domain/brief.dart';
import '../../briefs/presentation/providers/briefs_providers.dart';
import '../../contact_followup/presentation/providers/professional_contact_providers.dart';
import '../../discovery/data/discovery_repository.dart';
import '../../discovery/domain/contractor_listing.dart';
import '../../discovery/domain/professional_reference_fixture.dart';
import '../../discovery/presentation/providers/discovery_providers.dart';
import '../../explore/domain/post.dart';
import '../../explore/presentation/providers/explore_providers.dart';
import '../../notifications/domain/app_notification.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/providers/onboarding_draft_provider.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../../portfolio/domain/portfolio_project.dart';
import '../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../quotes/domain/quote.dart';
import '../../quotes/presentation/providers/quotes_providers.dart';
import '../../reviews/data/reviews_repository.dart';
import '../../saved/data/saved_repository.dart';
import '../../saved/presentation/providers/saved_providers.dart';

/// Scenarios accepted by the separate homeowner reference entry point.
enum HomeownerReferenceScenarioKind {
  home,
  noactive,
  active,
  onboarding1,
  onboarding2,
  onboarding3,
  error,
  loading,
}

/// Local state for a deterministic rendering of the real homeowner screens.
///
/// Every provider watched by [HomeownerHomeScreen] and the onboarding screens
/// is replaced with a local value or an in-memory controller. No repository
/// used by those screens can reach the Supabase client.
class HomeownerReferenceScenario {
  HomeownerReferenceScenario._({
    required this.kind,
    required this.textScale,
    required this.profile,
    required this.homeownerProfile,
    required this.initialDraft,
    required this.notificationStateOverride,
    required this.failFirstSave,
    required this.saveDelayMillis,
  });

  static const _fixtureHomeownerId = 'fixture-homeowner-001';

  final HomeownerReferenceScenarioKind kind;
  final double textScale;
  final OnboardingDraft initialDraft;
  final String? notificationStateOverride;
  final bool failFirstSave;
  final int saveDelayMillis;
  final Set<String> savedProfessionalIds = <String>{};
  bool _didInjectSaveFailure = false;
  late final List<Brief> localBriefs = List<Brief>.unmodifiable([
    _openBrief,
    _completedBrief,
    _awaitingCompletionBrief,
    _hiredBrief,
  ]);

  Profile profile;
  HomeownerProfile? homeownerProfile;

  bool get isOnboarding => switch (kind) {
    HomeownerReferenceScenarioKind.onboarding1 ||
    HomeownerReferenceScenarioKind.onboarding2 ||
    HomeownerReferenceScenarioKind.onboarding3 => true,
    _ => false,
  };

  String get initialLocation => switch (kind) {
    HomeownerReferenceScenarioKind.onboarding1 => '/onboarding/role-select',
    HomeownerReferenceScenarioKind.onboarding2 =>
      '/onboarding/homeowner/details',
    HomeownerReferenceScenarioKind.onboarding3 =>
      '/onboarding/homeowner/location',
    _ => '/h/home',
  };

  bool containsBrief(String id) => localBriefs.any((brief) => brief.id == id);

  /// Reads `scenario` and `textScale` from the fixture URL query.
  factory HomeownerReferenceScenario.fromUri(Uri uri) {
    final requested = uri.queryParameters['scenario'] ?? 'home';
    final kind = HomeownerReferenceScenarioKind.values.firstWhere(
      (value) => value.name == requested,
      orElse: () => throw FormatException(
        'Unknown homeowner reference scenario "$requested". Use one of: '
        '${HomeownerReferenceScenarioKind.values.map((value) => value.name).join(', ')}.',
      ),
    );
    final requestedScale = double.tryParse(
      uri.queryParameters['textScale'] ?? '1',
    );
    final notificationStateOverride = uri.queryParameters['notificationState'];
    if (notificationStateOverride != null &&
        !const {
          'loading',
          'error',
          'empty',
          'success',
        }.contains(notificationStateOverride)) {
      throw FormatException(
        'Unknown notificationState "$notificationStateOverride". Use '
        'loading, error, empty, or success.',
      );
    }
    final saveFailure = uri.queryParameters['saveFailure'];
    if (saveFailure != null && saveFailure != 'once') {
      throw FormatException('saveFailure accepts only "once".');
    }
    final failOnceValue = uri.queryParameters['failOnce'];
    if (failOnceValue != null &&
        failOnceValue != 'true' &&
        failOnceValue != 'false') {
      throw FormatException('failOnce accepts only "true" or "false".');
    }
    final blankValue = uri.queryParameters['blank'];
    if (blankValue != null && blankValue != 'true' && blankValue != 'false') {
      throw FormatException('blank accepts only "true" or "false".');
    }
    final requestedSaveDelay = int.tryParse(
      uri.queryParameters['saveDelay'] ?? '0',
    );
    if (requestedSaveDelay == null ||
        requestedSaveDelay < 0 ||
        requestedSaveDelay > 3000) {
      throw FormatException('saveDelay must be a number from 0 to 3000 ms.');
    }
    final blank =
        blankValue == 'true' &&
        kind == HomeownerReferenceScenarioKind.onboarding1;
    final textScale =
        requestedScale != null && requestedScale.isFinite && requestedScale > 0
        ? requestedScale
        : 1.0;

    final isOnboarding = switch (kind) {
      HomeownerReferenceScenarioKind.onboarding1 ||
      HomeownerReferenceScenarioKind.onboarding2 ||
      HomeownerReferenceScenarioKind.onboarding3 => true,
      _ => false,
    };
    final name = isOnboarding ? (blank ? '' : 'أحمد محمد') : 'مريم أحمد';
    final profile = Profile(
      id: _fixtureHomeownerId,
      role: UserRole.homeowner,
      roleSelectionLocked: !blank,
      fullName: name,
      phone: '',
      onboardingComplete: !isOnboarding,
    );

    final initialDraft = _draftFor(kind, name, blank: blank);
    return HomeownerReferenceScenario._(
      kind: kind,
      textScale: textScale,
      profile: profile,
      homeownerProfile: _homeownerProfileFor(kind),
      initialDraft: initialDraft,
      notificationStateOverride: notificationStateOverride,
      failFirstSave: failOnceValue == 'true' || saveFailure == 'once',
      saveDelayMillis: requestedSaveDelay,
    );
  }

  List<Brief> get briefs => switch (kind) {
    HomeownerReferenceScenarioKind.noactive => [localBriefs[1]],
    HomeownerReferenceScenarioKind.active => localBriefs.skip(1).toList(),
    HomeownerReferenceScenarioKind.home => [localBriefs.first],
    _ => const <Brief>[],
  };

  List<ContractorListing> get featuredListings =>
      ProfessionalReferenceFixture.listings.take(3).toList(growable: false);

  List<ContractorListing> get topRatedListings =>
      ProfessionalReferenceFixture.page(
        const DiscoveryFilters(sort: DiscoverySort.rating),
        limit: 50,
      ).items;

  List<PortfolioProject> get workProjects =>
      ProfessionalReferenceFixture.projectsForId(
        ProfessionalReferenceFixture.noorId,
      );

  List<Post> get communityPosts => [
    Post(
      id: 'fixture-homeowner-post-001',
      authorId: 'fixture-community-member-001',
      authorRole: 'homeowner',
      postType: PostType.tip,
      caption: 'تجربتي التجريبية في اختيار ألوان المطبخ.',
      createdAt: DateTime.utc(2026, 9, 28),
      likeCount: 8,
      commentCount: 2,
      authorName: 'عضوة تجريبية',
      city: 'القاهرة الجديدة',
    ),
  ];

  List<AppNotification> get notifications => [
    AppNotification(
      id: 'fixture-notification-001',
      kind: 'new_quote',
      titleKey: 'notificationNewQuoteTitle',
      bodyKey: 'notificationNewQuoteBody',
      createdAt: DateTime.utc(2026, 10, 2, 12),
      entityType: 'brief',
      entityId: _openBrief.id,
    ),
  ];

  List<Override> buildProviderOverrides(SupabaseClient localClient) {
    final overrides = <Override>[
      currentSessionProvider.overrideWithValue(_fixtureSession),
      currentProfileProvider.overrideWith(() => _FixtureCurrentProfile(this)),
      professionalContactEpisodeProvider.overrideWith((_) async => null),
      homeownerProfileProvider.overrideWith((_) async => homeownerProfile),
      contractorProfileProvider.overrideWith((_) async => null),
      myBriefsProvider.overrideWith((_) => _loadBriefs()),
      briefsControllerProvider.overrideWith(_FixtureBriefsController.new),
      quotesControllerProvider.overrideWith(_FixtureQuotesController.new),
      discoveryRepositoryProvider.overrideWithValue(
        ProfessionalReferenceDiscoveryRepository(localClient),
      ),
      portfolioRepositoryProvider.overrideWithValue(
        ProfessionalReferencePortfolioRepository(localClient),
      ),
      reviewsRepositoryProvider.overrideWithValue(
        ProfessionalReferenceReviewsRepository(localClient),
      ),
      savedRepositoryProvider.overrideWithValue(
        ProfessionalReferenceSavedRepository(localClient),
      ),
      if (kind == HomeownerReferenceScenarioKind.error ||
          kind == HomeownerReferenceScenarioKind.loading)
        discoverContractorsProvider.overrideWith(
          () => _FixtureDiscoverContractors(this),
        ),
      topRatedProfessionalsProvider.overrideWith(
        () => _FixtureTopRatedProfessionals(this),
      ),
      recentProjectsProvider.overrideWith((_) => _loadWorkProjects()),
      exploreFeedProvider.overrideWithValue(_communityState),
      savedContractorIdsProvider.overrideWith(
        (_) async => Set<String>.unmodifiable(savedProfessionalIds),
      ),
      savedControllerProvider.overrideWith(() => _FixtureSavedController(this)),
      notificationsProvider.overrideWith((_) => _notificationStream()),
      connectivityProvider.overrideWith((_) => Stream<bool>.value(true)),
      onboardingDraftProvider.overrideWith(
        () => _FixtureOnboardingDraft(initialDraft),
      ),
      onboardingControllerProvider.overrideWith(
        () => _FixtureOnboardingController(this),
      ),
    ];

    for (final listing in ProfessionalReferenceFixture.listings) {
      overrides.add(
        portfolioForContractorProvider(listing.id).overrideWith(
          (_) async => ProfessionalReferenceFixture.projectsForId(listing.id),
        ),
      );
    }
    for (final brief in localBriefs) {
      overrides.add(
        briefByIdProvider(brief.id).overrideWith((_) async => brief),
      );
      overrides.add(
        quotesForBriefProvider(brief.id).overrideWith(
          (_) async => brief.id == _openBrief.id ? _fixtureQuotes : const [],
        ),
      );
    }
    return overrides;
  }

  AsyncValue<List<Post>> get _communityState => switch (kind) {
    HomeownerReferenceScenarioKind.error => AsyncError(
      StateError('fixture community source error'),
      StackTrace.current,
    ),
    HomeownerReferenceScenarioKind.loading => const AsyncLoading(),
    _ => AsyncData(communityPosts),
  };

  Future<List<Brief>> _loadBriefs() async {
    if (kind == HomeownerReferenceScenarioKind.loading) {
      return Completer<List<Brief>>().future;
    }
    if (kind == HomeownerReferenceScenarioKind.error) {
      throw StateError('fixture brief source error');
    }
    return briefs;
  }

  Future<List<PortfolioProject>> _loadWorkProjects() async {
    if (kind == HomeownerReferenceScenarioKind.loading) {
      return Completer<List<PortfolioProject>>().future;
    }
    if (kind == HomeownerReferenceScenarioKind.error) {
      throw StateError('fixture work source error');
    }
    return workProjects;
  }

  Future<List<ContractorListing>> _loadProfessionals({
    required bool topRated,
  }) async {
    if (kind == HomeownerReferenceScenarioKind.loading) {
      return Completer<List<ContractorListing>>().future;
    }
    if (kind == HomeownerReferenceScenarioKind.error) {
      throw StateError('fixture professional source error');
    }
    return topRated ? topRatedListings : featuredListings;
  }

  Stream<List<AppNotification>> _notificationStream() {
    final state = notificationStateOverride;
    if (state == 'loading' ||
        (state == null && kind == HomeownerReferenceScenarioKind.loading)) {
      return Stream<List<AppNotification>>.multi((_) {});
    }
    if (state == 'error' ||
        (state == null && kind == HomeownerReferenceScenarioKind.error)) {
      return Stream<List<AppNotification>>.error(
        StateError('fixture notifications source error'),
      );
    }
    if (state == 'empty') {
      return Stream<List<AppNotification>>.value(const []);
    }
    if (state == 'success') return Stream.value(notifications);
    if (kind == HomeownerReferenceScenarioKind.noactive) {
      return Stream.value(notifications);
    }
    return Stream<List<AppNotification>>.value(const <AppNotification>[]);
  }

  Future<void> beforeOnboardingSave() async {
    if (saveDelayMillis > 0) {
      await Future<void>.delayed(Duration(milliseconds: saveDelayMillis));
    }
    if (!failFirstSave || _didInjectSaveFailure) return;
    _didInjectSaveFailure = true;
    throw StateError('fixture save failed once');
  }

  static final Session _fixtureSession = Session(
    accessToken: 'homeowner-reference-memory-session',
    refreshToken: 'homeowner-reference-memory-refresh',
    tokenType: 'bearer',
    user: const User(
      id: _fixtureHomeownerId,
      appMetadata: {},
      userMetadata: null,
      aud: 'authenticated',
      createdAt: '2026-10-03T00:00:00.000Z',
      phone: '+201000000000',
    ),
  );

  static OnboardingDraft _draftFor(
    HomeownerReferenceScenarioKind kind,
    String name, {
    bool blank = false,
  }) {
    final base = OnboardingDraft(
      accountId: _fixtureHomeownerId,
      role: blank ? null : UserRole.homeowner,
      fullName: name,
      fullNameEdited: true,
    );
    return switch (kind) {
      HomeownerReferenceScenarioKind.onboarding2 => base.copyWith(
        apartmentType: ApartmentType.twoBedroom,
        renovationInterests: const {'design'},
        homeownerDetailsEdited: true,
      ),
      HomeownerReferenceScenarioKind.onboarding3 => base.copyWith(
        apartmentType: ApartmentType.twoBedroom,
        renovationInterests: const {'design'},
        homeownerDetailsEdited: true,
        city: 'القاهرة الجديدة',
        clearDistrict: true,
        homeownerLocationEdited: true,
      ),
      _ => base,
    };
  }

  static HomeownerProfile? _homeownerProfileFor(
    HomeownerReferenceScenarioKind kind,
  ) => switch (kind) {
    HomeownerReferenceScenarioKind.onboarding2 => const HomeownerProfile(
      profileId: _fixtureHomeownerId,
    ),
    HomeownerReferenceScenarioKind.onboarding3 => const HomeownerProfile(
      profileId: _fixtureHomeownerId,
      apartmentType: ApartmentType.twoBedroom,
      renovationInterests: ['design'],
    ),
    HomeownerReferenceScenarioKind.home ||
    HomeownerReferenceScenarioKind.noactive ||
    HomeownerReferenceScenarioKind.active => const HomeownerProfile(
      profileId: _fixtureHomeownerId,
      apartmentType: ApartmentType.twoBedroom,
      city: 'القاهرة الجديدة',
      district: 'التجمع الخامس',
      renovationInterests: ['design'],
    ),
    _ => null,
  };

  static final DateTime _createdAt = DateTime.utc(2026, 9, 20);

  static Brief get _openBrief => Brief(
    id: 'fixture-homeowner-brief-open',
    homeownerId: _fixtureHomeownerId,
    apartmentType: ApartmentType.twoBedroom,
    city: 'القاهرة الجديدة',
    district: 'التجمع الخامس',
    workDescription: 'تجديد مطبخ الشقة وتجهيز وحدات التخزين.',
    projectTitle: 'تجديد المطبخ',
    photoUrls: const [],
    targetSpecialties: const ['kitchen'],
    status: BriefStatus.open,
    createdAt: _createdAt,
  );

  static Brief get _completedBrief => Brief(
    id: 'fixture-homeowner-brief-completed',
    homeownerId: _fixtureHomeownerId,
    apartmentType: ApartmentType.oneBedroom,
    city: 'القاهرة الجديدة',
    district: 'الرحاب',
    workDescription: 'مشروع تجريبي اكتمل سابقاً.',
    photoUrls: const [],
    targetSpecialties: const ['design'],
    status: BriefStatus.open,
    createdAt: _createdAt.subtract(const Duration(days: 40)),
    hiredAt: _createdAt.subtract(const Duration(days: 35)),
    completedAt: _createdAt.subtract(const Duration(days: 5)),
  );

  static Brief get _awaitingCompletionBrief => Brief(
    id: 'fixture-homeowner-brief-awaiting-completion',
    homeownerId: _fixtureHomeownerId,
    apartmentType: ApartmentType.twoBedroom,
    city: 'القاهرة الجديدة',
    district: 'التجمع الخامس',
    workDescription: 'مراجعة تشطيب غرفة المعيشة قبل تأكيد الاكتمال.',
    photoUrls: const [],
    targetSpecialties: const ['full_reno'],
    status: BriefStatus.open,
    createdAt: _createdAt.subtract(const Duration(days: 14)),
    hiredAt: _createdAt.subtract(const Duration(days: 12)),
    completionRequestedAt: _createdAt.subtract(const Duration(days: 1)),
  );

  static Brief get _hiredBrief => Brief(
    id: 'fixture-homeowner-brief-hired',
    homeownerId: _fixtureHomeownerId,
    apartmentType: ApartmentType.studio,
    city: 'المعادي',
    district: 'المعادي',
    workDescription: 'متابعة عمل تجريبي جارٍ.',
    photoUrls: const [],
    targetSpecialties: const ['paint'],
    status: BriefStatus.open,
    createdAt: _createdAt.subtract(const Duration(days: 8)),
    hiredAt: _createdAt.subtract(const Duration(days: 6)),
  );

  static final List<Quote> _fixtureQuotes = [
    Quote(
      id: 'fixture-homeowner-quote-sent',
      briefId: 'fixture-homeowner-brief-open',
      contractorId: 'reference-professional-002',
      note: 'عرض تجريبي للمراجعة البصرية.',
      status: QuoteStatus.sent,
      createdAt: DateTime.utc(2026, 9, 21),
      updatedAt: DateTime.utc(2026, 9, 21),
    ),
    Quote(
      id: 'fixture-homeowner-quote-withdrawn',
      briefId: 'fixture-homeowner-brief-open',
      contractorId: 'reference-professional-003',
      note: 'عرض تجريبي منسحب.',
      status: QuoteStatus.withdrawn,
      createdAt: DateTime.utc(2026, 9, 22),
      updatedAt: DateTime.utc(2026, 9, 23),
    ),
  ];
}

class _FixtureCurrentProfile extends CurrentProfile {
  _FixtureCurrentProfile(this.fixture);

  final HomeownerReferenceScenario fixture;

  @override
  Future<Profile?> build() async => fixture.profile;

  @override
  Future<void> refresh() async {
    state = AsyncData(fixture.profile);
  }
}

class _FixtureDiscoverContractors extends DiscoverContractors {
  _FixtureDiscoverContractors(this.fixture);

  final HomeownerReferenceScenario fixture;

  @override
  Future<List<ContractorListing>> build() =>
      fixture._loadProfessionals(topRated: false);
}

class _FixtureTopRatedProfessionals extends TopRatedProfessionals {
  _FixtureTopRatedProfessionals(this.fixture);

  final HomeownerReferenceScenario fixture;

  @override
  Future<List<ContractorListing>> build() =>
      fixture._loadProfessionals(topRated: true);
}

class _FixtureOnboardingDraft extends OnboardingDraftController {
  _FixtureOnboardingDraft(this.initial);

  final OnboardingDraft initial;

  @override
  OnboardingDraft build() => initial;
}

class _FixtureOnboardingController extends OnboardingController {
  _FixtureOnboardingController(this.fixture);

  final HomeownerReferenceScenario fixture;

  @override
  Future<void> selectRole(UserRole role, String fullName) async {
    fixture.profile = fixture.profile.copyWith(
      role: role,
      roleSelectionLocked: true,
      fullName: fullName.trim(),
    );
    await ref.read(currentProfileProvider.notifier).refresh();
  }

  @override
  Future<void> updateFullName(String fullName) async {
    fixture.profile = fixture.profile.copyWith(fullName: fullName.trim());
    ref.read(onboardingDraftProvider.notifier).updateFullName(fullName.trim());
    await ref.read(currentProfileProvider.notifier).refresh();
  }

  @override
  Future<void> saveHomeownerDetails({
    required ApartmentType apartmentType,
    required List<String> interests,
  }) async {
    await fixture.beforeOnboardingSave();
    final existing = fixture.homeownerProfile;
    fixture.homeownerProfile = HomeownerProfile(
      profileId: fixture.profile.id,
      apartmentType: apartmentType,
      city: existing?.city,
      district: existing?.district,
      renovationInterests: List<String>.unmodifiable(interests),
    );
    ref.invalidate(homeownerProfileProvider);
  }

  @override
  Future<void> setHomeownerLocation({
    required String city,
    required String district,
  }) async {
    await fixture.beforeOnboardingSave();
    final existing = fixture.homeownerProfile;
    fixture.homeownerProfile = HomeownerProfile(
      profileId: fixture.profile.id,
      apartmentType: existing?.apartmentType,
      city: city,
      district: district,
      renovationInterests: existing?.renovationInterests ?? const [],
    );
    ref.invalidate(homeownerProfileProvider);
  }

  @override
  Future<bool> markComplete() async {
    fixture.profile = fixture.profile.copyWith(onboardingComplete: true);
    await ref.read(currentProfileProvider.notifier).refresh();
    ref.read(onboardingDraftProvider.notifier).clearAfterCompletion();
    return true;
  }
}

class _FixtureSavedController extends SavedController {
  _FixtureSavedController(this.fixture);

  final HomeownerReferenceScenario fixture;

  @override
  Future<void> toggle(String contractorId) async {
    if (!ProfessionalReferenceFixture.isFixtureId(contractorId)) return;
    if (!fixture.savedProfessionalIds.add(contractorId)) {
      fixture.savedProfessionalIds.remove(contractorId);
    }
    ref.invalidate(savedContractorIdsProvider);
  }
}

class _FixtureBriefsController extends BriefsController {
  @override
  Future<void> updateBrief(
    String briefId, {
    required ApartmentType apartmentType,
    required String city,
    String? district,
    required String workDescription,
    required List<String> targetSpecialties,
  }) async {
    throw UnsupportedError(
      'Brief mutations are disabled in the homeowner reference fixture.',
    );
  }

  @override
  Future<String> deleteOrCancelBrief(String briefId) async {
    throw UnsupportedError(
      'Brief mutations are disabled in the homeowner reference fixture.',
    );
  }

  @override
  Future<void> requestCompletion(String briefId) async {
    throw UnsupportedError(
      'Brief mutations are disabled in the homeowner reference fixture.',
    );
  }

  @override
  Future<void> confirmCompletion(String briefId) async {
    throw UnsupportedError(
      'Brief mutations are disabled in the homeowner reference fixture.',
    );
  }

  @override
  Future<void> cancel(String briefId) async {
    throw UnsupportedError(
      'Brief mutations are disabled in the homeowner reference fixture.',
    );
  }
}

class _FixtureQuotesController extends QuotesController {
  @override
  Future<void> setStatus({
    required String quoteId,
    required String briefId,
    required QuoteStatus status,
  }) async {
    throw UnsupportedError(
      'Quote mutations are disabled in the homeowner reference fixture.',
    );
  }
}
