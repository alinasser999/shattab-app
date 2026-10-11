import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

import 'package:batsh/core/supabase/supabase_provider.dart';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/utils/connectivity.dart';
import 'package:batsh/core/widgets/photo_picker.dart';
import 'package:batsh/features/auth/data/auth_repository.dart';
import 'package:batsh/features/auth/presentation/providers/auth_provider.dart';
import 'package:batsh/features/auth/presentation/sign_in_sheet.dart';
import 'package:batsh/features/briefs/data/briefs_repository.dart';
import 'package:batsh/features/briefs/presentation/homeowner/brief_detail_screen.dart';
import 'package:batsh/features/briefs/presentation/homeowner/create_post_screen.dart';
import 'package:batsh/features/briefs/presentation/homeowner/my_briefs_screen.dart';
import 'package:batsh/features/contact_followup/presentation/providers/professional_contact_providers.dart';
import 'package:batsh/features/discovery/data/discovery_repository.dart';
import 'package:batsh/features/discovery/presentation/contractor_profile_screen.dart';
import 'package:batsh/features/discovery/presentation/professional_directory_screen.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/explore/data/post_repository.dart';
import 'package:batsh/features/explore/presentation/explore_screen.dart';
import 'package:batsh/features/explore/presentation/widgets/community_feed_widgets.dart';
import 'package:batsh/features/home/domain/empty_states_reference_fixture.dart';
import 'package:batsh/features/home/presentation/homeowner_home_screen.dart';
import 'package:batsh/features/notifications/data/notifications_repository.dart';
import 'package:batsh/features/notifications/presentation/notifications_screen.dart';
import 'package:batsh/features/onboarding/data/onboarding_repository.dart';
import 'package:batsh/features/onboarding/presentation/contractor/company_profile_screen.dart';
import 'package:batsh/features/onboarding/presentation/contractor/contractor_services_screen.dart';
import 'package:batsh/features/onboarding/presentation/contractor/experience_screen.dart';
import 'package:batsh/features/onboarding/presentation/homeowner/homeowner_details_screen.dart';
import 'package:batsh/features/onboarding/presentation/homeowner/location_screen.dart';
import 'package:batsh/features/onboarding/presentation/role_select_screen.dart';
import 'package:batsh/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:batsh/features/portfolio/data/portfolio_repository.dart';
import 'package:batsh/features/portfolio/presentation/my_portfolio_screen.dart';
import 'package:batsh/features/portfolio/presentation/portfolio_gallery_screen.dart';
import 'package:batsh/features/portfolio/presentation/project_editor_screen.dart';
import 'package:batsh/features/quotes/data/quotes_repository.dart';
import 'package:batsh/features/reviews/data/reviews_repository.dart';
import 'package:batsh/features/reviews/presentation/reviews_sheet.dart';
import 'package:batsh/features/saved/data/saved_repository.dart';
import 'package:batsh/features/saved/presentation/saved_screen.dart';
import 'package:batsh/features/shell/presentation/homeowner_shell.dart';
import 'package:batsh/features/shell/presentation/profile_screen.dart';
import 'package:batsh/l10n/app_localizations.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'homeowner_reference_harness.dart' show initializeHomeownerTestClient;

Future<void> initializeEmptyStateTests() => initializeHomeownerTestClient();

