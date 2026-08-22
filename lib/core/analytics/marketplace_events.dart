/// Stable, privacy-safe event names for the core marketplace funnel.
///
/// Keep properties about actions and outcomes, never names, IDs, contact
/// details, free text, or location. [AppAnalytics] applies a second sanitizer
/// at the write boundary as a guard against accidental leakage.
abstract final class MarketplaceEvents {
  static const homeViewed = 'home_viewed';
  static const discoverySearchSubmitted = 'discovery_search_submitted';
  static const discoverySpecialtySelected = 'discovery_specialty_selected';
  static const discoveryFiltersApplied = 'discovery_filters_applied';
  static const requestStarted = 'request_started';
  static const opportunityOpened = 'opportunity_opened';
  static const communityPostOpened = 'community_post_opened';
  static const communityPostShared = 'community_post_shared';
  static const communityAuthorProfileOpened = 'community_author_profile_opened';
  static const communityCommenterProfileOpened =
      'community_commenter_profile_opened';
  static const communityPostLiked = 'community_post_liked';
  static const communityPostSaved = 'community_post_saved';
  static const communityCommentLiked = 'community_comment_liked';
  static const communityCommentCreated = 'community_comment_created';
  static const communityCommentEdited = 'community_comment_edited';
  static const communityCommentDeleted = 'community_comment_deleted';
}
