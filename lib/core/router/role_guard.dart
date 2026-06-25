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
    return path.startsWith('/login') ? null : Routes.login;
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
    if (ho == null || !ho.hasApartmentType) {
      return Routes.onboardingHomeownerApartment;
    }
    if (!ho.hasLocation) return Routes.onboardingHomeownerLocation;
    if (!ho.hasInterests) return Routes.onboardingHomeownerInterests;
    return Routes.onboardingHomeownerInterests;
  }
  final co = ref.read(contractorProfileProvider).value;
  if (co == null || !co.hasBusinessName) {
    return Routes.onboardingContractorBusiness;
  }
  if (!co.hasSpecialties) return Routes.onboardingContractorSpecialties;
  if (!co.hasServiceAreas) return Routes.onboardingContractorAreas;
  if (co.logoUrl == null) return Routes.onboardingContractorLogo;
  if (!co.hasExperience) return Routes.onboardingContractorExperience;
  return Routes.onboardingContractorExperience;
}