Future<({EmptyReferenceFixture fixture, ProviderContainer container})>
pumpEmptyScene(
  WidgetTester tester,
  String scene, {
  bool? contractorRole,
  Size size = const Size(390, 844),
  double textScale = 1,
  List<Override> extraOverrides = const [],
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fixture = EmptyReferenceFixture(scene, contractorRole: contractorRole);
  final client = SupabaseClient(
    'http://127.0.0.1:54321',
    'local-test-placeholder',
    httpClient: EmptyReferenceTransport(fixture),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final logoFile = File(
    "${Directory.systemTemp.path}/empty-state-test-logo-${DateTime.now().microsecondsSinceEpoch}.png",
  );
  logoFile.writeAsBytesSync(
    base64Decode(
      "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAE0lEQVR4nGP4//vLf3yYYWQoAACWd/tB2yDuvwAAAABJRU5ErkJggg==",
    ),
  );
  addTearDown(() async {
    if (logoFile.existsSync()) logoFile.deleteSync();
  });
  final defaults = <Override>[
    supabaseClientProvider.overrideWithValue(client),
    currentSessionProvider.overrideWith(
      (_) => fixture.guest ? null : fixture.session,
    ),
    authRepositoryProvider.overrideWithValue(
      EmptyReferenceAuthRepository(client, fixture),
    ),
    onboardingRepositoryProvider.overrideWithValue(
      EmptyReferenceOnboardingRepository(client, fixture),
    ),
    onboardingControllerProvider.overrideWith(_LocalOnboardingController.new),
    discoveryRepositoryProvider.overrideWithValue(
      EmptyReferenceDiscoveryRepository(client, fixture),
    ),
    briefsRepositoryProvider.overrideWithValue(
      EmptyReferenceBriefsRepository(client, fixture),
    ),
    quotesRepositoryProvider.overrideWithValue(
      EmptyReferenceQuotesRepository(client, fixture),
    ),
    portfolioRepositoryProvider.overrideWithValue(
      EmptyReferencePortfolioRepository(client, fixture),
    ),
    reviewsRepositoryProvider.overrideWithValue(
      EmptyReferenceReviewsRepository(client, fixture),
    ),
    savedRepositoryProvider.overrideWithValue(
      EmptyReferenceSavedRepository(client, fixture),
    ),
    notificationsRepositoryProvider.overrideWithValue(
      EmptyReferenceNotificationsRepository(client, fixture),
    ),
    postRepositoryProvider.overrideWithValue(
      EmptyReferencePostRepository(client, fixture),
    ),
    photoPickerCallbackProvider.overrideWithValue((_) async {
      fixture.record('pickPhotos');
      throw StateError('Local picker failure fixture');
    }),
    companyLogoPickerProvider.overrideWithValue(() async {
      fixture.record('pickLogo');
      return XFile(logoFile.path);
    }),
    professionalContactEpisodeProvider.overrideWith((_) async => null),
    connectivityProvider.overrideWith((_) => Stream.value(scene != 'C2')),
    if (scene == 'B5')
      discoveryFiltersControllerProvider.overrideWith(_FilteredDirectory.new),
  ];
  final replaced = extraOverrides.map((o) => o.origin).toSet();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        ...defaults.where((o) => !replaced.contains(o.origin)),
        ...extraOverrides,
      ],
      child: _ReferenceApp(
        key: UniqueKey(),
        fixture: fixture,
        textScale: textScale,
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(_ReferenceApp)),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  return (fixture: fixture, container: container);
}

class _FilteredDirectory extends DiscoveryFiltersController {
  @override
  DiscoveryFilters build() =>
      const DiscoveryFilters(searchQuery: 'بحث المعاينة');
}

class _LocalOnboardingController extends OnboardingController {
  @override
  Future<String?> uploadLogo(File file) => ref
      .read(onboardingRepositoryProvider)
      .uploadContractorLogo(
        profileId: EmptyReferenceFixture.userId,
        file: file,
      );
}

class _ReferenceApp extends StatefulWidget {
  const _ReferenceApp({
    super.key,
    required this.fixture,
    required this.textScale,
  });
  final EmptyReferenceFixture fixture;
  final double textScale;
  @override
  State<_ReferenceApp> createState() => _ReferenceAppState();
}

class _ReferenceAppState extends State<_ReferenceApp> {
  late final GoRouter router = GoRouter(
    initialLocation:
        widget.fixture.scene == 'B1' || widget.fixture.scene == 'B2'
        ? '/h/home'
        : '/',
    overridePlatformDefaultLocation: true,
    observers: [_ActionObserver(widget.fixture)],
    routes: [
      GoRoute(path: '/', builder: (_, _) => _scene(widget.fixture.scene)),
      GoRoute(
        path: '/fixture-actions',
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Local fixture action record')),
          body: ListView(
            children: [
              for (final action in widget.fixture.actions)
                ListTile(title: Text(action)),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/onboarding/role-select',
        builder: (_, _) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: '/onboarding/homeowner/details',
        builder: (_, _) => const HomeownerDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/homeowner/location',
        builder: (_, _) => const LocationScreen(),
      ),
      GoRoute(
        path: '/onboarding/contractor/profile',
        builder: (_, _) => const CompanyProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/contractor/services',
        builder: (_, _) => const ContractorServicesScreen(),
      ),
      GoRoute(
        path: '/onboarding/contractor/experience',
        builder: (_, _) => const ExperienceScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, state, navigationShell) => HomeownerShell(
          navigationShell: navigationShell,
          location: state.uri.path,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/h/home',
                builder: (_, _) => const HomeownerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/h/discover',
                builder: (_, _) => const ProfessionalDirectoryScreen(),
                routes: [
                  GoRoute(
                    path: 'all-professionals',
                    builder: (_, _) => const ProfessionalDirectoryScreen(),
                  ),
                  GoRoute(
                    path: 'contractor/:id',
                    builder: (_, s) => ContractorProfileScreen(
                      contractorId: s.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'portfolio',
                        builder: (_, s) => PortfolioGalleryScreen(
                          contractorId: s.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/h/requests',
                builder: (_, _) => const MyBriefsScreen(),
                routes: [
                  GoRoute(
                    path: 'new-post',
                    builder: (_, _) => const CreatePostScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, s) =>
                        BriefDetailScreen(briefId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/h/explore',
                builder: (_, _) => ExploreScreen(
                  initialFilter: widget.fixture.scene == 'B11'
                      ? CommunityFeedFilter.requests
                      : CommunityFeedFilter.all,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/h/profile',
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'saved',
                    builder: (_, _) => const SavedScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/c/portfolio',
        builder: (_, _) => const MyPortfolioScreen(),
      ),
      GoRoute(
        path: '/c/portfolio/new',
        builder: (_, _) => const ProjectEditorScreen(),
      ),
      GoRoute(
        path: '/c/dashboard',
        builder: (_, _) => const _ContractorLanding(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
    ],
  );
  Widget _scene(String scene) => switch (scene) {
    'A1' || 'C3' => const RoleSelectScreen(),
    'A2' => const HomeownerDetailsScreen(),
    'A3' => const LocationScreen(),
    'A4' || 'C4' || 'C5' => const CompanyProfileScreen(),
    'A5' => const ContractorServicesScreen(),
    'A6' => const ExperienceScreen(),
    'B1' || 'B2' => const HomeownerHomeScreen(),
    'B3' || 'B4' => const SavedScreen(),
    'B5' || 'B6' || 'C1' || 'C2' => const ProfessionalDirectoryScreen(),
    'B7' => const MyPortfolioScreen(),
    'B8' => const PortfolioGalleryScreen(
      contractorId: EmptyReferenceFixture.contractorId,
    ),
    'B9' => const _SheetLauncher(reviews: true),
    'B10' => const NotificationsScreen(),
    'B11' => const ExploreScreen(initialFilter: CommunityFeedFilter.requests),
    'B12' => const ExploreScreen(),
    'C6' => const CreatePostScreen(),
    'profile' => const ContractorProfileScreen(
      contractorId: EmptyReferenceFixture.contractorId,
    ),
    'signin' => const _SheetLauncher(reviews: false),
    'quotes' => BriefDetailScreen(briefId: widget.fixture.brief.id),
    'projects' => const MyBriefsScreen(),
    _ => const RoleSelectScreen(),
  };
  @override
  void initState() {
    super.initState();
    router.routerDelegate.addListener(_recordLocation);
    _recordLocation();
  }

  void _recordLocation() => widget.fixture.record(
    'router location:${router.routeInformationProvider.value.uri.path}',
  );
  @override
  void dispose() {
    router.routerDelegate.removeListener(_recordLocation);
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Shattab empty states — local development fixture',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: BatshTheme.light(),
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(widget.textScale)),
      child: child!,
    ),
  );
}

class _ActionObserver extends NavigatorObserver {
  _ActionObserver(this.fixture);
  final EmptyReferenceFixture fixture;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      fixture.record('route push:${route.settings.name}');
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      fixture.record('route pop:${route.settings.name}');
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      fixture.record('route replace:${newRoute?.settings.name}');
}

class _SheetLauncher extends StatefulWidget {
  const _SheetLauncher({required this.reviews});
  final bool reviews;
  @override
  State<_SheetLauncher> createState() => _SheetLauncherState();
}

class _SheetLauncherState extends State<_SheetLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open();
    });
  }

  void _open() {
    if (widget.reviews) {
      showReviewsSheet(context, EmptyReferenceFixture.contractorId);
    } else {
      showSignInSheet(context, reason: 'سجّل دخولك لحفظ اختياراتك');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('معاينة محلية')),
    body: Center(
      child: FilledButton(
        onPressed: _open,
        child: Text(widget.reviews ? 'عرض التقييمات' : 'تسجيل الدخول'),
      ),
    ),
  );
}

class _ContractorLanding extends StatelessWidget {
  const _ContractorLanding();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مساحة المهني — وجهة معاينة محلية')),
    body: Center(
      child: FilledButton(
        onPressed: () => context.go('/c/portfolio'),
        child: const Text('أعمالي'),
      ),
    ),
  );
}
