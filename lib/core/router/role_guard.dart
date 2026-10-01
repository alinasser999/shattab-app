import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../debug/debug_role_override.dart';
import '../../features/auth/domain/profile.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import 'routes.dart';

/// Returns the redirect path, or null if the requested path is allowed.
/// Called by [GoRouter.redirect] on every navigation.
String? roleGuard(Ref ref, GoRouterState state) {
  final path = state.matchedLocation;

  final session = ref.read(currentSessionProvider);

  if (session == null) {
    if (path == Routes.notifications) return Routes.login;
    if (path.startsWith('/login')) return null;
    // Guests may browse the homeowner shell (Discover, contractor profiles,
    // portfolios) freely — sign-in is gated at the point of a write action
    // (save / send request / create post), not at the app door.
    if (path.startsWith(Routes.homeownerShell)) return null;
    // Contractors still need to sign in up front — no anonymous browsing
    // on that side.
    if (path.startsWith(Routes.contractorShell)) return Routes.login;
    // Splash (first launch) or any other unmatched path: land guests in
    // Discover instead of forcing the login wall.
    return Routes.homeownerHome;
  }

  final profileAsync = ref.read(currentProfileProvider);
  // Wait until profile resolves; show splash in the meantime.
  if (profileAsync.isLoading) {
    // Keep an authenticated portal deep link alive while its screen-level
    // providers resolve. Otherwise a refresh of /c/profile/settings falls
    // through splash and loses the original destination.
    final isPortalPath =
        path.startsWith(Routes.homeownerShell) ||
        path.startsWith(Routes.contractorShell);
    if (isPortalPath || path == Routes.splash) return null;
    return Routes.splash;
  }

  // A failed profile fetch (transient network error at startup) must not be
  // read as "no profile" — routing an onboarded user into role-select looks
  // like their account vanished. Park on splash instead: CurrentProfile
  // retries internally and rebuilds when connectivity returns, and the
  // router refreshes when the provider resolves.
  if (profileAsync.hasError) {
    return path == Routes.splash ? null : Routes.splash;
  }

  final profile = profileForDebugRole(
    profileAsync.value,
    ref.read(debugRoleOverrideProvider),
  );
  if (profile == null) {
    return path == Routes.onboardingRoleSelect
        ? null
        : Routes.onboardingRoleSelect;
  }

  if (!profile.onboardingComplete) {
    // An unlocked account must make its one-time role choice first. A locked
    // account with a legacy or edited-invalid name may repair that name in the
    // same screen, while the role remains read-only.
    if (!profile.roleSelectionLocked || profile.fullName.trim().length < 2) {
      return path == Routes.onboardingRoleSelect
          ? null
          : Routes.onboardingRoleSelect;
    }

    // The role/name page remains available as a locked summary while the user
    // reviews earlier required steps.
    if (path == Routes.onboardingRoleSelect) return null;

    final nextStep = _nextOnboardingStep(ref, profile);
    if (nextStep == Routes.splash) {
      final currentRoleFlow = profile.role == UserRole.homeowner
          ? path.startsWith('/onboarding/homeowner/')
          : path.startsWith('/onboarding/contractor/');
      return path == Routes.splash || currentRoleFlow ? null : Routes.splash;
    }
    if (path == nextStep) return null;
    if (path.startsWith('/onboarding/')) {
      // Allow lateral movement within the same flow so users can revisit
      // earlier steps if they want to amend a value.
      final inHomeownerFlow = path.startsWith('/onboarding/homeowner/');
      final inContractorFlow = path.startsWith('/onboarding/contractor/');
      if ((profile.role == UserRole.homeowner && inHomeownerFlow) ||
          (profile.role == UserRole.contractor && inContractorFlow)) {
        return null;
      }
    }
    return nextStep;
  }

  // Onboarded — bounce to the right portal if user lands in the wrong place.
  final homeRoot = profile.role == UserRole.homeowner
      ? Routes.homeownerHome
      : Routes.contractorDashboard;

  if (path == Routes.splash ||
      path.startsWith('/login') ||
      path.startsWith('/onboarding/')) {
    return homeRoot;
  }

  if (profile.role == UserRole.homeowner && path.startsWith('/c')) {
    return Routes.homeownerDiscover;
  }
  if (profile.role == UserRole.contractor && path.startsWith('/h')) {
    return Routes.contractorDashboard;
  }
  return null;
}

String _nextOnboardingStep(Ref ref, Profile profile) {
  if (profile.role == UserRole.homeowner) {
    final homeownerAsync = ref.read(homeownerProfileProvider);
    if (homeownerAsync.isLoading || homeownerAsync.hasError) {
      return Routes.splash;
    }
    final ho = homeownerAsync.value;
    if (ho == null || !ho.hasApartmentType || !ho.hasInterests) {
      return Routes.onboardingHomeownerDetails;
    }
    return Routes.onboardingHomeownerLocation;
  }
  final contractorAsync = ref.read(contractorProfileProvider);
  if (contractorAsync.isLoading || contractorAsync.hasError) {
    return Routes.splash;
  }
  final co = contractorAsync.value;
  if (co == null ||
      !co.hasRequiredIdentity(responsibleName: profile.fullName)) {
    return Routes.onboardingContractorProfile;
  }
  if (!co.hasSpecialties || !co.hasServiceAreas) {
    return Routes.onboardingContractorServices;
  }
  // Experience, bio, and portfolio improve discovery but do not block a new
  // contractor from reaching relevant opportunities.
  return Routes.onboardingContractorServices;
}
