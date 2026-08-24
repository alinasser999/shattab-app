// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get opportunityPostedBy => 'Post owner';

  @override
  String get viewHomeownerProfile => 'View post owner\'s profile';

  @override
  String get homeownerProfileTitle => 'Post owner profile';

  @override
  String get homeownerProfileSubtitle => 'Public details about the post owner';

  @override
  String get homeownerProfileDetailsTitle => 'Post owner details';

  @override
  String get homeownerLocationLabel => 'Project area';

  @override
  String get homeownerApartmentLabel => 'Home type';

  @override
  String get homeownerInterestsLabel => 'Renovation interests';

  @override
  String get homeownerProfileUnavailable =>
      'Post owner details are unavailable right now.';

  @override
  String get homeownerProfileNoDetails =>
      'No additional home or renovation details have been added yet.';

  @override
  String get homeownerProfilePrivacyHint =>
      'Contact details are not shown on this profile.';

  @override
  String get tierHowGold =>
      'Gold: verified account + 10 completed projects or 5 reviews.';

  @override
  String get tierHowSilver =>
      'Silver: 3 completed projects or a verified account.';

  @override
  String get tierNotForSale =>
      'Levels are earned through completed work — never bought, not part of Pro.';

  @override
  String quotesLeftThisMonth(int remaining) {
    return '$remaining free quotes left this month';
  }

  @override
  String get appName => 'Shattab';

  @override
  String get appNameLatin => 'Shattab';

  @override
  String get enterPhone => 'Enter your phone number';

  @override
  String get phoneHint => '+20 1XX XXX XXXX';

  @override
  String get phoneLocalHint => '1XX XXX XXXX';

  @override
  String get continueLabel => 'Continue';

  @override
  String get otpTitle => 'Enter verification code';

  @override
  String get signInSheetTitle => 'Sign in to continue';

  @override
  String get signInToSave => 'Sign in to save this Professional';

  @override
  String get signInToSendRequest => 'Sign in to send your request';

  @override
  String get signInToPost => 'Sign in to post your request';

  @override
  String get signInToInteract => 'Sign in to interact with posts';

  @override
  String get quoteSentShort => 'Quote sent';

  @override
  String get myQuotesTitle => 'My quotes';

  @override
  String get myQuotesEmptyTitle => 'No quotes yet';

  @override
  String get signInToSeeRequests => 'Sign in to see your requests';

  @override
  String get signInOrCreateAccount => 'Sign in or create an account';

  @override
  String get contractorSignInLink => 'Professional? Sign in here';

  @override
  String get heroLine1 => 'Finish your home';

  @override
  String get heroLine2 => 'without the headache';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get dataSecure => 'Your data is secure and encrypted';

  @override
  String get loginPrompt => 'Already have an account?';

  @override
  String get loginAction => 'Log in';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'At least 6 characters';

  @override
  String get confirmPasswordHint => 'Confirm password';

  @override
  String get signupNeedsConfirmation =>
      'Your account was created. Confirm your phone, then sign in.';

  @override
  String get signInAction => 'Sign in';

  @override
  String get createAccountAction => 'Create account';

  @override
  String get noAccountPrompt => 'No account?';

  @override
  String get haveAccountPrompt => 'Have an account?';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orDivider => 'or';

  @override
  String get quickActionsTitle => 'Quick actions';

  @override
  String get accountSettingsTitle => 'Settings';

  @override
  String get roleSwitcherOwner => 'Owner';

  @override
  String get roleSwitcherContractor => 'Contractor';

  @override
  String get nextStepsTitle => 'Start here';

  @override
  String get performanceTitle => 'Your performance in the last 30 days';

  @override
  String get personalizeTitle => 'Personalize your experience';

  @override
  String get areasNotAdded => 'Work areas have not been added';

  @override
  String get verifiedStatus => 'Verified';

  @override
  String get unverifiedStatus => 'Not verified';

  @override
  String get profileCompletionTitle => 'Profile completion';

  @override
  String profileCompletionPercent(int value) {
    return 'Profile $value% complete';
  }

  @override
  String get profileCompleteMessage =>
      'Your profile is ready to introduce your work to clients.';

  @override
  String get profileIncompleteMessage =>
      'Complete your profile to appear to more clients.';

  @override
  String get completeProfileAction => 'Complete profile';

  @override
  String get editProfileImage => 'Edit account image';

  @override
  String get addFirstProject => 'Add your first project';

  @override
  String get addFirstProjectSubtitle =>
      'Show your work and attract new clients';

  @override
  String get verifyAccount => 'Verify your account';

  @override
  String get verifyAccountSubtitle =>
      'Give clients more confidence in your work';

  @override
  String get addWorkAreas => 'Add your work areas';

  @override
  String get addWorkAreasSubtitle => 'Get matched with the right opportunities';

  @override
  String get verificationPending => 'Under review';

  @override
  String get performanceEmptyTitle => 'Your performance will appear here';

  @override
  String get performanceEmptyMessage =>
      'Complete your profile and add a project to start tracking client engagement.';

  @override
  String get proCardTitle => 'Shattab Pro';

  @override
  String get proCardSubtitle =>
      'Reach more clients and make your work easier to discover.';

  @override
  String get proLearnMore => 'Learn more';

  @override
  String get proManageSubtitle =>
      'Manage your subscription and active benefits.';

  @override
  String get settingsEntryTitle => 'Settings and preferences';

  @override
  String get settingsEntrySubtitle => 'Control how the app works for you';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get settingsPreferencesSection => 'Preferences';

  @override
  String get settingsSupportSection => 'Support and legal';

  @override
  String get settingsAccountManagementSection => 'Account management';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle => 'Choose what feels right for you';

  @override
  String get appearanceDay => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceSystem => 'System';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle => 'Manage notification preferences';

  @override
  String get notificationsRequests => 'Job requests';

  @override
  String get notificationsMessages => 'Messages and updates';

  @override
  String get taglineNew => 'From first idea to final touch';

  @override
  String get otpHint => 'A 6-digit code';

  @override
  String get resendCode => 'Resend code';

  @override
  String get resendInSeconds => 'Resend in %s s';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get invalidOtp => 'The code you entered is incorrect';

  @override
  String get signOut => 'Sign out';

  @override
  String get unknownErrorRetry => 'Something went wrong, please try again.';

  @override
  String get chooseRoleTitle => 'Who are you?';

  @override
  String get roleHomeowner => 'Homeowner';

  @override
  String get roleHomeownerSub => 'Looking for a Professional to renovate';

  @override
  String get roleProfessional => 'Professional';

  @override
  String get roleContractorSub => 'Looking for jobs and new clients';

  @override
  String get apartmentTypeTitle => 'What type is your apartment?';

  @override
  String get apartmentStudio => 'Studio';

  @override
  String get apartmentOneBedroom => '1 Bedroom';

  @override
  String get apartmentTwoBedroom => '2 Bedrooms';

  @override
  String get apartmentThreeBedroomPlus => '3+ Bedrooms';

  @override
  String get apartmentDuplex => 'Duplex';

  @override
  String get apartmentVilla => 'Villa';

  @override
  String get apartmentPenthouse => 'Penthouse';

  @override
  String get locationTitle => 'Where are you?';

  @override
  String get cityLabel => 'City';

  @override
  String get districtLabel => 'District / Area';

  @override
  String get cityCairo => 'Cairo';

  @override
  String get cityGiza => 'Giza';

  @override
  String get cityAlexandria => 'Alexandria';

  @override
  String get cityNewCairo => 'New Cairo';

  @override
  String get city6October => '6 October';

  @override
  String get cityNorthCoast => 'North Coast';

  @override
  String get interestsTitle => 'What do you need to renovate?';

  @override
  String get interestsSubtitle => 'Choose one or more';

  @override
  String get interestPaint => 'Paint';

  @override
  String get interestFlooring => 'Flooring';

  @override
  String get interestKitchen => 'Kitchen';

  @override
  String get interestBathroom => 'Bathroom';

  @override
  String get interestElectrical => 'Electrical';

  @override
  String get interestPlumbing => 'Plumbing';

  @override
  String get interestFullReno => 'Full renovation';

  @override
  String get businessNameTitle => 'Your company or business name';

  @override
  String get businessNameHint => 'Example: Al-Fannan Contracting';

  @override
  String get displayNameLabel => 'Responsible name';

  @override
  String get specialtiesTitle => 'What are your specialties?';

  @override
  String get specialtiesSubtitle => 'Select everything you do';

  @override
  String get serviceAreasTitle => 'Where do you work?';

  @override
  String get serviceAreasSubtitle => 'Select the governorates you cover';

  @override
  String get logoUploadTitle => 'Photo or logo for your business';

  @override
  String get logoUploadHint => 'Optional — you can skip it for now';

  @override
  String get chooseImage => 'Choose image';

  @override
  String get experienceTitle => 'Your experience and bio';

  @override
  String get yearsExperience => 'Years of experience';

  @override
  String get bioLabel => 'Short bio';

  @override
  String get bioHint => 'Tell us about your work in 2-3 lines';

  @override
  String get save => 'Save';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get comingSoon => 'Coming soon…';

  @override
  String get comingSoonM3 => 'This feature is being prepared';

  @override
  String get optional => '(optional)';

  @override
  String get tabDiscover => 'Professionals';

  @override
  String get tabRequests => 'My Requests';

  @override
  String get tabSaved => 'Saved';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabOpportunities => 'Jobs';

  @override
  String get tabInbox => 'Inbox';

  @override
  String get tabPortfolio => 'Portfolio';

  @override
  String get tabExplore => 'Projects';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCommunity => 'Community';

  @override
  String get sampleImagesLabel => 'Sample images';

  @override
  String get workInspirationTitle => 'Work inspiration';

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get exploreTitle => 'Projects';

  @override
  String get communityTitle => 'Shattab Community';

  @override
  String get communitySubtitle =>
      'Share your experience and get inspired by others.';

  @override
  String get communityNotificationsLabel => 'Notifications';

  @override
  String get communityFiltersLabel => 'Filter posts';

  @override
  String get communityFilterAll => 'All';

  @override
  String get communityFilterBeforeAfter => 'Before & after';

  @override
  String get communityFilterTips => 'Tips';

  @override
  String get communityFilterExperiences => 'Experiences';

  @override
  String get communityFilterRequests => 'Requests';

  @override
  String get communityCreatePrompt => 'What is on your mind about finishing?';

  @override
  String get communityCreatePost => 'Create a post';

  @override
  String get communityCreatePostTypeTitle => 'Choose a post type';

  @override
  String get communityPostKindStandard => 'Post';

  @override
  String get communityPostKindStandardDescription =>
      'Share a finishing experience or update';

  @override
  String get communityPostKindBeforeAfter => 'Before & after';

  @override
  String get communityPostKindBeforeAfterDescription =>
      'Show the difference with two photos';

  @override
  String get communityPostKindQuestion => 'Question';

  @override
  String get communityPostKindQuestionDescription =>
      'Ask the community for useful advice';

  @override
  String get communityPostKindTips => 'Tips';

  @override
  String get communityPostKindTipsDescription =>
      'Share a step or material that made a difference';

  @override
  String get communityPostKindExperiences => 'Experiences';

  @override
  String get communityPostKindExperiencesDescription =>
      'Tell the story of what you learned while finishing';

  @override
  String get communityCreatePostTypeSubtitle => 'Choose how you want to share';

  @override
  String get communityWritePostTitle => 'Write it your way';

  @override
  String get communityPublishCta => 'Share with the Shattab community';

  @override
  String get communityBeforeAfterNeedsImages =>
      'Add two photos to show before and after';

  @override
  String get communityPhotoAction => 'Photo';

  @override
  String get communityBeforeAfterAction => 'Before & after';

  @override
  String get communityBeforeLabel => 'Before';

  @override
  String get communityAfterLabel => 'After';

  @override
  String get communityQuestionAction => 'Question';

  @override
  String get communityPostMenuLabel => 'Post actions';

  @override
  String get communityLikePost => 'Like';

  @override
  String get communityUnlikePost => 'Unlike';

  @override
  String get communityCommentPost => 'Comments';

  @override
  String get communitySharePost => 'Share';

  @override
  String get communitySavePost => 'Save post';

  @override
  String get communityUnsavePost => 'Remove saved post';

  @override
  String get communityNoPostsTitle => 'No posts here yet';

  @override
  String get communityNoPostsMessage =>
      'Be the first to share a finishing experience or tip with the Shattab community.';

  @override
  String get communityPostsTitle => 'Community posts';

  @override
  String get communityPostsEmptyTitle => 'No shared posts yet';

  @override
  String get communityPostsEmptyMessage =>
      'Their experiences and tips will appear here when they share them with the Shattab community.';

  @override
  String get communityPostsLoadError =>
      'We couldn\'t load these posts right now';

  @override
  String get communityFeedErrorTitle =>
      'We couldn\'t load the community right now';

  @override
  String get communityFeedErrorMessage =>
      'Something temporary interrupted the feed. Try again in a moment.';

  @override
  String get communityFeedGuestErrorTitle => 'Sign in to open the community';

  @override
  String get communityFeedGuestErrorMessage =>
      'Signing in lets you see posts, interact with professionals, and save what matters to you.';

  @override
  String get communityClearFilter => 'Show all posts';

  @override
  String get communityLoadingMore => 'Loading more posts';

  @override
  String communityFilterAnnouncement(String filter) {
    return 'Post filter: $filter';
  }

  @override
  String get communityAuthorHomeowner => 'Homeowner';

  @override
  String get communityAuthorProfessional => 'Verified professional';

  @override
  String get communityMemberFallback => 'Community member';

  @override
  String communityTimePublic(String time) {
    return 'Posted $time';
  }

  @override
  String get createPost => 'Create Post';

  @override
  String get editPost => 'Edit Post';

  @override
  String get deletePost => 'Delete Post';

  @override
  String get postCaptionHint => 'Write a caption...';

  @override
  String get postCaptionLabel => 'Caption';

  @override
  String get addMedia => 'Add Photos';

  @override
  String get postTypeLabel => 'Post Type';

  @override
  String get postTypeProjectShowcase => 'Project Showcase';

  @override
  String get postTypeTip => 'Tip';

  @override
  String get postTypeMilestone => 'Milestone';

  @override
  String get postTypeRenovationUpdate => 'Renovation Update';

  @override
  String get postCategoryLabel => 'Category';

  @override
  String get postLinkPortfolio => 'Link to portfolio project';

  @override
  String get sharePost => 'Share';

  @override
  String get likeLabel => 'Like';

  @override
  String get commentLabel => 'Comment';

  @override
  String get saveLabel => 'Save';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentHint => 'Write a comment...';

  @override
  String get postComment => 'Post';

  @override
  String get noComments => 'No comments yet';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get noPostsYetSub => 'Be the first to post on Explore!';

  @override
  String get myPosts => 'My Posts';

  @override
  String get savedPosts => 'Saved Posts';

  @override
  String get myPostsEmpty => 'You have no posts yet';

  @override
  String get savedPostsEmpty => 'You haven\'t saved any posts';

  @override
  String get postUnavailable => 'This post is no longer available';

  @override
  String get postCreated => 'Post created';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get commentPosted => 'Comment posted';

  @override
  String get commentReply => 'Reply';

  @override
  String get commentLike => 'Like comment';

  @override
  String get commentUnlike => 'Unlike comment';

  @override
  String get editComment => 'Edit comment';

  @override
  String get deleteComment => 'Delete comment';

  @override
  String get deleteCommentConfirm =>
      'Are you sure you want to delete this comment?';

  @override
  String get commentUpdated => 'Comment updated';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get replyingToComment => 'Replying to a comment';

  @override
  String get commentEditedLabel => 'Edited';

  @override
  String get commentRateLimitError => 'Commenting too fast! Please wait.';

  @override
  String get captionRequired => 'Caption is required';

  @override
  String get photoCount => 'Photos: %s';

  @override
  String get agoNow => 'Just now';

  @override
  String get agoMin => '1 min ago';

  @override
  String get agoMins => '%s min ago';

  @override
  String get agoHour => '1 hour ago';

  @override
  String get agoHours => '%s hours ago';

  @override
  String get agoDay => '1 day ago';

  @override
  String get agoDays => '%s days ago';

  @override
  String get quotesSectionTitle => 'Quotes';

  @override
  String get sendQuote => 'Send Quote';

  @override
  String get yourQuote => 'Your Quote';

  @override
  String get editQuote => 'Edit Quote';

  @override
  String get submitQuote => 'Submit Quote';

  @override
  String get quoteSentSuccess => 'Quote sent successfully';

  @override
  String get priceFromLabel => 'Price from';

  @override
  String get priceToLabel => 'To';

  @override
  String get priceEgpHint => 'In EGP';

  @override
  String get priceOnRequest => 'Price after inspection';

  @override
  String get fixedPriceLabel => 'Fixed price';

  @override
  String get durationLabel => 'Expected duration';

  @override
  String get durationHint => 'Example: 2 weeks';

  @override
  String get quoteNoteLabel => 'Quote details';

  @override
  String get quoteNoteRequired => 'You must write the quote details';

  @override
  String get egpUnit => 'EGP';

  @override
  String get quoteAccept => 'Accept';

  @override
  String get quoteDecline => 'Decline';

  @override
  String get quoteAcceptConfirm => 'Accept this quote?';

  @override
  String get quoteDeclineConfirm => 'Decline this quote?';

  @override
  String get quoteStatusSent => 'Awaiting response';

  @override
  String get quoteStatusAccepted => 'Accepted';

  @override
  String get quoteStatusDeclined => 'Declined';

  @override
  String get quoteStatusWithdrawn => 'Withdrawn';

  @override
  String get noQuoteBadge => 'Needs response';

  @override
  String get noQuotesYet => 'No quotes yet for this request';

  @override
  String get viewContractorProfile => 'View profile';

  @override
  String get proPlanName => 'Pro';

  @override
  String get freePlanName => 'Free';

  @override
  String get paywallTitle => 'Pro Plan';

  @override
  String get proRequiredToQuoteTitle => 'Go Pro to send quotes';

  @override
  String get proBenefitQuotes => 'Unlimited quotes';

  @override
  String get proBenefitRanking => 'Higher ranking in search results';

  @override
  String get proBenefitPhotos => 'More portfolio photos';

  @override
  String get upgradeToProCta => 'Subscribe now';

  @override
  String get upgradeToProShort => 'Go Pro';

  @override
  String get perMonth => '/mo';

  @override
  String get paymentComingSoon => 'Payment is coming very soon.';

  @override
  String get currentPlanLabel => 'Your current plan';

  @override
  String get previewPublicProfile => 'Preview profile';

  @override
  String get memberSinceLabel => 'Member since';

  @override
  String get proActiveLine => 'Pro subscription active';

  @override
  String get sponsoredProfessionals => 'Featured professionals';

  @override
  String get paidPlacementLabel => 'Paid placement';

  @override
  String get specialProTitle => 'Featured placement';

  @override
  String get specialProSubtitle =>
      'Put your profile in a clear spot near the right clients';

  @override
  String get specialProValueLine =>
      'A visible space for your work without mixing paid reach with trust';

  @override
  String get specialProBenefit =>
      'Featured for 7 days in relevant results for your specialties and areas';

  @override
  String get specialProFairness =>
      'Ratings, verification, and completed work stay independent from payment';

  @override
  String get specialProPriceLine => 'EGP 199 for 7 days';

  @override
  String get specialProCta => 'Request featured placement';

  @override
  String get specialProActive => 'Featured placement is active';

  @override
  String specialProExpiresOn(String date) {
    return 'Featured placement runs until $date';
  }

  @override
  String get specialProPending => 'Placement request is under review';

  @override
  String get specialProPendingBody =>
      'We will review the transfer and activate placement after approval.';

  @override
  String get specialProActivationNote =>
      'After you upload the transfer proof, our team reviews the request manually.';

  @override
  String get specialProManage => 'Manage featured placement';

  @override
  String get specialProNoGuarantee =>
      'Placement helps clients find you, but it does not guarantee requests or ratings.';

  @override
  String get specialProScreenTitle => 'Your featured placement';

  @override
  String get paymentWeekly => 'Weekly';

  @override
  String get paySpecialPlacement => 'Request featured placement';

  @override
  String get paySpecialPlacementSub =>
      'EGP 199 for 7 days after transfer review';

  @override
  String get specialPlacementSubmittedTitle => 'Placement request sent';

  @override
  String get specialPlacementSubmittedBody =>
      'We will review the transfer and activate placement after approval.';

  @override
  String get specialPlacementDone => 'Back';

  @override
  String get specialPlacementAmountLabel => 'Featured placement price';

  @override
  String get specialPlacementUploadLabel => 'Upload transfer proof';

  @override
  String get specialPlacementReferenceLabel => 'Transfer reference (optional)';

  @override
  String get specialPlacementSubmit => 'Send request';

  @override
  String get specialPlacementTitle => 'Request featured placement';

  @override
  String get tierGold => 'Gold';

  @override
  String get tierSilver => 'Silver';

  @override
  String get tierBronze => 'Bronze';

  @override
  String get tierLevelPrefix => 'Level';

  @override
  String get tierHowTitle => 'How levels are earned';

  @override
  String get trustSectionTitle => 'Why trust this professional?';

  @override
  String get verifiedIdentity => 'Identity verified';

  @override
  String get verifiedIdentityTitle => 'What does verified mean?';

  @override
  String get verifiedIdentityBody =>
      'The Shattab team reviewed the identity documents submitted by this professional. This badge does not guarantee the result of every project or mean every piece of work was reviewed.';

  @override
  String get verifiedBusiness => 'Business verified';

  @override
  String get highlightTopRated => 'Top rated';

  @override
  String get highlightRecommended => 'Recommended';

  @override
  String get highlightEstablished => 'Proven track record';

  @override
  String get responseTimeLabel => 'Avg. response';

  @override
  String get completionRateLabel => 'Completion rate';

  @override
  String withinMinutes(int n) {
    return 'Within $n min';
  }

  @override
  String withinHours(int n) {
    return 'Within $n h';
  }

  @override
  String withinDays(int n) {
    return 'Within $n d';
  }

  @override
  String get reviewVerifiedChip => 'Verified review';

  @override
  String get ratingBreakdownTitle => 'Rating breakdown';

  @override
  String reviewsBasedOn(int n) {
    return 'From the latest $n reviews';
  }

  @override
  String get reviewSortNewest => 'Newest';

  @override
  String get reviewSortHighest => 'Highest';

  @override
  String get reviewSortLowest => 'Lowest';

  @override
  String get reviewFilterAll => 'All';

  @override
  String get reviewFilterWithText => 'With comment';

  @override
  String get reviewFilterWithPhotos => 'With photos';

  @override
  String get reviewsNoMatch => 'No reviews match this filter';

  @override
  String get reviewsClearFilter => 'Clear filter';

  @override
  String get ratingOutOfFive => 'out of 5';

  @override
  String get projectDurationLabel => 'Duration';

  @override
  String projectDurationMonths(int n) {
    return '$n months';
  }

  @override
  String get accountWelcome => 'Welcome';

  @override
  String get ratingCaption => 'Client rating';

  @override
  String get statJobs => 'Jobs';

  @override
  String get statLevel => 'Level';

  @override
  String get proBannerSubtitle => 'Exclusive features to grow your work';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get darkModeSubtitle => 'Comfortable dark theme';

  @override
  String get verifySubtitle => 'Earn the gold verified badge';

  @override
  String get languageSubtitle => 'Arabic or English';

  @override
  String get helpSubtitle => 'Message us on WhatsApp';

  @override
  String get verifyTileLabel => 'Verification';

  @override
  String get verifyStateVerified => 'Verified';

  @override
  String get verifyTitle => 'Get verified';

  @override
  String get verifyBenefitTrust => 'A verified badge on your profile';

  @override
  String get verifyBenefitRanking => 'Higher placement in search results';

  @override
  String get verifyBenefitFree => 'Completely free, one time';

  @override
  String get verifyUploadLabel => 'Upload your documents';

  @override
  String get verifyNoteLabel => 'Note (optional)';

  @override
  String get verifySubmit => 'Submit for review';

  @override
  String get verifyDocsRequired => 'Add at least one document photo';

  @override
  String get verifyError => 'Could not submit, try again';

  @override
  String get verifyPendingTitle => 'Your request is under review';

  @override
  String get verifyApprovedTitle => 'You are verified';

  @override
  String get verifyDone => 'Done';

  @override
  String get proScreenTitle => 'Shattab Pro';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planAnnual => 'Annual';

  @override
  String get annualSaveBadge => 'Save 2 months';

  @override
  String get perYear => '/yr';

  @override
  String get startFreeMonth => 'Start free month';

  @override
  String get cancelAnytime => 'Cancel anytime';

  @override
  String get proBenefitSeen => 'Alert when a client views your quote';

  @override
  String get trustPaymob => 'Payments by Paymob · secure';

  @override
  String get comparePlans => 'Free vs Pro';

  @override
  String get cmpQuotes => 'Quotes';

  @override
  String get cmpQuotesFree => '3 / month';

  @override
  String get cmpUnlimited => 'Unlimited';

  @override
  String get cmpRequests => 'Direct requests';

  @override
  String get cmpRequestsFree => 'Read only';

  @override
  String get cmpRequestsPro => 'Reply & quote';

  @override
  String get cmpRanking => 'Search ranking';

  @override
  String get cmpRankingFree => 'Normal';

  @override
  String get cmpRankingPro => 'Higher';

  @override
  String get cmpPortfolio => 'Portfolio';

  @override
  String get cmpPortfolioFree => '5 projects';

  @override
  String get cmpSeenRow => '\"Saw your quote\" alert';

  @override
  String proExpiresOn(String date) {
    return 'Renews on $date';
  }

  @override
  String get choosePaymentMethod => 'Choose payment method';

  @override
  String get payInstapay => 'InstaPay';

  @override
  String get payApplePay => 'Apple Pay';

  @override
  String get paySoonBadge => 'Soon';

  @override
  String get payApplePaySub => 'Card or wallet — coming soon';

  @override
  String get instapayTitle => 'Pay via InstaPay';

  @override
  String get instapayAmountLabel => 'Amount due';

  @override
  String get instapayNumberLabel => 'Transfer to this InstaPay number';

  @override
  String get copyAction => 'Copy';

  @override
  String get copiedToast => 'Copied';

  @override
  String get instapayUploadLabel => 'Upload transfer screenshot';

  @override
  String get instapayRefLabel => 'Transfer reference (optional)';

  @override
  String get instapaySubmit => 'Send for confirmation';

  @override
  String get instapayProofRequired => 'Upload the transfer screenshot first';

  @override
  String get instapaySubmittedTitle => 'Request under review';

  @override
  String get instapayDone => 'Done';

  @override
  String get instapayError => 'Something went wrong, try again';

  @override
  String get applePaySoon => 'Apple Pay is coming soon';

  @override
  String get inboxTitle => 'Direct Requests';

  @override
  String get inboxEmptyTitle => 'No direct requests';

  @override
  String get requestDetailTitle => 'Request Details';

  @override
  String get contactClient => 'Contact Client';

  @override
  String get requestsPageTitle => 'Requests';

  @override
  String requestsUsage(String used, String limit) {
    return 'You have used $used of $limit free offers in the last 30 days';
  }

  @override
  String get requestsProStatus =>
      'Pro is active — your offers and requests are available';

  @override
  String get requestsPlanRefreshError =>
      'We couldn\'t refresh your plan right now.';

  @override
  String get requestsPlanRetry => 'Refresh plan status';

  @override
  String get requestsOpenDetails => 'View request details';

  @override
  String get requestsQuoteType => 'Quote requested';

  @override
  String requestsPublishedOn(String date) {
    return 'Posted on $date';
  }

  @override
  String get requestsLockedWithPro => 'Available with Pro';

  @override
  String get requestsProContactAvailable =>
      'Contact details available with Pro';

  @override
  String get requestsProtectedContact => 'Contact details are protected';

  @override
  String get requestsLocationVisible => 'Request details are visible to you';

  @override
  String get requestsOtherTitle => 'More requests';

  @override
  String get requestsProHeadline => 'Is this request a fit for your work?';

  @override
  String get requestsProEmphasis => 'Don\'t let it pass you by.';

  @override
  String get requestsProDescription =>
      'Pro opens contact details and lets you send offers without a cap.';

  @override
  String get requestsBenefitContact => 'Contact details';

  @override
  String get requestsBenefitUnlimited => 'Unlimited offers';

  @override
  String get requestsBenefitRanking => 'Higher visibility in search';

  @override
  String requestsAnnualSaving(String amount) {
    return 'Save $amount EGP with annual billing';
  }

  @override
  String get requestsTrialBilling =>
      'Start with a free month, then billing follows your plan';

  @override
  String get requestsPaidBilling =>
      'Paid subscription — activation follows transfer confirmation';

  @override
  String get requestsCtaTrial => 'Open the request and start a free month';

  @override
  String get requestsCtaPaid => 'Open the request and subscribe to Pro';

  @override
  String get requestsPaymentNote =>
      'Secure payment — activation follows transfer review';

  @override
  String get requestsCheckoutFailed => 'We couldn\'t open checkout. Try again.';

  @override
  String get requestsProUnlocked =>
      'Pro is active — you can follow up and send your offer';

  @override
  String get myPortfolioTitle => 'My Portfolio';

  @override
  String get addWork => 'Add Work';

  @override
  String get newWorkTitle => 'New Work';

  @override
  String get editWorkTitle => 'Edit Work';

  @override
  String get portfolioEmptyTitle => 'No works added yet';

  @override
  String get workTitleLabel => 'Work title';

  @override
  String get workCategoryLabel => 'Category';

  @override
  String get workCategoryHint => 'Example: Full finishing';

  @override
  String get workYearLabel => 'Year';

  @override
  String get workYearHint => 'Example: 2025';

  @override
  String get workLocationLabel => 'Location';

  @override
  String get workLocationHint => 'Example: New Cairo';

  @override
  String get workDescriptionLabel => 'Description';

  @override
  String get workDescriptionHint => 'Write a short description';

  @override
  String get coverPhotoHint => 'The first photo will be the cover';

  @override
  String get saveWork => 'Save Work';

  @override
  String get deleteWork => 'Delete Work';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get coverRequired => 'You must add at least one photo';

  @override
  String get searchHint => 'Who are you looking for, or what do you need done?';

  @override
  String get discoverHeroKicker => 'The right people for your home';

  @override
  String get discoverHeroTitle => 'Professionals';

  @override
  String get discoverHeroSubtitle => 'Trusted people and visible work';

  @override
  String professionalsAvailable(int count) {
    return '$count professionals available';
  }

  @override
  String get trustedProfessionals => 'Trusted professionals';

  @override
  String get trustedProfessionalsHint =>
      'Based on real ratings and completed work';

  @override
  String get changeBrowseLocationShort => 'Change location';

  @override
  String get discoverPageTitle => 'Professionals';

  @override
  String get discoverSearchHint => 'Who are you looking for?';

  @override
  String get featuredProfessional => 'Featured professional';

  @override
  String get customerReviews => 'Customer reviews';

  @override
  String get completedProjectsShort => 'Completed projects';

  @override
  String get verifiedByShattab => 'Verified by Shattab';

  @override
  String get featuredContractors => 'Featured Professionals';

  @override
  String get topRated => 'Top Rated';

  @override
  String get topRatedCollectionDescription =>
      'Professionals with real customer ratings';

  @override
  String get noRatedProfessionalsMessage =>
      'There are no professionals with published ratings yet.';

  @override
  String get recentWorkTitle => 'Real work, beautifully done';

  @override
  String get allProfessionalsCollectionDescription =>
      'Every professional currently available on Shattab';

  @override
  String get nearbyProfessionalsCollectionDescription =>
      'Professionals who serve your area';

  @override
  String get nearYou => 'Near You';

  @override
  String nearYouIn(String city) {
    return 'Near you in $city';
  }

  @override
  String get browseByCategory => 'Browse by category';

  @override
  String get homeServicesTitle => 'Services';

  @override
  String get more => 'More';

  @override
  String get specialtyPaint => 'Painting';

  @override
  String get specialtyFlooring => 'Flooring';

  @override
  String get specialtyKitchen => 'Kitchens';

  @override
  String get specialtyBathroom => 'Bathrooms';

  @override
  String get specialtyElectrical => 'Electrical';

  @override
  String get specialtyPlumbing => 'Plumbing';

  @override
  String get specialtyCarpentry => 'Carpentry';

  @override
  String get specialtyDesign => 'Interior design';

  @override
  String get specialtyFullRenovation => 'Full renovation';

  @override
  String get shattabVerifiedProfessional => 'Verified by Shattab';

  @override
  String get trendingNearYou => 'Trending Near You';

  @override
  String get viewAll => 'View All';

  @override
  String get verified => 'Verified';

  @override
  String get allProfessionals => 'All Professionals';

  @override
  String get noContractorsTitle => 'No Professionals matching these criteria';

  @override
  String get noContractorsMessage => 'Try changing the specialty or city';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profilePhoneLabel => 'Phone number';

  @override
  String get phoneNotEditable => 'Phone number cannot be changed';

  @override
  String get changePhoto => 'Tap to change photo';

  @override
  String get housingData => 'Housing Data';

  @override
  String get interestAreas => 'Areas of Interest';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get saveProfile => 'Save';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileError => 'An error occurred, try again';

  @override
  String get selectCity => 'Select city';

  @override
  String get selectDistrict => 'Select district';

  @override
  String get editProfileButton => 'Edit Profile';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get profileTitle => 'Profile';

  @override
  String get signOutButton => 'Sign Out';

  @override
  String get signOutTitle => 'Confirm Sign Out';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get myRequests => 'My Requests';

  @override
  String get mySaved => 'Saved';

  @override
  String get discoverContractors => 'Discover Professionals';

  @override
  String get darkModeTitle => 'Dark Mode';

  @override
  String get lightModeTitle => 'Light Mode';

  @override
  String get motionLabel => 'Motion';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get briefDetailTitle => 'Request Details';

  @override
  String get briefLifecycleTitle => 'Your request journey';

  @override
  String get briefLifecycleRequestPosted => 'Request posted';

  @override
  String get briefLifecycleRequestPostedBody =>
      'Your request details are saved here so you can follow every update.';

  @override
  String get briefLifecycleWaitingForQuotes => 'Waiting for quotes';

  @override
  String get briefLifecycleWaitingForQuotesBody =>
      'New quotes will appear here as soon as they arrive.';

  @override
  String get briefLifecycleQuotesReceived => 'Quotes received';

  @override
  String get briefLifecycleQuotesReceivedBody =>
      'Review the quotes and choose the right professional for you.';

  @override
  String get briefLifecycleQuotesLoading => 'Updating quote status...';

  @override
  String get briefLifecycleQuotesError =>
      'We couldn\'t update quotes right now. Open the quotes section and try again.';

  @override
  String get briefLifecycleWorkStarted => 'Work started';

  @override
  String get briefLifecycleWorkStartedBody =>
      'The quote was accepted. Your next step is to follow the work.';

  @override
  String get briefLifecycleConfirmCompletion => 'Confirm the work is complete';

  @override
  String get briefLifecycleConfirmCompletionBody =>
      'Review the result and confirm when the work is finished.';

  @override
  String get briefLifecycleCompleted => 'Work completed';

  @override
  String get briefLifecycleCompletedBody =>
      'You can leave a verified review of your experience.';

  @override
  String get briefLifecycleCancelled => 'Request cancelled';

  @override
  String get briefLifecycleCancelledBody =>
      'This request is no longer available for new quotes.';

  @override
  String get briefNextStepQuotes => 'Review quotes and choose a professional';

  @override
  String get briefNextStepFollowWork => 'Follow the work in progress';

  @override
  String get briefNextStepConfirmWork => 'Review and confirm completion';

  @override
  String get briefNextStepReview => 'Share your verified review';

  @override
  String get cancelBriefTitle => 'Cancel request?';

  @override
  String get cancelBriefNo => 'No, keep it';

  @override
  String get cancelBriefYes => 'Yes, cancel';

  @override
  String get cancelButton => 'Cancel Request';

  @override
  String get briefNotFound => 'Request not found';

  @override
  String get tryAgain => 'Try again';

  @override
  String get locationDetailsLabel => 'Location Details';

  @override
  String get lookingForLabel => 'Looking for';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusPost => 'Public Post';

  @override
  String get statusDirectRequest => 'Direct Request';

  @override
  String get briefSentTitle => 'Your request has been sent!';

  @override
  String get doneBackToDiscover => 'Done, back to Discover';

  @override
  String get briefSentWhatsApp => 'Contact Professional on WhatsApp';

  @override
  String get briefSentCall => 'Call the Professional';

  @override
  String get briefSentBackToRequests => 'Back to my requests';

  @override
  String get createPostTitle => 'New Post';

  @override
  String get workTypeLabel => 'Work type';

  @override
  String get workTypeHint => 'Example: Bathroom renovation';

  @override
  String get apartmentTypeLabel => 'Unit type';

  @override
  String get budgetLabel => 'Budget (optional)';

  @override
  String get budgetHint => 'Example: 50000';

  @override
  String get timelineLabel => 'Timeline';

  @override
  String get timelineHint => 'Example: Within 2 weeks';

  @override
  String get descriptionLabel => 'Work details';

  @override
  String get descriptionHint => 'Write any additional details...';

  @override
  String get photosLabel => 'Photos (optional)';

  @override
  String get createPostButton => 'Publish Post';

  @override
  String get writeWhatYouNeed => 'Write what you need';

  @override
  String get sectionLookingForWho => 'Who are you looking for?';

  @override
  String get errorWriteMoreDetails => 'Write more details';

  @override
  String get errorFillApartmentCity => 'Fill in apartment type and city';

  @override
  String get errorSelectSpecialty => 'Select one or more specialties';

  @override
  String get sendBriefTitle => 'Send Direct Request';

  @override
  String get sendBriefDescriptionLabel => 'Work details';

  @override
  String get sendBriefPhotosLabel => 'Photos (optional)';

  @override
  String get sendBriefButton => 'Send Request';

  @override
  String get sendBriefDefaultTitle => 'Send project details';

  @override
  String get sendBriefProjectDetails => 'Your project details';

  @override
  String get sendBriefWorkDescLabel => 'Work description';

  @override
  String get sendBriefWorkDescHint => 'Example: Need full finishing…';

  @override
  String get myBriefsTitle => 'My Requests';

  @override
  String get newPostButton => 'New Post';

  @override
  String get noBriefsTitle => 'No requests yet';

  @override
  String get createNewPostButton => 'Create New Post';

  @override
  String get noBriefsHere => 'Nothing here yet';

  @override
  String get sectionOpenPosts => 'Open Posts';

  @override
  String get sectionDirectRequests => 'Direct Requests';

  @override
  String get opportunitiesTitle => 'Job Opportunities';

  @override
  String get noPostsTitle => 'No posts right now';

  @override
  String get postDetailTitle => 'Post Details';

  @override
  String get postDescriptionLabel => 'Work details';

  @override
  String get postLocationLabel => 'Location';

  @override
  String get homeownerLabel => 'Post owner';

  @override
  String get contactHomeowner => 'Contact post owner';

  @override
  String get sendQuoteButton => 'Send Quote';

  @override
  String get yourQuoteLabel => 'Your Quote';

  @override
  String get postNotFound => 'Post not found';

  @override
  String get postDetailPostedPrefix => 'Posted: ';

  @override
  String get clientInfoFailed => 'Failed to load client data';

  @override
  String get sendQuoteCTA => 'Send Quote';

  @override
  String get portfolioGalleryTitle => 'Portfolio Gallery';

  @override
  String get noWorksTitle => 'No works added yet';

  @override
  String get projectDetailTitle => 'Project Details';

  @override
  String get projectCategoryLabel => 'Category';

  @override
  String get projectYearLabel => 'Year';

  @override
  String get projectLocationLabel => 'Location';

  @override
  String get projectDescriptionLabel => 'Description';

  @override
  String get projectNotFound => 'Project not found';

  @override
  String get contractorProfileTitle => 'Professional Profile';

  @override
  String get ratingLabel => 'Rating';

  @override
  String get reviewsCount => 'Review';

  @override
  String get specialtiesLabel => 'Specialties';

  @override
  String get serviceAreasLabel => 'Service Areas';

  @override
  String get saveContractor => 'Save';

  @override
  String get savedContractor => 'Saved';

  @override
  String get sendBriefCTA => 'Send Request';

  @override
  String get viewPortfolio => 'View Portfolio';

  @override
  String get writeReviewTitle => 'Write a Review';

  @override
  String get reviewTitleLabel => 'Review title';

  @override
  String get reviewTitleHint => 'Example: Great work';

  @override
  String get reviewBodyLabel => 'Details';

  @override
  String get reviewBodyHint => 'Write about your experience...';

  @override
  String get reviewSubmit => 'Submit Review';

  @override
  String get reviewRequired => 'Title and details are required';

  @override
  String get reviewSuccess => 'Review submitted successfully';

  @override
  String get rateContractor => 'Rate Professional';

  @override
  String get yourReview => 'Your review (optional)';

  @override
  String get yourReviewHint => 'Tell us about your experience';

  @override
  String get submitReview => 'Submit Review';

  @override
  String get selectStarsFirst => 'Select a star rating first';

  @override
  String get editReview => 'Edit';

  @override
  String get ratingHelpsOthers => 'Your rating helps other clients';

  @override
  String get contactViaWhatsApp => 'Contact via WhatsApp';

  @override
  String get whatsappShort => 'WhatsApp';

  @override
  String get call => 'Call';

  @override
  String get phone => 'Phone';

  @override
  String get createPostPublishButton => 'Publish Post';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingPersonalized(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get newJobs => 'New Jobs';

  @override
  String get searchJobs => 'Search for a job...';

  @override
  String get filterToday => 'Today';

  @override
  String get filterNearest => 'Nearest';

  @override
  String get filterHighestBudget => 'Highest Budget';

  @override
  String get filterVerified => 'Verified Clients';

  @override
  String get filterUrgent => 'Urgent';

  @override
  String get filterPainting => 'Painting';

  @override
  String get filterElectrical => 'Electrical';

  @override
  String get filterPlumbing => 'Plumbing';

  @override
  String get filterFinishing => 'Finishing';

  @override
  String get filterBathrooms => 'Bathrooms';

  @override
  String get filterKitchens => 'Kitchens';

  @override
  String get urgentLabel => 'Urgent';

  @override
  String get newLabel => 'New';

  @override
  String get openJobs => 'Open Jobs';

  @override
  String get applicants => 'Applicants';

  @override
  String get budget => 'Budget';

  @override
  String get verifiedTrust => 'Verified';

  @override
  String get filter => 'Filter';

  @override
  String get apply => 'Apply';

  @override
  String get clearAll => 'Clear All';

  @override
  String filterWithCount(int count) {
    return 'Filter ($count)';
  }

  @override
  String get filterSort => 'Sort';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterCity => 'City';

  @override
  String get filterTime => 'Time';

  @override
  String get filterThisWeek => 'This Week';

  @override
  String get filterThisMonth => 'This Month';

  @override
  String get filterNewestFirst => 'Newest';

  @override
  String get noJobsTitle => 'No job opportunities right now';

  @override
  String get noJobsMatchSearchTitle => 'No job matches that search';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get editedMarker => 'Edited';

  @override
  String get withdrawQuote => 'Withdraw quote';

  @override
  String get quoteWithdrawn => 'Quote withdrawn';

  @override
  String get withdrawQuoteTitle => 'Withdraw this quote?';

  @override
  String get deleteBriefTitle => 'Delete this request?';

  @override
  String get briefDeleted => 'Request deleted';

  @override
  String get briefCancelledInstead => 'Request cancelled';

  @override
  String get editBriefTitle => 'Edit request';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get changesSaved => 'Changes saved';

  @override
  String get markWorkDone => 'I finished the work';

  @override
  String get confirmWorkDone => 'Work completed';

  @override
  String get awaitingHomeownerConfirm => 'Waiting for the homeowner to confirm';

  @override
  String get confirmCompletionTitle => 'Is the work really finished?';

  @override
  String get workCompletedNow => 'The job is now recorded as finished';

  @override
  String get completedLabel => 'Completed';

  @override
  String get workTypeSpecLabel => 'Work type';

  @override
  String get publishedSpecLabel => 'Posted';

  @override
  String get closePhotoViewer => 'Close photo';

  @override
  String get openPhotoViewer => 'Open photo';

  @override
  String photoIndexOf(int index, int total) {
    return '$index / $total';
  }

  @override
  String morePhotosCount(int count) {
    return '+$count';
  }

  @override
  String get debugMode => 'Debug Mode';

  @override
  String get demoLoginHomeowner => 'Login as Homeowner';

  @override
  String get demoLoginContractor => 'Login as Professional';

  @override
  String get networkError => 'No internet connection';

  @override
  String get somethingWentWrong => 'Something went wrong, try again';

  @override
  String get nameNotEnough => 'Name is not enough';

  @override
  String get nameExample => 'Example: Ahmed Ali';

  @override
  String get refreshHint => 'Pull down to refresh';

  @override
  String get yearsExperienceInvalid => 'Invalid years of experience';

  @override
  String get noSavedContractors => 'No saved Professionals yet';

  @override
  String get contractorNotFound => 'Professional not found';

  @override
  String get contractorNotFoundMsg => 'Account may have been deleted';

  @override
  String get projectDetails => 'Your Project Details';

  @override
  String get statusOpen => 'Open Post';

  @override
  String get statusDirect => 'Direct Request';

  @override
  String get newBadge => 'New';

  @override
  String get urgentBadge => 'Urgent';

  @override
  String get projects => 'Projects';

  @override
  String get singleProject => 'Project';

  @override
  String get year => 'Year';

  @override
  String get photos => 'Photos';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get saveTooltip => 'Save Professional';

  @override
  String get unsaveTooltip => 'Remove from saved';

  @override
  String get allSpecialties => 'All Specialties';

  @override
  String get allCities => 'All Cities';

  @override
  String get foundProfessionals => 'Professionals';

  @override
  String get editLabel => 'Edit';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get retry => 'Retry';

  @override
  String get noMoreResults => 'No more results';

  @override
  String get loading => 'Loading';

  @override
  String get loadingMore => 'Loading more...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get required => 'Required';

  @override
  String get minLabel => 'Min';

  @override
  String get maxLabel => 'Max';

  @override
  String get allRightsReserved => 'All rights reserved';

  @override
  String get activityPostedProject => 'Posted a new work request';

  @override
  String get activityAcceptedQuote => 'Accepted a quote';

  @override
  String get activityPaymentCompleted => 'Payment completed';

  @override
  String get activityNewReview => 'New review';

  @override
  String get activityDisputeOpened => 'Dispute opened';

  @override
  String get activityVerified => 'Verified';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get tooShort => 'Too short';

  @override
  String get tooLong => 'Too long';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get errAuthFailed => 'Login failed, try again';

  @override
  String get errOtpFailed => 'Wrong verification code, try again';

  @override
  String get errOtpExpired => 'Code expired, send a new one';

  @override
  String get errNetwork => 'No internet, check your connection';

  @override
  String get errServerError => 'Service unavailable, try again';

  @override
  String get errDataLoad => 'Error loading data';

  @override
  String get errDataSave => 'Error saving data';

  @override
  String get errSessionExpired => 'Session expired, log in again';

  @override
  String get errPermissionDenied => 'Permission denied';

  @override
  String get errNotFound => 'Not found';

  @override
  String get errPhotoUpload => 'Error uploading photos';

  @override
  String get errInvalidData => 'Invalid data, please check';

  @override
  String get portfolioAdd => 'Add Work';

  @override
  String get portfolioEdit => 'Edit Work';

  @override
  String get portfolioDelete => 'Delete Work';

  @override
  String get portfolioDeleteError => 'Error deleting work';

  @override
  String get postCreatedSuccess => 'Post created successfully';

  @override
  String get projectSavedSuccess => 'Project saved successfully';

  @override
  String get projectDeletedSuccess => 'Project deleted successfully';

  @override
  String get portfolioTitleLabel => 'Work title';

  @override
  String get portfolioTitleHint => 'Example: 150m² apartment finishing';

  @override
  String get portfolioCategoryLabel => 'Category';

  @override
  String get portfolioCategoryHint => 'Example: Finishing';

  @override
  String get portfolioYearLabel => 'Year';

  @override
  String get portfolioYearHint => 'Example: 2025';

  @override
  String get portfolioLocationLabel => 'Location';

  @override
  String get portfolioLocationHint => 'Example: Cairo';

  @override
  String get portfolioDescriptionLabel => 'Description';

  @override
  String get portfolioDescriptionHint => 'Detailed description...';

  @override
  String get portfolioCoverLabel => 'Cover photo';

  @override
  String get portfolioPhotosLabel => 'Work photos';

  @override
  String get portfolioSaved => 'Work saved';

  @override
  String get portfolioSaveError => 'Error saving work';

  @override
  String get photoMaxReached => 'Maximum photos reached';

  @override
  String get savedToast => 'Saved';

  @override
  String get unsavedToast => 'Removed from saved';

  @override
  String get motionFull => 'Full';

  @override
  String get motionReduced => 'Reduced';

  @override
  String get motionOff => 'Off';

  @override
  String get yourData => 'Your Data';

  @override
  String get apartmentType => 'Apartment Type';

  @override
  String get fillBothFields => 'Fill both fields';

  @override
  String get companyData => 'Company Data';

  @override
  String get companyName => 'Company / Professional Name';

  @override
  String get logo => 'Logo';

  @override
  String get professionalTitle => 'Professional Title';

  @override
  String get professionalTitleHint => 'Example: Luxury finishes and decor';

  @override
  String get bioInfo => 'About You';

  @override
  String get coverPhoto => 'Cover Photo';

  @override
  String get sendProjectDetails => 'Send your project details';

  @override
  String get aboutProfessional => 'About';

  @override
  String get requestPriceQuote => 'Request a quote';

  @override
  String get contactThroughShattab => 'Contact through Shattab';

  @override
  String get professionalWorkTitle => 'Real work, beautifully done';

  @override
  String get fromOurClients => 'From our clients';

  @override
  String get viewAllReviews => 'View all reviews';

  @override
  String get shattabClient => 'Shattab client';

  @override
  String get verifiedReviewFromCompletedJob =>
      'Verified review from a completed job';

  @override
  String get noPublicWorkYet => 'This professional has not published work yet.';

  @override
  String get contactPrivacyShareHint =>
      'Start a secure conversation through Shattab.';

  @override
  String get worksIn => 'Works in';

  @override
  String get newProfessional => 'New Professional';

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String get responseRate => 'Response Rate';

  @override
  String get projectsCompleted => 'Projects Completed';

  @override
  String get experienceYears => 'Years of Experience';

  @override
  String get continueWithApple => 'Sign in with Apple';

  @override
  String get professionals => 'Professionals';

  @override
  String get professionalSingular => 'Professional';

  @override
  String get providerKindContractor => 'Contractor';

  @override
  String get providerKindEngineer => 'Engineer';

  @override
  String get providerKindEngineeringOffice => 'Engineering office';

  @override
  String get providerKindFinishingCompany => 'Finishing company';

  @override
  String get providerKindInteriorDesigner => 'Interior designer';

  @override
  String get providerKindTradesman => 'Specialist tradesman';

  @override
  String get providerKindQuestion => 'What describes you best?';

  @override
  String get quotaReachedTitle => 'You have used your free quotes';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get legalSectionLabel => 'Legal';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportPostAction => 'Report post';

  @override
  String get reportSent => 'Report received — thank you';

  @override
  String get reportAlreadySent => 'You already reported this';

  @override
  String get reportReasonSpam => 'Spam or ads';

  @override
  String get reportReasonScam => 'Scam or fraud';

  @override
  String get reportReasonOffensive => 'Offensive content';

  @override
  String get reportReasonSexual => 'Sexual content';

  @override
  String get reportReasonViolence => 'Violence';

  @override
  String get reportReasonImpersonation => 'Impersonation';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get blockUser => 'Block';

  @override
  String get blockUserTitle => 'Block this user?';

  @override
  String get blockUserBody =>
      'You will not see their posts and they will not see yours. You can undo this at any time.';

  @override
  String get userBlocked => 'Blocked';

  @override
  String get unblockUser => 'Unblock';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Permanently delete your account?';

  @override
  String get deleteAccountBody =>
      'This erases your account and everything in it: your posts, requests, quotes, photos and reviews. This cannot be undone.';

  @override
  String get deleteAccountConfirmWord => 'DELETE';

  @override
  String get deleteAccountConfirmHint => 'Type DELETE to confirm';

  @override
  String get accountDeleted => 'Your account has been deleted';

  @override
  String get reviewsSheetTitle => 'Reviews';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get share => 'Share';

  @override
  String get copiedData => 'Data copied';

  @override
  String get seeOnShattab => 'View profile on Shattab: %s';

  @override
  String get forContact => 'Contact';

  @override
  String get clientsPreview => 'This is what clients see';

  @override
  String get tellUsAboutYourself => 'Tell us about yourself';

  @override
  String get fullNameHint => 'Full name';

  @override
  String get chooseRole => 'Choose account type';

  @override
  String minAgo(int n) {
    return '$n min ago';
  }

  @override
  String minsAgo(int n) {
    return '$n mins ago';
  }

  @override
  String hourAgo(int n) {
    return '$n hour ago';
  }

  @override
  String hoursAgo(int n) {
    return '$n hours ago';
  }

  @override
  String dayAgo(int n) {
    return '$n day ago';
  }

  @override
  String daysAgo(int n) {
    return '$n days ago';
  }

  @override
  String photosCount(int n) {
    return '$n photos';
  }

  @override
  String get briefSentMessageNew =>
      'The contractor received your project details and will contact you soon.\\nYou can call them on WhatsApp now if you want to speed things up.';

  @override
  String get cancelBriefMessage =>
      'It cannot be reactivated after cancellation.';

  @override
  String get chooseRoleSubtitle =>
      'Choose what fits you so we can tailor the experience';

  @override
  String get confirmCompletionBody =>
      'Once you confirm, the job is recorded as finished and you can rate the contractor. This can\'t be undone.';

  @override
  String get contractorSaysDone => 'The Professional says the work is finished';

  @override
  String get contractorsWillSeeMatched =>
      'Contractors whose specialties and areas match will see the post.';

  @override
  String get couldNotOpenApp =>
      'Couldn\'t open the app. Make sure it\'s installed.';

  @override
  String get deleteBriefBody => 'This can\'t be undone.';

  @override
  String get deleteBriefWithQuotesBody =>
      'Contractors have already sent quotes, so it will be cancelled rather than deleted, to preserve their work.';

  @override
  String get deletePostConfirm => 'Are you sure you want to delete this post?';

  @override
  String get deleteWorkConfirm => 'Are you sure you want to delete this work?';

  @override
  String get descriptionWorkHint =>
      'Example: I need someone to paint the entire apartment…';

  @override
  String get errorDescriptionShort =>
      'Write a description of at least 10 characters';

  @override
  String get heroSubtitle =>
      'Request the right service and receive quotes from verified contractors.';

  @override
  String get homeownerDetailsHint =>
      'So we can match you with the right contractors';

  @override
  String get inboxEmptyMessage =>
      'When a client sends you a direct request, it will appear here.';

  @override
  String get instapaySubmittedBody =>
      'We received your transfer. Pro activates after we confirm it, usually within 24 hours.';

  @override
  String get myPostsEmptySub =>
      'What you post on Explore shows up here, to edit or delete any time.';

  @override
  String get myQuotesEmptyMessage =>
      'Quotes you send on jobs will show up here';

  @override
  String get noBriefsHereMessage =>
      'Send a request to a specific contractor from their page, or create a public post.';

  @override
  String get noJobsMatchSearchMessage =>
      'Try another word, or clear the search to see every open job.';

  @override
  String get noJobsMessage =>
      'Try changing the filters or come back later. New opportunities appear regularly.';

  @override
  String get noReviewsYetSub =>
      'The first review arrives after the first finished job';

  @override
  String get noSavedContractorsMsg => 'Tap the save icon to come back later';

  @override
  String get noWorksMessage =>
      'The Professional will add their work here soon.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get payInstapaySub => 'Instant transfer from any bank or wallet';

  @override
  String get paywallSubtitle => 'Reach more clients and win more work.';

  @override
  String get phoneVisibleContractor =>
      'Your phone number will be visible to the contractor when they receive the request.';

  @override
  String get phoneVisibleContractors =>
      'Your phone number will be visible to contractors who see the post.';

  @override
  String get portfolioEmptyMessage =>
      'Show your work so clients can see your quality. Start by adding your first project.';

  @override
  String get portfolioLoadFailed => 'Couldn\'t load previous work';

  @override
  String get postUnavailableSub =>
      'It may have been deleted, or its owner made it private.';

  @override
  String get priceMinLessThanMax => 'Price from must be less than price to';

  @override
  String get proBenefitRequests => 'View job requests & contact details';

  @override
  String get profileGreeting =>
      'Hello, I saw your profile on Shattab and wanted to reach out';

  @override
  String get proRoiLine => 'One won job can cover the whole year';

  @override
  String get proValueLine => 'Keep the work coming, quotes without limits';

  @override
  String get providerKindHelp =>
      'This appears on your profile. You can change it any time.';

  @override
  String get quoteNoteHint =>
      'Write the quote details and any notes for the client';

  @override
  String get reportSheetSubtitle =>
      'Pick a reason. Every report is reviewed by a human.';

  @override
  String get reviewAfterCompletionHint =>
      'You can rate the contractor once you confirm the work is finished';

  @override
  String get savedPostsEmptySub =>
      'Tap the bookmark on any post to keep it here for later.';

  @override
  String get sendBriefAllDetailsHint =>
      'Send all the details the contractor needs to know';

  @override
  String get signInEmptyMessage =>
      'Your account keeps your activity and requests, on any device you sign in from.';

  @override
  String get signInToSeeSaved => 'Sign in to see your saved Professionals';

  @override
  String get verifyApprovedBody =>
      'The verified badge now shows on your profile.';

  @override
  String get verifyHeadline => 'Verify your account, earn client trust';

  @override
  String get verifyPendingBody =>
      'We are reviewing your documents and will verify you within 48 hours.';

  @override
  String get verifyPrivacyNote =>
      'Your documents are private and used only to verify you.';

  @override
  String get verifyUploadHint =>
      'National ID, plus trade licence or professional permit if you have one.';

  @override
  String get whatsappBriefGreeting => 'Hello, I sent you a request on Shattab';

  @override
  String get whatsappPostGreeting =>
      'Hello, I saw your post on Shattab and would like to know more about the work';

  @override
  String get whatsYourName => 'What\'s your name?';

  @override
  String get withdrawQuoteBody =>
      'The homeowner won\'t be able to accept it after you withdraw. You can send a new quote later.';

  @override
  String get workDoneRequested => 'The homeowner has been told you finished';

  @override
  String get workTitleHint => 'Example: Apartment finishing in Tagamo3';

  @override
  String get adjustOpportunityPreferences => 'Adjust opportunity preferences';

  @override
  String get budgetAndTimingTitle => 'Budget and start date';

  @override
  String get budgetAndTimingUnavailable =>
      'The homeowner has not provided a budget or start date yet. You can ask about both in your quote.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get competitionUnavailableHint =>
      'Competition level will appear when the opportunity exposes its offer count.';

  @override
  String get completeOpportunityPreferencesHint =>
      'Add your specialties and work areas so we can recommend better opportunities.';

  @override
  String get completeProfileBeforeApplying => 'Complete your profile first';

  @override
  String get distanceUnavailableHint =>
      'Matching currently uses your saved work areas. Distance in kilometres will be available after location is enabled.';

  @override
  String get filterAll => 'All';

  @override
  String get filterAllLocations => 'All locations';

  @override
  String get filterAnyTime => 'Any time';

  @override
  String get filterFresh => 'New';

  @override
  String get filterLocation => 'Location';

  @override
  String get filterNearYou => 'Your areas';

  @override
  String get filterNotApplied => 'Not applied';

  @override
  String get filterHideApplied => 'Hide opportunities I applied to';

  @override
  String get filterPublishedTime => 'Published';

  @override
  String get filtersApplyHint =>
      'Filters will apply to available opportunities.';

  @override
  String get followQuoteAction => 'Track quote';

  @override
  String get jobRadarTitle => 'Job radar';

  @override
  String get opportunitySummaryTitle => 'Opportunity summary';

  @override
  String get opportunitySummaryHeading => 'Your opportunity summary';

  @override
  String get opportunityCountLabel => 'matching opportunities';

  @override
  String get opportunityFreshCount => 'new';

  @override
  String get opportunityAreaCount => 'in your areas';

  @override
  String get opportunityWeekCount => 'This week';

  @override
  String get searchForMatchingOpportunities =>
      'Find opportunities that fit your work';

  @override
  String get opportunitySortTitle => 'Sort opportunities';

  @override
  String get opportunitySortRecommended => 'Best match';

  @override
  String get opportunitySortNewest => 'Newest';

  @override
  String opportunitySortLabel(String sort) {
    return 'Sort opportunities by $sort';
  }

  @override
  String opportunityFilterAction(int count) {
    return 'Filter opportunities, $count filters active';
  }

  @override
  String matchingOpportunitiesHeader(int count) {
    return 'You have $count opportunities that fit your work';
  }

  @override
  String opportunityCompactSummary(int count, int fresh, int area) {
    return '$count matches · $fresh new today · $area in your work areas';
  }

  @override
  String get projectPhotoLabel => 'Project photo';

  @override
  String get projectPhotoLoading => 'Loading project photo';

  @override
  String get opportunityMediaUnavailable => 'Project photo unavailable';

  @override
  String get loadMoreProgress => 'Loading more opportunities';

  @override
  String get loadMoreError => 'We could not load more opportunities';

  @override
  String latestOpportunityTime(String time) {
    return 'Latest matching opportunity was posted $time';
  }

  @override
  String get makeOpportunitiesMoreAccurate => 'Make your matches more accurate';

  @override
  String get matchDataInsufficient =>
      'Complete your specialties and work areas so we can explain each recommendation more accurately.';

  @override
  String get matchReasonFresh => 'Recently posted opportunity';

  @override
  String get matchReasonPhotos => 'Includes clear project photos';

  @override
  String get matchReasonPortfolio => 'Similar to work in your portfolio';

  @override
  String get matchReasonServiceArea => 'Located in one of your work areas';

  @override
  String get matchReasonSpecialty => 'Your specialty matches the request';

  @override
  String get moreMatchingOpportunities => 'More matching opportunities';

  @override
  String get newOpportunitiesForYou => 'new opportunities match you';

  @override
  String get noOpportunityMatches => 'No opportunities match these filters';

  @override
  String get noOpportunityMatchesHint =>
      'Try widening your search or clearing some filters. New matching opportunities will appear as they are posted.';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get opportunityAcceptingOffers => 'Accepting quotes';

  @override
  String get opportunityClosed => 'Opportunity closed';

  @override
  String get opportunityDetailsTitle => 'Opportunity details';

  @override
  String get opportunityFiltersTitle => 'Filter opportunities';

  @override
  String get opportunityOpen => 'Opportunity open';

  @override
  String get opportunityQuality => 'Opportunity quality';

  @override
  String get opportunityRemovedFromSaved => 'Opportunity removed from saved';

  @override
  String get opportunitySaved => 'Opportunity saved';

  @override
  String get opportunityTimeline => 'Opportunity timeline';

  @override
  String get opportunityViewed => 'Viewed before';

  @override
  String get ownerNoteTitle => 'Homeowner note';

  @override
  String get ownerPrivacyHint =>
      'Contact details remain private until communication starts through a quote.';

  @override
  String get projectDetailsTitle => 'Project details';

  @override
  String get quoteAlreadySent => 'Quote submitted';

  @override
  String get radarFresh => 'New today';

  @override
  String get radarInYourAreas => 'In your work areas';

  @override
  String get radarMatchesThisWeek => 'Matches this week';

  @override
  String get recommendedForYou => 'Recommended for you';

  @override
  String get relevantOpportunity => 'Relevant opportunity';

  @override
  String get removeOpportunityFromSaved => 'Remove opportunity from saved';

  @override
  String get resetFilters => 'Reset';

  @override
  String get clearAllFilters => 'Clear all filters';

  @override
  String get saveOpportunity => 'Save opportunity';

  @override
  String searchPreferencesCompletion(int percent) {
    return 'Search preferences $percent% complete';
  }

  @override
  String showOpportunityCount(int count) {
    return 'Show $count opportunities';
  }

  @override
  String get strongMatch => 'Strong match';

  @override
  String get submitYourQuote => 'Submit your quote';

  @override
  String get timelineAcceptOffers => 'Accepting quotes';

  @override
  String get timelineChooseContractor => 'Choose contractor';

  @override
  String get timelineStartWork => 'Start work';

  @override
  String get viewOpportunityDetails => 'View details';

  @override
  String get whyOpportunityMatches => 'Why does this opportunity match you?';

  @override
  String get youHaveNewOpportunities => 'You have';

  @override
  String get homeownerAccountRole => 'Homeowner';

  @override
  String get homeownerAreaFallback => 'Your preferred area';

  @override
  String get homeownerQuickActions => 'Quick actions';

  @override
  String get homeownerSettingsPreview => 'Your settings';

  @override
  String get homeownerAccountExperienceSection => 'Your account experience';

  @override
  String get homeownerEditProfileAction => 'Edit profile';

  @override
  String get homeownerDiscoverSubtitle => 'Find the right professional';

  @override
  String get homeownerRequestsSubtitle => 'Track your requests';

  @override
  String get homeownerSavedSubtitle => 'Your saved professionals';

  @override
  String get homeownerAppearanceRow => 'Appearance';

  @override
  String get homeownerMotionRow => 'Motion';

  @override
  String get homeownerLanguageRow => 'Language';

  @override
  String get homeownerSettingsRow => 'Settings and preferences';

  @override
  String get homeownerSettingsSubtitle => 'Control your app experience';

  @override
  String get homeownerLogoutSubtitle => 'You can come back anytime';

  @override
  String get homeownerSettingsExperienceSection => 'App experience';

  @override
  String get homeownerAppearanceAndMotionTitle => 'Appearance and motion';

  @override
  String get homeownerAppearanceAndMotionSubtitle =>
      'Choose the look and motion that suit you';

  @override
  String get homeownerLegalSection => 'Privacy and legal';

  @override
  String get homeownerPrivacySubtitle => 'Learn how we protect your data';

  @override
  String get homeownerTermsSubtitle => 'Review the Shattab terms';

  @override
  String get homeownerAccountSection => 'Account';

  @override
  String get homeownerDeleteSubtitle => 'Permanently remove account data';

  @override
  String get homeownerMotionTitle => 'Motion';

  @override
  String get homeownerMotionSubtitle => 'Control movement across the app';

  @override
  String get homeownerMotionAccessibility =>
      'If motion feels uncomfortable, choose reduced or off for a calmer interface.';

  @override
  String get homeownerSaveSettings => 'Save settings';

  @override
  String get homeownerLanguageChoose => 'Choose your app language';

  @override
  String get homeownerLanguageArabicHint => 'Arabic';

  @override
  String get homeownerLanguageEnglishHint => 'English';

  @override
  String get homeownerLanguagePreview => 'Text direction preview';

  @override
  String get homeownerLanguageLtr => 'LTR';

  @override
  String get homeownerLanguageRtl => 'RTL';

  @override
  String get homeownerSaveLanguage => 'Save language';

  @override
  String get homeownerPrivacyIntro =>
      'We protect your data and use it to provide a safer experience and better finishing recommendations.';

  @override
  String get homeownerTermsIntro =>
      'By using Shattab, you agree to the rules that govern the platform and your contact with professionals.';

  @override
  String get homeownerPrivacySection1Title => 'Data we collect';

  @override
  String get homeownerPrivacySection1Body =>
      'We use basic account data, home information, and finishing interests that you choose to share to run the service.';

  @override
  String get homeownerPrivacySection2Title => 'How we use your data';

  @override
  String get homeownerPrivacySection2Body =>
      'We use your data to recommend professionals, organize requests, improve the app, and provide support.';

  @override
  String get homeownerPrivacySection3Title => 'Protecting your data';

  @override
  String get homeownerPrivacySection3Body =>
      'We apply appropriate access and security controls, and we do not expose contact details on public profiles without a clear reason.';

  @override
  String get homeownerPrivacySection4Title => 'Your choices';

  @override
  String get homeownerPrivacySection4Body =>
      'You can edit your profile, control notifications, and request account deletion from your account settings.';

  @override
  String get homeownerPrivacySection5Title => 'Contact us';

  @override
  String get homeownerPrivacySection5Body =>
      'If you have a question about your data or privacy, contact our support team using the button below.';

  @override
  String get homeownerTermsSection1Title => 'Using Shattab';

  @override
  String get homeownerTermsSection1Body =>
      'Use Shattab lawfully and respectfully, and provide accurate information that helps professionals understand your request.';

  @override
  String get homeownerTermsSection2Title => 'Requests and contact';

  @override
  String get homeownerTermsSection2Body =>
      'The platform helps you reach professionals, but the final agreement and execution details remain with the parties involved.';

  @override
  String get homeownerTermsSection3Title => 'Content and photos';

  @override
  String get homeownerTermsSection3Body =>
      'Make sure you have the right to upload any photos and information, and never add content that violates someone else\'s rights.';

  @override
  String get homeownerTermsSection4Title => 'Independent professionals';

  @override
  String get homeownerTermsSection4Body =>
      'Professionals provide services independently. Review their profile and ratings and agree on the details before work begins.';

  @override
  String get homeownerTermsSection5Title => 'Terms updates';

  @override
  String get homeownerTermsSection5Body =>
      'We may update these terms as the service changes. Important changes will be explained inside the app.';

  @override
  String get homeownerContactSupport => 'Contact support';

  @override
  String get homeownerLogoutTitle => 'Sign out?';

  @override
  String get homeownerLogoutBody =>
      'You can sign in again anytime without losing your requests or saved professionals.';

  @override
  String get homeownerStaySignedIn => 'Stay signed in';

  @override
  String get homeownerOrdersAll => 'All';

  @override
  String get homeownerOrdersNew => 'New';

  @override
  String get homeownerOrdersActive => 'Active';

  @override
  String get homeownerOrdersCompleted => 'Completed';

  @override
  String get homeownerOrdersEmptyTitle => 'No requests yet';

  @override
  String get homeownerOrdersEmptyMessage =>
      'Once you contact a professional, you can follow the details here.';

  @override
  String get homeownerOrdersDiscoverAction => 'Discover professionals';

  @override
  String get homeownerOrdersBackToAccount => 'Back to my account';

  @override
  String get homeownerSavedEmptyTitle => 'No saved professionals';

  @override
  String get homeownerSavedEmptyMessage =>
      'Save the professionals you like so you can find them again easily.';

  @override
  String get homeownerSavedDiscoverAction => 'Discover professionals';

  @override
  String get homeownerSavedHint =>
      'Tap the bookmark on any professional to see them here.';

  @override
  String get changeLocation => 'Change browse location';

  @override
  String get changeLocationDescription =>
      'Choose a city to see professionals in that area';

  @override
  String get useProfileLocation => 'Use profile location';

  @override
  String get notificationInboxTitle => 'Notifications';

  @override
  String get notificationMarkAllRead => 'Mark all as read';

  @override
  String get notificationEmptyTitle => 'No new notifications';

  @override
  String get notificationEmptyBody =>
      'Updates about your requests and work will appear here.';

  @override
  String get notificationNewQuoteTitle => 'New quote';

  @override
  String get notificationNewQuoteBody =>
      'You received a new quote on your request.';

  @override
  String get notificationQuoteDecisionTitle => 'Update on your quote';

  @override
  String get notificationQuoteAcceptedBody =>
      'The homeowner accepted your quote.';

  @override
  String get notificationQuoteDeclinedBody =>
      'The homeowner chose another quote for this request.';

  @override
  String get notificationCompletionTitle => 'Work update';

  @override
  String get notificationCompletionRequestedBody =>
      'The professional marked the work as finished. Review the request details.';

  @override
  String get notificationJobCompletedBody =>
      'The project was confirmed complete.';

  @override
  String get notificationNewReviewTitle => 'New review';

  @override
  String get notificationNewReviewBody =>
      'A homeowner added a new review to your profile.';

  @override
  String get notificationVerificationTitle => 'Verification update';

  @override
  String get notificationVerificationApprovedBody =>
      'Your account was verified successfully.';

  @override
  String get notificationVerificationRejectedBody =>
      'Review the verification notes and submit again.';

  @override
  String get notificationPaymentTitle => 'Subscription update';

  @override
  String get notificationPaymentApprovedBody =>
      'Your subscription is now active.';

  @override
  String get notificationPaymentRejectedBody =>
      'Your payment request needs review.';

  @override
  String get notificationCommunityTitle => 'New activity';

  @override
  String get notificationPostLikedBody => 'Someone liked your post.';

  @override
  String get notificationPostCommentedBody => 'Someone commented on your post.';

  @override
  String get notificationCommentRepliedBody =>
      'Someone replied to your comment.';

  @override
  String get notificationCommentLikedBody => 'Someone liked your comment.';

  @override
  String get homeHeroTitleLead => 'Your home';

  @override
  String get homeHeroTitleRest => 'deserves someone who gets it right';

  @override
  String get homeHeroSubtitle => 'Trusted professionals, close to home';

  @override
  String get homeSearchHint => 'Search for a service or a professional...';

  @override
  String get homeQuickStartTitle => 'Start your request';

  @override
  String get homeQuickNearbyTitle => 'Professionals near you';

  @override
  String get homeQuickNearbySubtitle => 'Easier, faster contact';

  @override
  String get homeQuickRequestsTitle => 'Track your requests';

  @override
  String get homeQuickRequestsSubtitle => 'All in one place';

  @override
  String get homeQuickQuoteTitle => 'Request a quote';

  @override
  String get homeQuickQuoteSubtitle => 'Free and quick';

  @override
  String get homeActiveRequestTitle => 'Your current request';

  @override
  String get homeActiveRequestFallback =>
      'Your request is ready to follow up with professionals.';

  @override
  String get homeViewProfile => 'View profile';

  @override
  String get homeContactWhatsApp => 'Chat on WhatsApp';

  @override
  String get homeStartTitle => 'Start here';

  @override
  String get homeStartDiscoverTitle => 'Discover professionals';

  @override
  String get homeStartDiscoverSubtitle => 'Find the right fit for your home';

  @override
  String get homeStartQuoteTitle => 'Request a quote';

  @override
  String get homeStartQuoteSubtitle => 'Tell us what you need';

  @override
  String get homeStartWorkTitle => 'See real work';

  @override
  String get homeStartWorkSubtitle => 'Real projects, before and after';

  @override
  String get homeStartCommunityTitle => 'Ask the community';

  @override
  String get homeStartCommunitySubtitle =>
      'Real experiences and finishing tips';

  @override
  String get homeProcessTitle => 'From idea to execution';

  @override
  String get homeProcessStepOne => 'Share your needs';

  @override
  String get homeProcessStepOneBody => 'Tell us what you want to finish';

  @override
  String get homeProcessStepTwo => 'Choose your fit';

  @override
  String get homeProcessStepTwoBody => 'See real work and reach out';

  @override
  String get homeProcessStepThree => 'Start with confidence';

  @override
  String get homeProcessStepThreeBody => 'Follow your request step by step';

  @override
  String get homeCommunityInviteTitle => 'Ask the community';

  @override
  String get homeCommunityInviteBody =>
      'See real experiences from people who started where you are.';

  @override
  String get homeClosingCtaTitle => 'Ready to start?';

  @override
  String get homeClosingCtaBody =>
      'Tell us about your home and make the choice easier.';

  @override
  String get homeClosingCtaAction => 'Start your request';

  @override
  String get profileVerifiedStat => 'Verified & approved';

  @override
  String get profileAboutCompany => 'About the company';

  @override
  String get profileShowMore => 'Show more';

  @override
  String get profileShowLess => 'Show less';

  @override
  String get profileServicesTitle => 'Our services';

  @override
  String get profileHighlightsTitle => 'Featured work';

  @override
  String get profileProjectsTitle => 'Completed projects';

  @override
  String get profileTabAbout => 'About';

  @override
  String get profileTabWork => 'Work';

  @override
  String get profileTabReviews => 'Reviews';

  @override
  String get profileClosingTitle => 'Ready to start your project?';

  @override
  String get profileClosingBody => 'Get in touch now and receive a free quote.';

  @override
  String get profileClosingAction => 'Request a quote now';

  @override
  String get profileDirectCall => 'Call directly';

  @override
  String get profileFilterAll => 'All';

  @override
  String get homeLiveActivityTitle => 'Your request activity';

  @override
  String get homeLiveLatestActivity => 'Latest activity';

  @override
  String get homeLiveEmptyTitle => 'Nothing started yet';

  @override
  String get homeLiveEmptyMessage =>
      'Start a quick request and let the right professionals see what you need.';

  @override
  String get homeLiveStartAction => 'Start your request';

  @override
  String get homeLiveOpenRequests => 'View your requests';

  @override
  String get homeLiveOpenNotifications => 'View notifications';

  @override
  String get homeLiveErrorTitle => 'We could not get the latest update';

  @override
  String get homeLiveAwaitingOffers => 'Waiting for quotes';

  @override
  String get homeLiveWorkInProgress => 'Work in progress';

  @override
  String get homeLiveReviewCompletion => 'Review completion';

  @override
  String get homeLiveCompleted => 'Project complete';

  @override
  String get homeLiveRequestPosted => 'Posted';

  @override
  String homeLiveUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get quoteSentTitle => 'Your quote was sent';

  @override
  String get quoteSentMessage =>
      'The homeowner received your quote details. We will show you any updates here.';

  @override
  String get draftRestored => 'Your saved draft is ready';

  @override
  String get draftSavedAutomatically => 'Saved automatically on this device';

  @override
  String get trustEvidenceTitle => 'Evidence you can use';

  @override
  String get trustEvidenceBody =>
      'Review the signals we can verify before you start a conversation.';

  @override
  String get trustNewProfessional => 'New professional on Shattab';

  @override
  String get trustSafetyBody =>
      'If something feels unclear, review the details or contact Shattab before deciding.';

  @override
  String get profileSafetyTitle => 'Choose with clarity';

  @override
  String get profileSafetyBody =>
      'You can report or block this account, and Shattab support is here if you need help.';

  @override
  String get reportProfileAction => 'Report account';

  @override
  String get blockProfileAction => 'Block account';

  @override
  String get homeFeaturedEmptyTitle => 'We will recommend a professional soon';

  @override
  String get homeFeaturedEmptyMessage =>
      'As more verified work becomes available, this space will show a recommendation grounded in real evidence.';

  @override
  String get homeProjectsLoadErrorTitle =>
      'We could not show the work right now';

  @override
  String get homeProjectsLoadErrorMessage =>
      'Try again to see real projects from Shattab professionals.';

  @override
  String get homeProjectsEmptyTitle => 'Real work will appear here';

  @override
  String get homeProjectsEmptyMessage =>
      'Explore professional portfolios and see the details before you choose.';
}
