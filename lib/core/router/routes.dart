class Routes {
  const Routes._();

  static const String splash = '/';

  static const String login = '/login';
  static const String otp = '/login/otp';

  static const String onboardingRoleSelect = '/onboarding/role-select';

  // Consolidated onboarding
  static const String onboardingHomeownerDetails =
      '/onboarding/homeowner/details';
  static const String onboardingHomeownerLocation =
      '/onboarding/homeowner/location';

  static const String onboardingContractorProfile =
      '/onboarding/contractor/profile';
  static const String onboardingContractorServices =
      '/onboarding/contractor/services';
  static const String onboardingContractorExperience =
      '/onboarding/contractor/experience';

  static const String homeownerShell = '/h';
  static const String homeownerExplore = '/h/explore';
  static const String homeownerDiscover = '/h/discover';
  static const String homeownerRequests = '/h/requests';
  static const String homeownerSaved = '/h/saved';
  static const String homeownerProfile = '/h/profile';
  static const String homeownerEditProfile = '/h/profile/edit';

  static const String contractorShell = '/c';
  static const String contractorExplore = '/c/explore';
  static const String contractorDashboard = '/c/dashboard';
  static const String contractorInbox = '/c/inbox';
  static const String contractorPortfolio = '/c/portfolio';
  static const String contractorProfile = '/c/profile';
  static const String contractorEditProfile = '/c/profile/edit';

  // Monetization (full-screen, above the shell)
  static const String pro = '/pro';

  // M2 nested routes
  static String homeownerContractorProfilePath(String id) =>
      '/h/discover/contractor/$id';
  static String homeownerSendBriefPath(String id) =>
      '/h/discover/contractor/$id/brief';
  static String homeownerBriefSentPath(String id) =>
      '/h/discover/contractor/$id/brief/sent';
  static const String homeownerNewPost = '/h/requests/new-post';
  static String homeownerBriefDetailPath(String id) => '/h/requests/$id';
  static String contractorPostDetailPath(String id) => '/c/dashboard/post/$id';
  static String contractorRequestDetailPath(String id) => '/c/inbox/$id';
  static const String contractorMyQuotes = '/c/dashboard/my-quotes';
  static const String contractorPortfolioNew = '/c/portfolio/new';
  static String contractorPortfolioEditPath(String id) =>
      '/c/portfolio/$id/edit';
  static String homeownerContractorPortfolioPath(String id) =>
      '/h/discover/contractor/$id/portfolio';
  static String homeownerProjectDetailPath(
    String contractorId,
    String projectId,
  ) => '/h/discover/contractor/$contractorId/portfolio/$projectId';

  // Explore
  static const String exploreCreatePost = '/explore/new';
  static String explorePostDetailPath(String id) => '/explore/post/$id';
  static const String exploreMyPosts = '/explore/my-posts';
  static const String exploreSavedPosts = '/explore/saved-posts';
}
