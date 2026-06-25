class Routes {
  const Routes._();

  static const String splash = '/';

  static const String login = '/login';
  static const String otp = '/login/otp';

  static const String onboardingRoleSelect = '/onboarding/role-select';

  static const String onboardingHomeownerApartment =
      '/onboarding/homeowner/apartment';
  static const String onboardingHomeownerLocation =
      '/onboarding/homeowner/location';
  static const String onboardingHomeownerInterests =
      '/onboarding/homeowner/interests';

  static const String onboardingContractorBusiness =
      '/onboarding/contractor/business';
  static const String onboardingContractorSpecialties =
      '/onboarding/contractor/specialties';
  static const String onboardingContractorAreas =
      '/onboarding/contractor/areas';
  static const String onboardingContractorLogo =
      '/onboarding/contractor/logo';
  static const String onboardingContractorExperience =
      '/onboarding/contractor/experience';

  static const String homeownerShell = '/h';
  static const String homeownerDiscover = '/h/discover';
  static const String homeownerRequests = '/h/requests';
  static const String homeownerSaved = '/h/saved';
  static const String homeownerProfile = '/h/profile';

  static const String contractorShell = '/c';
  static const String contractorDashboard = '/c/dashboard';
  static const String contractorInbox = '/c/inbox';
  static const String contractorPortfolio = '/c/portfolio';
  static const String contractorProfile = '/c/profile';

  // M2 nested routes
  static String homeownerContractorProfilePath(String id) =>
      '/h/discover/contractor/$id';
  static String homeownerSendBriefPath(String id) =>
      '/h/discover/contractor/$id/brief';
  static String homeownerBriefSentPath(String id) =>
      '/h/discover/contractor/$id/brief/sent';
  static const String homeownerNewPost = '/h/requests/new-post';
  static String homeownerBriefDetailPath(String id) => '/h/requests/$id';
  static String contractorPostDetailPath(String id) =>
      '/c/dashboard/post/$id';
  static String homeownerContractorPortfolioPath(String id) =>
      '/h/discover/contractor/$id/portfolio';
  static String homeownerProjectDetailPath(
          String contractorId, String projectId) =>
      '/h/discover/contractor/$contractorId/portfolio/$projectId';
}
