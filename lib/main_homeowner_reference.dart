import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/routes.dart';
import 'core/theme/batsh_theme.dart';
import 'features/briefs/presentation/homeowner/brief_detail_screen.dart';
import 'features/discovery/domain/professional_reference_fixture.dart';
import 'features/discovery/presentation/contractor_profile_screen.dart';
import 'features/discovery/presentation/discover_screen.dart';
import 'features/home/domain/homeowner_reference_fixture.dart';
import 'features/home/presentation/homeowner_home_screen.dart';
import 'features/onboarding/presentation/homeowner/homeowner_details_screen.dart';
import 'features/onboarding/presentation/homeowner/location_screen.dart';
import 'features/onboarding/presentation/role_select_screen.dart';
import 'features/shell/presentation/homeowner_shell.dart';
import 'l10n/app_localizations.dart';

const bool _homeownerReferenceEnabled =
    kDebugMode &&
    bool.fromEnvironment('SHATTAB_HOMEOWNER_REFERENCE') &&
    professionalReferenceEnabled;

Future<void> main() async {
  if (!kDebugMode) {
    throw UnsupportedError(
      'The homeowner reference fixture only runs in a debug build.',
    );
  }
  if (!_homeownerReferenceEnabled) {
    throw StateError(
      'Enable the homeowner fixture with '
      '--dart-define=SHATTAB_HOMEOWNER_REFERENCE=true and '
      '--dart-define=SHATTAB_PROFESSIONAL_REFERENCE=true.',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();

  // HomeownerHomeScreen reports a privacy-safe view event through the Supabase
  // singleton. This local anonymous client keeps that call inert; all screen
  // data providers and mutation controllers are replaced with fixture-only
  // implementations below.
  await Supabase.initialize(
    url: 'http://127.0.0.1:54321',
    anonKey: 'homeowner-reference-local-placeholder',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: false,
      detectSessionInUri: false,
      localStorage: EmptyLocalStorage(),
    ),
  );

  final scenario = HomeownerReferenceScenario.fromUri(Uri.base);
  runApp(
    ProviderScope(
      overrides: scenario.buildProviderOverrides(Supabase.instance.client),
      child: HomeownerReferenceApp(scenario: scenario),
    ),
  );
}

class HomeownerReferenceApp extends StatefulWidget {
  const HomeownerReferenceApp({super.key, required this.scenario});

  final HomeownerReferenceScenario scenario;

  @override
  State<HomeownerReferenceApp> createState() => _HomeownerReferenceAppState();
}

class _HomeownerReferenceAppState extends State<HomeownerReferenceApp> {
  final _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'homeowner-reference-fixture-root',
  );
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createLocalRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  GoRouter _createLocalRouter() => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: widget.scenario.initialLocation,
    overridePlatformDefaultLocation: true,
    routes: [
      GoRoute(
        path: Routes.onboardingRoleSelect,
        builder: (_, __) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: Routes.onboardingHomeownerDetails,
        builder: (_, __) => const HomeownerDetailsScreen(),
      ),
      GoRoute(
        path: Routes.onboardingHomeownerLocation,
        builder: (_, __) => const LocationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeownerShell(
          navigationShell: navigationShell,
          location: state.uri.path,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.homeownerHome,
                builder: (_, __) => const HomeownerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.homeownerDiscover,
                builder: (_, __) => const DiscoverScreen(),
                routes: [
                  GoRoute(
                    path: 'top-rated',
                    builder: (_, __) => const _FixtureDestinationScreen(
                      title: 'الأعلى تقييماً',
                    ),
                  ),
                  GoRoute(
                    path: 'all-professionals',
                    builder: (_, __) =>
                        const _FixtureDestinationScreen(title: 'كل المحترفين'),
                  ),
                  GoRoute(
                    path: 'nearby-professionals',
                    builder: (_, __) => const _FixtureDestinationScreen(
                      title: 'محترفون قريبون',
                    ),
                  ),
                  GoRoute(
                    path: 'completed-work',
                    builder: (_, __) =>
                        const _FixtureDestinationScreen(title: 'أعمال مكتملة'),
                  ),
                  GoRoute(
                    path: 'contractor/:id',
                    builder: (_, state) => ContractorProfileScreen(
                      contractorId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'brief',
                        builder: (_, __) => const _FixtureDestinationScreen(
                          title: 'طلب عرض سعر',
                        ),
                        routes: [
                          GoRoute(
                            path: 'sent',
                            builder: (_, __) => const _FixtureDestinationScreen(
                              title: 'تم إرسال الطلب',
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'portfolio',
                        builder: (_, __) => const _FixtureDestinationScreen(
                          title: 'معرض الأعمال',
                        ),
                        routes: [
                          GoRoute(
                            path: ':projectId',
                            builder: (_, state) => _FixtureDestinationScreen(
                              title:
                                  'تفاصيل العمل ${state.pathParameters['projectId']}',
                            ),
                          ),
                        ],
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
                path: Routes.homeownerRequests,
                builder: (_, __) =>
                    const _FixtureDestinationScreen(title: 'طلباتي'),
                routes: [
                  GoRoute(
                    path: 'new-post',
                    builder: (_, __) => const _FixtureDestinationScreen(
                      title: 'طلب مشروع جديد',
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) {
                      final briefId = state.pathParameters['id']!;
                      if (!widget.scenario.containsBrief(briefId)) {
                        return const _FixtureDestinationScreen(
                          title: 'تفاصيل الطلب غير متاحة في هذا النموذج',
                        );
                      }
                      return BriefDetailScreen(briefId: briefId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.homeownerExplore,
                builder: (_, __) =>
                    const _FixtureDestinationScreen(title: 'مجتمع شطّاب'),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) =>
                        const _FixtureDestinationScreen(title: 'منشور جديد'),
                  ),
                  GoRoute(
                    path: 'homeowner/:id',
                    builder: (_, state) => _FixtureDestinationScreen(
                      title: 'عضو المجتمع ${state.pathParameters['id']}',
                    ),
                  ),
                  GoRoute(
                    path: 'post/:id',
                    builder: (_, state) => _FixtureDestinationScreen(
                      title: 'منشور ${state.pathParameters['id']}',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.homeownerProfile,
                builder: (_, __) =>
                    const _FixtureDestinationScreen(title: 'حسابي'),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, __) =>
                        const _FixtureDestinationScreen(title: 'تعديل الحساب'),
                  ),
                  GoRoute(
                    path: 'saved',
                    builder: (_, __) => const _FixtureDestinationScreen(
                      title: 'المحترفون المحفوظون',
                    ),
                  ),
                  GoRoute(
                    path: 'orders',
                    builder: (_, __) =>
                        const _FixtureDestinationScreen(title: 'طلباتي'),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (_, __) =>
                        const _FixtureDestinationScreen(title: 'الإعدادات'),
                    routes: [
                      GoRoute(
                        path: 'appearance',
                        builder: (_, __) =>
                            const _FixtureDestinationScreen(title: 'المظهر'),
                      ),
                      GoRoute(
                        path: 'language',
                        builder: (_, __) =>
                            const _FixtureDestinationScreen(title: 'اللغة'),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (_, __) =>
                        const _FixtureDestinationScreen(title: 'الخصوصية'),
                  ),
                  GoRoute(
                    path: 'terms',
                    builder: (_, __) => const _FixtureDestinationScreen(
                      title: 'الشروط والأحكام',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const _FixtureDestinationScreen(title: 'الإشعارات'),
      ),
      GoRoute(
        path: Routes.homeownerAssistant,
        builder: (_, __) => const _FixtureDestinationScreen(title: 'المساعد'),
      ),
      GoRoute(
        path: Routes.pro,
        builder: (_, __) => const _FixtureDestinationScreen(title: 'الاشتراك'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Shattab Homeowner Reference Fixture',
    debugShowCheckedModeBanner: false,
    theme: BatshTheme.light(),
    routerConfig: _router,
    locale: const Locale('ar', 'EG'),
    supportedLocales: const [Locale('ar', 'EG'), Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) {
      if (child == null) return const SizedBox.shrink();
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          textScaler: TextScaler.linear(widget.scenario.textScale),
        ),
        child: child,
      );
    },
  );
}

class _FixtureDestinationScreen extends StatelessWidget {
  const _FixtureDestinationScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ),
  );
}
