import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../debug/debug_role_override.dart';
import '../../features/assistant/presentation/assistant_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_entry_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/billing/presentation/pro_screen.dart';
import '../../features/briefs/presentation/contractor/job_opportunities_screen.dart';
import '../../features/briefs/presentation/contractor/homeowner_profile_preview_screen.dart';
import '../../features/briefs/presentation/contractor/post_detail_screen.dart';
import '../../features/briefs/presentation/homeowner/brief_detail_screen.dart';
import '../../features/briefs/presentation/homeowner/brief_sent_screen.dart';
import '../../features/briefs/presentation/homeowner/create_post_screen.dart';
import '../../features/briefs/presentation/homeowner/my_briefs_screen.dart';
import '../../features/briefs/presentation/homeowner/send_brief_screen.dart';
import '../../features/discovery/presentation/contractor_profile_screen.dart';
import '../../features/discovery/presentation/completed_work_screen.dart';
import '../../features/discovery/presentation/discover_screen.dart';
import '../../features/discovery/presentation/professional_collections_screen.dart';
import '../../features/explore/presentation/create_post_screen.dart' as create;
import '../../features/explore/domain/post.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/explore/presentation/my_posts_screen.dart';
import '../../features/explore/presentation/post_detail_screen.dart'
    as explore_detail;
