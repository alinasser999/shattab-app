import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_entry_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/briefs/presentation/contractor/job_opportunities_screen.dart';
import '../../features/briefs/presentation/contractor/post_detail_screen.dart';
import '../../features/briefs/presentation/homeowner/brief_detail_screen.dart';
import '../../features/briefs/presentation/homeowner/brief_sent_screen.dart';
import '../../features/briefs/presentation/homeowner/create_post_screen.dart';
import '../../features/briefs/presentation/homeowner/my_briefs_screen.dart';
import '../../features/briefs/presentation/homeowner/send_brief_screen.dart';
import '../../features/discovery/presentation/contractor_profile_screen.dart';
import '../../features/discovery/presentation/discover_screen.dart';
import '../../features/onboarding/presentation/contractor/business_name_screen.dart';
import '../../features/onboarding/presentation/contractor/experience_screen.dart';
import '../../features/onboarding/presentation/contractor/logo_upload_screen.dart';
import '../../features/onboarding/presentation/contractor/service_areas_screen.dart';
import '../../features/onboarding/presentation/contractor/specialties_screen.dart';
import '../../features/onboarding/presentation/homeowner/apartment_type_screen.dart';
import '../../features/onboarding/presentation/homeowner/interests_screen.dart';
import '../../features/onboarding/presentation/homeowner/location_screen.dart';
import '../../features/onboarding/presentation/role_select_screen.dart';
import '../../features/portfolio/presentation/portfolio_gallery_screen.dart';
import '../../features/portfolio/presentation/project_detail_screen.dart';
import '../../features/saved/presentation/saved_screen.dart';
import '../../features/shell/presentation/contractor_shell.dart';
import '../../features/shell/presentation/homeowner_shell.dart';
import '../../features/shell/presentation/placeholder_screen.dart';
import '../../features/shell/presentation/profile_screen.dart';
import '../../features/shell/presentation/splash_screen.dart';
import '../l10n/strings.dart';
import 'role_guard.dart';
import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refreshable = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshable,
    redirect: (context, state) => roleGuard(ref, state),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const PhoneEntryScreen(),
        routes: [
          GoRoute(path: 'otp', builder: (_, _) => const OtpScreen()),
        ],
      ),
      GoRoute(
        path: Routes.onboardingRoleSelect,
        builder: (_, _) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: Routes.onboardingHomeownerApartment,
        builder: (_, _) => const ApartmentTypeScreen(),
      ),
      GoRoute(
        path: Routes.onboardingHomeownerLocation,
        builder: (_, _) => const LocationScreen(),
      ),
      GoRoute(
        path: Routes.onboardingHomeownerInterests,
        builder: (_, _) => const InterestsScreen(),
      ),
      GoRoute(
        path: Routes.onboardingContractorBusiness,
        builder: (_, _) => const BusinessNameScreen(),
      ),
      GoRoute(
        path: Routes.onboardingContractorSpecialties,
        builder: (_, _) => const SpecialtiesScreen(),
      ),
      GoRoute(
        path: Routes.onboardingContractorAreas,
        builder: (_, _) => const ServiceAreasScreen(),
      ),
      GoRoute(
        path: Routes.onboardingContractorLogo,
        builder: (_, _) => const LogoUploadScreen(),
      ),
      GoRoute(
        path: Routes.onboardingContractorExperience,
        builder: (_, _) => const ExperienceScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            HomeownerShell(navigationShell: navShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.homeownerDiscover,
              builder: (_, _) => const DiscoverScreen(),
              routes: [
                GoRoute(
                  path: 'contractor/:id',
                  builder: (_, state) => ContractorProfileScreen(
                      contractorId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'brief',
                      builder: (_, state) => SendBriefScreen(
                          contractorId: state.pathParameters['id']!),
                      routes: [
                        GoRoute(
                          path: 'sent',
                          builder: (_, state) => BriefSentScreen(
                              contractorId: state.pathParameters['id']!),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'portfolio',
                      builder: (_, state) => PortfolioGalleryScreen(
                          contractorId: state.pathParameters['id']!),
                      routes: [
                        GoRoute(
                          path: ':projectId',
                          builder: (_, state) => ProjectDetailScreen(
                              projectId:
                                  state.pathParameters['projectId']!),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.homeownerRequests,
              builder: (_, _) => const MyBriefsScreen(),
              routes: [
                GoRoute(
                  path: 'new-post',
                  builder: (_, _) => const CreatePostScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => BriefDetailScreen(
                      briefId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.homeownerSaved,
              builder: (_, _) => const SavedScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.homeownerProfile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            ContractorShell(navigationShell: navShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.contractorDashboard,
              builder: (_, _) => const JobOpportunitiesScreen(),
              routes: [
                GoRoute(
                  path: 'post/:id',
                  builder: (_, state) => PostDetailScreen(
                      postId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.contractorInbox,
              builder: (_, _) => const PlaceholderScreen(
                title: S.tabInbox,
                message: S.comingSoonM3,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.contractorPortfolio,
              builder: (_, _) => const PlaceholderScreen(
                title: S.tabPortfolio,
                message: S.comingSoonM3,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.contractorProfile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(currentSessionProvider, (_, _) => notifyListeners());
    ref.listen(currentProfileProvider, (_, _) => notifyListeners());
  }
}
