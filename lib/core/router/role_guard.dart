import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    return Routes.homeownerDiscover;
  }

  final profileAsync = ref.read(currentProfileProvider);
  // Wait until profile resolves; show splash in the meantime.
  if (profileAsync.isLoading) {
    return path == Routes.splash ? null : Routes.splash;
  }

  final profile = profileAsync.value;
  if (profile == null) {
    return path == Routes.onboardingRoleSelect
        ? null
        : Routes.onboardingRoleSelect;
  }

  // A brand-new, trigger-created profile has an empty full_name and role
  // defaulted to homeowner. Anyone who entered through the /login flow (e.g.
  // tapped "sign in as contractor") must pick their role first. A guest who
  // signed in mid-browse via the sheet keeps their place — the sheet collects
  // the name inline and never routes here.
  if (profile.fullName.trim().isEmpty) {
    if (path == Routes.onboardingRoleSelect) return null;
    // /login covers direct sign-ins; /splash covers fresh sign-ups (the
    // profile resolves while the guard is parked on splash, so without this
    // case a new account skips role/name selection entirely). Guests signing
    // in mid-browse stay where they are — the sheet collects the name inline.
    if (path.startsWith('/login') || path == Routes.splash) {
      return Routes.onboardingRoleSelect;
    }
  }

  if (!profile.onboardingComplete) {
    final nextStep = _nextOnboardingStep(ref, profile);
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
      ? Routes.homeownerDiscover
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
    final ho = ref.read(homeownerProfileProvider).value;
    if (ho == null || !ho.hasApartmentType || !ho.hasInterests) {
      return Routes.onboardingHomeownerDetails;
    }
    return Routes.onboardingHomeownerLocation;
  }
  final co = ref.read(contractorProfileProvider).value;
  if (co == null || !co.hasBusinessName) {
    return Routes.onboardingContractorProfile;
  }
  if (!co.hasSpecialties || !co.hasServiceAreas) {
    return Routes.onboardingContractorServices;
  }
  return Routes.onboardingContractorExperience;
}