import '../../features/explore/presentation/saved_posts_screen.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/inbox/presentation/request_detail_screen.dart';
import '../../features/home/presentation/homeowner_home_screen.dart';
import '../../features/home/presentation/reference_home_preview_profile_screen.dart';
import '../../features/home/domain/reference_home_data.dart';
import '../../features/onboarding/presentation/contractor/company_profile_screen.dart';
import '../../features/onboarding/presentation/contractor/contractor_services_screen.dart';
import '../../features/onboarding/presentation/contractor/edit_profile_screen.dart';
import '../../features/onboarding/presentation/contractor/experience_screen.dart';
import '../../features/onboarding/presentation/homeowner/homeowner_details_screen.dart';
import '../../features/onboarding/presentation/homeowner/location_screen.dart';
import '../../features/onboarding/presentation/role_select_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/portfolio/presentation/my_portfolio_screen.dart';
import '../../features/portfolio/presentation/portfolio_gallery_screen.dart';
import '../../features/portfolio/presentation/project_detail_screen.dart';
import '../../features/portfolio/presentation/project_editor_screen.dart';
import '../../features/quotes/presentation/my_quotes_screen.dart';
import '../../features/saved/presentation/saved_screen.dart';
import '../../features/shell/presentation/contractor_shell.dart';
import '../../features/shell/presentation/homeowner_shell.dart';
import '../../features/profile/presentation/homeowner_edit_profile_screen.dart';
import '../../features/shell/presentation/profile_screen.dart';
import '../../features/shell/presentation/splash_screen.dart';
import 'role_guard.dart';
import 'routes.dart';
import 'transitions.dart';
import 'browser_location.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refreshable = _AuthRefreshNotifier(ref);
  final browserUri = kIsWeb ? currentBrowserUri() : null;
  final browserPath = browserUri?.path ?? Routes.splash;
  final browserQuery = browserUri?.hasQuery == true
      ? '?${browserUri!.query}'
      : '';
  final initialLocation = browserPath == '/'
      ? Routes.splash
      : '$browserPath$browserQuery';
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    // GoRouter's platform default route is '/' in some Flutter web hosts even
    // when the browser opened a deep path. Seed it explicitly from the browser
    // location so a refresh on a profile or project route does not fall back
    // to Home.
    initialLocation: initialLocation,
    overridePlatformDefaultLocation: true,
    debugLogDiagnostics: false,
    refreshListenable: refreshable,
    redirect: (context, state) => roleGuard(ref, state),
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (_, state) => fadeSlidePage(const SplashScreen(), state),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (_, state) =>
            fadeSlidePage(const PhoneEntryScreen(), state),
        routes: [
          GoRoute(
            path: 'otp',
            pageBuilder: (_, state) => fadeSlidePage(const OtpScreen(), state),
          ),
        ],
      ),
      GoRoute(
        path: Routes.onboardingRoleSelect,
        pageBuilder: (_, state) =>
            fadeSlidePage(const RoleSelectScreen(), state),
      ),
      GoRoute(
        path: Routes.onboardingHomeownerDetails,
        pageBuilder: (_, state) =>
            fadeSlidePage(const HomeownerDetailsScreen(), state),
      ),
      GoRoute(
        path: Routes.onboardingHomeownerLocation,
        pageBuilder: (_, state) => fadeSlidePage(const LocationScreen(), state),
      ),
      GoRoute(
        path: Routes.onboardingContractorProfile,
        pageBuilder: (_, state) =>
            fadeSlidePage(const CompanyProfileScreen(), state),
      ),
      GoRoute(
        path: Routes.onboardingContractorServices,
        pageBuilder: (_, state) =>
            fadeSlidePage(const ContractorServicesScreen(), state),
      ),
      GoRoute(
        path: Routes.onboardingContractorExperience,
        pageBuilder: (_, state) => slideUpPage(const ExperienceScreen(), state),
      ),
      GoRoute(
        path: Routes.pro,
        pageBuilder: (_, state) => slideUpPage(const ProScreen(), state),
      ),
      GoRoute(
        path: Routes.notifications,
        pageBuilder: (_, state) =>
            slideUpPage(const NotificationsScreen(), state),
      ),
      GoRoute(
        path: Routes.contractorHomeownerProfile,
        pageBuilder: (_, state) => slideUpPage(
          HomeownerProfilePreviewScreen(
            homeownerId: state.pathParameters['id']!,
          ),
          state,
        ),
      ),
      GoRoute(
        path: Routes.homeownerSavedLegacy,
        redirect: (_, __) => Routes.homeownerSaved,
      ),
      GoRoute(
        path: Routes.homeownerAssistant,
        pageBuilder: (_, state) =>
            slideUpPage(const AssistantScreen(isHomeowner: true), state),
      ),
      GoRoute(
        path: Routes.contractorAssistant,
        pageBuilder: (_, state) =>
            slideUpPage(const AssistantScreen(isHomeowner: false), state),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            HomeownerShell(navigationShell: navShell, location: state.uri.path),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.homeownerHome,
                pageBuilder: (_, state) =>
                    fadeSlidePage(const HomeownerHomeScreen(), state),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.homeownerDiscover,
                pageBuilder: (_, state) =>
                    fadeSlidePage(const DiscoverScreen(), state),
                routes: [
                  GoRoute(
                    path: 'top-rated',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) => fadeSlidePage(
                      const ProfessionalCollectionsScreen(
                        kind: ProfessionalCollectionKind.topRated,
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'all-professionals',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) => fadeSlidePage(
                      const ProfessionalCollectionsScreen(
                        kind: ProfessionalCollectionKind.all,
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'nearby-professionals',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) => fadeSlidePage(
                      ProfessionalCollectionsScreen(
                        kind: ProfessionalCollectionKind.nearby,
                        city: state.uri.queryParameters['city'],
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'completed-work',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) =>
                        fadeSlidePage(const CompletedWorkScreen(), state),
                  ),
                  GoRoute(
                    path: 'contractor/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) {
                      final id = state.pathParameters['id']!;
                      return fadeSlidePage(
                        id.startsWith('preview-') && referenceHomePreviewEnabled
                            ? ReferenceHomePreviewProfileScreen(
                                professionalId: id,
                              )
                            : ContractorProfileScreen(contractorId: id),
                        state,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'brief',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (_, state) => slideUpPage(
                          SendBriefScreen(
                            contractorId: state.pathParameters['id']!,
                          ),
                          state,
                        ),
                        routes: [
                          GoRoute(
                            path: 'sent',
                            parentNavigatorKey: _rootNavigatorKey,
                            pageBuilder: (_, state) => fadeSlidePage(
                              BriefSentScreen(
                                contractorId: state.pathParameters['id']!,
                              ),
                              state,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'portfolio',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (_, state) => zoomInPage(
                          PortfolioGalleryScreen(
                            contractorId: state.pathParameters['id']!,
                          ),
                          state,
                        ),
                        routes: [
                          GoRoute(
                            path: ':projectId',
                            parentNavigatorKey: _rootNavigatorKey,
                            pageBuilder: (_, state) => zoomInPage(
                              ProjectDetailScreen(
                                projectId: state.pathParameters['projectId']!,
                              ),
                              state,
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
                pageBuilder: (_, state) =>
                    fadeSlidePage(const MyBriefsScreen(), state),
                routes: [
                  GoRoute(
                    path: 'new-post',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) =>
                        slideUpPage(const CreatePostScreen(), state),
                  ),
                  GoRoute(
                    path: ':id',
                    pageBuilder: (_, state) => fadeSlidePage(
                      BriefDetailScreen(briefId: state.pathParameters['id']!),
                      state,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.homeownerExplore,
                pageBuilder: (_, state) =>
                    fadeSlidePage(const ExploreScreen(), state),
                routes: [
                  GoRoute(
                    path: 'post/:id',
                    pageBuilder: (_, state) => fadeSlidePage(
                      explore_detail.PostDetailScreen(
                        postId: state.pathParameters['id']!,
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'new',
                    pageBuilder: (_, state) => slideUpPage(
                      create.CreatePostScreen(
                        initialKind: CommunityPostKind.fromQuery(
                          state.uri.queryParameters['type'],
                        ),
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'homeowner/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) => fadeSlidePage(
                      HomeownerProfilePreviewScreen(
                        homeownerId: state.pathParameters['id']!,
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'my-posts',
                    pageBuilder: (_, state) =>
                        fadeSlidePage(const MyPostsScreen(), state),
                  ),
                  GoRoute(
                    path: 'saved-posts',
                    pageBuilder: (_, state) =>
                        fadeSlidePage(const SavedPostsScreen(), state),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.homeownerProfile,
                pageBuilder: (_, state) =>
                    fadeSlidePage(const ProfileScreen(), state),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) =>
                        slideUpPage(const HomeownerEditProfileScreen(), state),
                  ),
                  GoRoute(
                    path: 'saved',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) =>
                        fadeSlidePage(const SavedScreen(), state),
                  ),
                  GoRoute(
                    path: 'orders',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) =>
                        fadeSlidePage(const MyBriefsScreen(), state),
                  ),
                  GoRoute(
                    path: 'settings',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) =>
                        fadeSlidePage(const HomeownerSettingsScreen(), state),
                    routes: [
                      GoRoute(
                        path: 'appearance',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (_, state) => fadeSlidePage(
                          const HomeownerAppearanceScreen(),
                          state,
                        ),
                      ),
                      GoRoute(
                        path: 'language',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (_, state) => fadeSlidePage(
                          const HomeownerLanguageScreen(),
                          state,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'privacy',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) => fadeSlidePage(
                      const HomeownerLegalScreen(
                        document: HomeownerLegalDocument.privacy,
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'terms',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) => fadeSlidePage(
                      const HomeownerLegalScreen(
                        document: HomeownerLegalDocument.terms,
                      ),
                      state,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) => ContractorShell(
          navigationShell: navShell,
          location: state.uri.path,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.contractorDashboard,
                pageBuilder: (_, state) =>
                    fadeSlidePage(const JobOpportunitiesScreen(), state),
                routes: [
                  GoRoute(
                    path: 'my-quotes',
                    pageBuilder: (_, state) =>
                        fadeSlidePage(const MyQuotesScreen(), state),
                  ),
                  GoRoute(
                    path: 'post/:id',
                    pageBuilder: (_, state) => fadeSlidePage(
                      PostDetailScreen(postId: state.pathParameters['id']!),
                      state,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.contractorExplore,
                pageBuilder: (_, state) =>
                    fadeSlidePage(const ExploreScreen(), state),
                routes: [
                  GoRoute(
                    path: 'post/:id',
                    pageBuilder: (_, state) => fadeSlidePage(
                      explore_detail.PostDetailScreen(
                        postId: state.pathParameters['id']!,
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'new',
                    pageBuilder: (_, state) => slideUpPage(
                      create.CreatePostScreen(
                        initialKind: CommunityPostKind.fromQuery(
                          state.uri.queryParameters['type'],
                        ),
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'contractor/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) => fadeSlidePage(
                      ContractorProfileScreen(
                        contractorId: state.pathParameters['id']!,
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'my-posts',
                    pageBuilder: (_, state) =>
                        fadeSlidePage(const MyPostsScreen(), state),
                  ),
                  GoRoute(
                    path: 'saved-posts',
                    pageBuilder: (_, state) =>
                        fadeSlidePage(const SavedPostsScreen(), state),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.contractorInbox,
                pageBuilder: (_, state) =>
                    fadeSlidePage(const InboxScreen(), state),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (_, state) => fadeSlidePage(
                      RequestDetailScreen(briefId: state.pathParameters['id']!),
                      state,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.contractorPortfolio,
                pageBuilder: (_, state) =>
                    fadeSlidePage(const MyPortfolioScreen(), state),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (_, state) =>
                        slideUpPage(const ProjectEditorScreen(), state),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    pageBuilder: (_, state) => slideUpPage(
                      ProjectEditorScreen(
                        projectId: state.pathParameters['id']!,
                      ),
                      state,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.contractorProfile,
                pageBuilder: (_, state) =>
                    fadeSlidePage(const ProfileScreen(), state),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (_, state) =>
                        slideUpPage(const EditProfileScreen(), state),
                  ),
                  GoRoute(
                    path: 'settings',
                    pageBuilder: (_, state) =>
                        slideUpPage(const ContractorSettingsScreen(), state),
                    routes: [
                      GoRoute(
                        path: 'appearance',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (_, state) => fadeSlidePage(
                          const HomeownerAppearanceScreen(),
                          state,
                        ),
                      ),
                      GoRoute(
                        path: 'language',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (_, state) => fadeSlidePage(
                          const HomeownerLanguageScreen(),
                          state,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'privacy',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) => fadeSlidePage(
                      const HomeownerLegalScreen(
                        document: HomeownerLegalDocument.privacy,
                      ),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'terms',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) => fadeSlidePage(
                      const HomeownerLegalScreen(
                        document: HomeownerLegalDocument.terms,
                      ),
                      state,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(currentSessionProvider, (previous, next) {
      if (previous?.user.id != next?.user.id) {
        // Never carry a view-only role override across accounts or sign-out.
        ref.read(debugRoleOverrideProvider.notifier).set(null);
      }
      notifyListeners();
    });
    ref.listen(currentProfileProvider, (_, _) => notifyListeners());
    ref.listen(homeownerProfileProvider, (_, _) => notifyListeners());
    ref.listen(contractorProfileProvider, (_, _) => notifyListeners());
    ref.listen(debugRoleOverrideProvider, (_, _) => notifyListeners());
  }
}
