import '../../discovery/domain/contractor_listing.dart';
import '../../../core/theme/professional_reference_theme.dart';
import '../../portfolio/presentation/providers/portfolio_providers.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/analytics/marketplace_events.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/domain/profile.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../briefs/domain/brief.dart';
import '../../briefs/presentation/providers/briefs_providers.dart';
import '../../contact_followup/presentation/widgets/professional_contact_review_card.dart';
import '../../contact_followup/presentation/providers/professional_contact_providers.dart';
import '../../discovery/presentation/providers/discovery_providers.dart';
import '../../explore/presentation/providers/explore_providers.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../../quotes/domain/quote.dart';
import '../../quotes/presentation/providers/quotes_providers.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import '../domain/reference_home_data.dart';
import 'widgets/reference_home_experience.dart';

/// The homeowner landing surface.
///
/// The visual composition lives in [ReferenceHomeExperience]. This screen is
/// deliberately the orchestration seam: it resolves existing repositories,
/// maps their domain models to the reference presentation models, and owns
/// every destination/action so the landing page never becomes a static mock.
class HomeownerHomeScreen extends ConsumerStatefulWidget {
  const HomeownerHomeScreen({super.key});

  @override
  ConsumerState<HomeownerHomeScreen> createState() =>
      _HomeownerHomeScreenState();
}

class _HomeownerHomeScreenState extends ConsumerState<HomeownerHomeScreen>
    with WidgetsBindingObserver {
  static const _contactReviewPollInterval = Duration(minutes: 5);

  late final TextEditingController _searchController;
  final Set<String> _previewSavedIds = <String>{};
  GoRouter? _router;
  Timer? _contactReviewPollTimer;
  bool _homeRouteActive = false;
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!referenceHomePreviewEnabled) {
      unawaited(AppAnalytics.track(MarketplaceEvents.homeViewed));
    }
    _searchController = TextEditingController(
      text: referenceHomePreviewEnabled
          ? ''
          : ref.read(discoveryFiltersControllerProvider).searchQuery ?? '',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (!identical(_router, router)) {
      _router?.routeInformationProvider.removeListener(_handleHomeRouteChange);
      _router = router;
      router.routeInformationProvider.addListener(_handleHomeRouteChange);
    }
    _handleHomeRouteChange();
  }

  @override
  void dispose() {
    _contactReviewPollTimer?.cancel();
    _router?.routeInformationProvider.removeListener(_handleHomeRouteChange);
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  bool get _isSignedInHomeowner {
    final session = ref.read(currentSessionProvider);
    final profile = ref.read(currentProfileProvider).asData?.value;
    return session != null &&
        profile?.id == session.user.id &&
        profile?.role == UserRole.homeowner;
  }

  void _handleHomeRouteChange() {
    final isHome =
        _router?.routeInformationProvider.value.uri.path ==
        Routes.homeownerHome;
    if (isHome == _homeRouteActive) return;

    _homeRouteActive = isHome;
    if (isHome) {
      _refreshContactReviewIfUnresolved();
      _ensureContactReviewPolling();
    } else {
      _contactReviewPollTimer?.cancel();
      _contactReviewPollTimer = null;
    }
  }

  void _refreshContactReviewIfUnresolved() {
    if (!mounted || !_isSignedInHomeowner) return;
    final current = ref.read(professionalContactEpisodeProvider);
    if (current.isLoading || current.asData?.value != null) return;
    ref.invalidate(professionalContactEpisodeProvider);
  }

  void _ensureContactReviewPolling() {
    if (!mounted ||
        !_homeRouteActive ||
        !_appResumed ||
        !_isSignedInHomeowner ||
        _contactReviewPollTimer != null) {
      return;
    }

    final current = ref.read(professionalContactEpisodeProvider);
    if (current.asData?.value != null) {
      _contactReviewPollTimer?.cancel();
      _contactReviewPollTimer = null;
      return;
    }
    if (current.isLoading) return;

    _contactReviewPollTimer = Timer.periodic(_contactReviewPollInterval, (_) {
      if (!mounted ||
          !_homeRouteActive ||
          !_appResumed ||
          !_isSignedInHomeowner) {
        _contactReviewPollTimer?.cancel();
        _contactReviewPollTimer = null;
        return;
      }

      final latest = ref.read(professionalContactEpisodeProvider);
      if (latest.asData?.value != null) {
        _contactReviewPollTimer?.cancel();
        _contactReviewPollTimer = null;
      } else if (!latest.isLoading) {
        ref.invalidate(professionalContactEpisodeProvider);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (!_appResumed) {
      _contactReviewPollTimer?.cancel();
      _contactReviewPollTimer = null;
      return;
    }

    if (_homeRouteActive) {
      _refreshContactReviewIfUnresolved();
      _ensureContactReviewPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve providers while the ConsumerState is building; the theme only
    // wraps rendering, so ref.listen retains its consumer lifecycle boundary.
    final content = _buildHome(context);
    return Theme(
      data: ProfessionalReferenceTheme.scopedTheme(Theme.of(context)),
      child: content,
    );
  }

  Widget _buildHome(BuildContext context) {
    if (referenceHomePreviewEnabled) return _buildPreviewHome(context);

    final preview = referenceHomePreviewEnabled;
    final profileState = ref.watch(currentProfileProvider);
    final homeownerState = ref.watch(homeownerProfileProvider);
    final briefsState = ref.watch(myBriefsProvider);
    final professionalsState = ref.watch(discoverContractorsProvider);
    final topRatedState = ref.watch(topRatedProfessionalsProvider);
    final workState = ref.watch(recentProjectsProvider);
    final communityState = ref.watch(exploreFeedProvider);
    final savedState = ref.watch(savedContractorIdsProvider);
    final unreadCount = ref.watch(unreadNotificationsProvider);
    final displayedUnreadCount = preview && unreadCount == 0 ? 1 : unreadCount;

    final profile = profileState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final session = ref.watch(currentSessionProvider);
    final showContactReview =
        session != null &&
        profile?.id == session.user.id &&
        profile?.role == UserRole.homeowner;
    if (showContactReview) {
      _ensureContactReviewPolling();
      ref.listen(professionalContactEpisodeProvider, (_, next) {
        if (next.asData?.value != null) {
          _contactReviewPollTimer?.cancel();
          _contactReviewPollTimer = null;
        } else {
          _ensureContactReviewPolling();
        }
      });
    } else {
      _contactReviewPollTimer?.cancel();
      _contactReviewPollTimer = null;
    }
    final homeowner = homeownerState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final briefs = briefsState.asData?.value ?? const <Brief>[];
    final activeBrief = _activeBrief(briefs);
    final quoteState = activeBrief == null
        ? null
        : ref.watch(quotesForBriefProvider(activeBrief.id));

    final professionalListings = professionalsState.asData?.value ?? const [];
    final topRatedListings = (topRatedState.asData?.value ?? const [])
        .where((listing) => listing.rating != null)
        .toList(growable: false);
    final workProjects = workState.asData?.value ?? const [];
    final posts = communityState.asData?.value ?? const [];

    // The compile-time preview intentionally wins over live rows so the
    // supplied reference composition remains reproducible for visual QA.
    // It is false in every normal build and never writes or claims anything
    // about the marketplace.
    final featuredProfessionals = preview
        ? ReferenceHomePreviewData.professionals
        : professionalListings.isNotEmpty
        ? professionalListings
              .take(3)
              .map(_mapProfessional)
              .toList(growable: false)
        : const <ReferenceHomeProfessional>[];
    final featuredIds = featuredProfessionals.map((item) => item.id).toSet();
    final topRatedIds = <String>{};
    final topRatedProfessionals =
        (preview
                ? ReferenceHomePreviewData.topRated
                : topRatedListings
                      .where(
                        (listing) =>
                            !featuredIds.contains(listing.id) &&
                            topRatedIds.add(listing.id),
                      )
                      .take(5)
                      .map(_mapProfessional))
            .where((item) => !featuredIds.contains(item.id))
            .toList(growable: false);
    final work = preview
        ? ReferenceHomePreviewData.work
        : workProjects.isNotEmpty
        ? ReferenceHomeWork.fromProject(workProjects.first)
        : null;
    final communityPosts = preview
        ? ReferenceHomePreviewData.communityPosts
        : posts.isNotEmpty
        ? posts
              .take(2)
              .map(
                (post) => ReferenceHomeCommunityPost.fromPost(
                  post,
                  timeLabel: _relativeTime(context, post.createdAt),
                ),
              )
              .toList(growable: false)
        : const <ReferenceHomeCommunityPost>[];

    final project = preview
        ? ReferenceHomePreviewData.project
        : activeBrief == null
        ? null
        : _mapBriefToProject(activeBrief, quoteState);
    final savedIds = <String>{
      ...(savedState.value ?? const <String>{}),
      ..._previewSavedIds,
    };
    final name = _displayName(context, profile?.fullName, preview);
    final location = _displayLocation(context, homeowner, preview);

    return BatshScaffold(
      showAppBar: false,
      padding: EdgeInsets.zero,
      backgroundColor: ProfessionalReferenceTheme.background,
      showPattern: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: ProfessionalReferenceTheme.background,
              border: Border(
                bottom: BorderSide(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
            ),
            child: ReferenceHomeHeader(
              locationLabel: location,
              homeownerName: name,
              avatarUrl:
                  profile?.avatarUrl ??
                  (preview
                      ? ReferenceHomePreviewData.topRated.first.avatarUrl
                      : null),
              unreadCount: displayedUnreadCount,
              onLocationTap: () => _openLocation(context),
              onNotificationTap: () => _openNotifications(context),
              onAccountTap: () => context.go(Routes.homeownerProfile),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              key: const PageStorageKey<String>('homeowner-home-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 0)),
                if (showContactReview)
                  const SliverToBoxAdapter(
                    child: ProfessionalContactReviewCard(),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: BatshSpacing.md),
                    child: ReferenceHomeExperience(
                      showHeader: false,
                      locationLabel: location,
                      homeownerName: name,
                      avatarUrl:
                          profile?.avatarUrl ??
                          (preview
                              ? 'assets/images/stitch_home_header_avatar.jpg'
                              : null),
                      unreadCount: displayedUnreadCount,
                      onLocationTap: () => _openLocation(context),
                      onNotificationTap: () => _openNotifications(context),
                      onAccountTap: () => context.go(Routes.homeownerProfile),
                      searchController: _searchController,
                      onSearchSubmitted: (value) =>
                          _submitSearch(context, value),
                      onSearchChanged: (_) => setState(() {}),
                      onSearchClear: () => _clearSearch(context),
                      onStartProject: () => _startProject(context),
                      onSelectService: (specialty) =>
                          _selectService(context, specialty),
                      onOpenProject: (item) => _openProject(context, item),
                      onOpenProjectOffers: (item) =>
                          _openProject(context, item),
                      onOpenProjectDetails: (item) =>
                          _openProject(context, item),
                      onOpenFeaturedProfessionals: () =>
                          context.go(Routes.homeownerDiscover),
                      onOpenTopRated: () =>
                          context.push(Routes.homeownerTopRatedProfessionals),
                      onOpenWork: (item) => _openWork(context, item),
                      onOpenCompletedWork: () =>
                          context.push(Routes.homeownerCompletedWork),
                      onOpenCommunity: (post) => _openCommunity(context, post),
                      onOpenCommunityFeed: () =>
                          context.go(Routes.homeownerExplore),
                      onCreatePost: () => _createCommunityPost(context),
                      onOpenClosingCta: () => _startProject(context),
                      featuredProfessionals: featuredProfessionals,
                      topRatedProfessionals: topRatedProfessionals,
                      project: project,
                      work: work,
                      communityPosts: communityPosts,
                      savedProfessionalIds: savedIds,
                      onOpenProfessional: (id) =>
                          _openProfessional(context, id),
                      onRequestQuote: (id) => _requestQuote(context, id),
                      onToggleSaved: (id) => _toggleSaved(context, id),
                      professionalsLoading:
                          !preview && professionalsState.isLoading,
                      professionalsError:
                          !preview && professionalsState.hasError
                          ? ErrorMapper.map(professionalsState.error!)
                          : null,
                      onRetryProfessionals: preview
                          ? null
                          : () => ref.invalidate(discoverContractorsProvider),
                      topRatedLoading: !preview && topRatedState.isLoading,
                      topRatedError: !preview && topRatedState.hasError
                          ? ErrorMapper.map(topRatedState.error!)
                          : null,
                      onRetryTopRated: preview
                          ? null
                          : () => ref.invalidate(topRatedProfessionalsProvider),
                      workLoading: !preview && workState.isLoading,
                      workError: !preview && workState.hasError
                          ? ErrorMapper.map(workState.error!)
                          : null,
                      onRetryWork: preview
                          ? null
                          : () => ref.invalidate(recentProjectsProvider),
                      communityLoading: !preview && communityState.isLoading,
                      communityError: !preview && communityState.hasError
                          ? ErrorMapper.map(communityState.error!)
                          : null,
                      onRetryCommunity: preview
                          ? null
                          : () => ref.invalidate(exploreFeedProvider),
                      showOfferCount:
                          preview ||
                          (quoteState?.hasValue == true &&
                              quoteState?.hasError != true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewHome(BuildContext context) {
    final name = _displayName(context, null, true);
    final location = context.l10n.cityNewCairo;
    const avatarUrl = 'assets/images/stitch_home_header_avatar.jpg';

    return BatshScaffold(
      showAppBar: false,
      padding: EdgeInsets.zero,
      backgroundColor: ProfessionalReferenceTheme.background,
      showPattern: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: ProfessionalReferenceTheme.background,
              border: Border(
                bottom: BorderSide(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
            ),
            child: ReferenceHomeHeader(
              locationLabel: location,
              homeownerName: name,
              avatarUrl: avatarUrl,
              unreadCount: 1,
              onLocationTap: () => _openLocation(context),
              onNotificationTap: () => _openNotifications(context),
              onAccountTap: () => context.go(Routes.homeownerProfile),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              key: const PageStorageKey<String>('homeowner-home-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 0)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: BatshSpacing.md),
                    child: ReferenceHomeExperience(
                      showHeader: false,
                      locationLabel: location,
                      homeownerName: name,
                      avatarUrl: avatarUrl,
                      unreadCount: 1,
                      onLocationTap: () => _openLocation(context),
                      onNotificationTap: () => _openNotifications(context),
                      onAccountTap: () => context.go(Routes.homeownerProfile),
                      searchController: _searchController,
                      onSearchSubmitted: (value) =>
                          _submitSearch(context, value),
                      onSearchChanged: (_) => setState(() {}),
                      onSearchClear: () => _clearSearch(context),
                      onStartProject: () => _startProject(context),
                      onSelectService: (specialty) =>
                          _selectService(context, specialty),
                      onOpenProject: (item) => _openProject(context, item),
                      onOpenProjectOffers: (item) =>
                          _openProject(context, item),
                      onOpenProjectDetails: (item) =>
                          _openProject(context, item),
                      onOpenFeaturedProfessionals: () =>
                          context.go(Routes.homeownerDiscover),
                      onOpenTopRated: () =>
                          context.push(Routes.homeownerTopRatedProfessionals),
                      onOpenWork: (item) => _openWork(context, item),
                      onOpenCompletedWork: () =>
                          context.push(Routes.homeownerCompletedWork),
                      onOpenCommunity: (post) => _openCommunity(context, post),
                      onOpenCommunityFeed: () =>
                          context.go(Routes.homeownerExplore),
                      onCreatePost: () => _createCommunityPost(context),
                      onOpenClosingCta: () => _startProject(context),
                      featuredProfessionals:
                          ReferenceHomePreviewData.professionals,
                      topRatedProfessionals: ReferenceHomePreviewData.topRated,
                      project: ReferenceHomePreviewData.project,
                      work: ReferenceHomePreviewData.work,
                      communityPosts: ReferenceHomePreviewData.communityPosts,
                      savedProfessionalIds: _previewSavedIds,
                      staticPreview: true,
                      onOpenProfessional: (id) =>
                          _openProfessional(context, id),
                      onRequestQuote: (id) => _requestQuote(context, id),
                      onToggleSaved: (id) => _toggleSaved(context, id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitSearch(BuildContext context, String value) {
    final query = value.trim();
    ref
        .read(discoveryFiltersControllerProvider.notifier)
        .setSearch(query.isEmpty ? null : query);
    context.go(Routes.homeownerDiscover);
  }

  void _clearSearch(BuildContext context) {
    _searchController.clear();
    ref.read(discoveryFiltersControllerProvider.notifier).setSearch(null);
    setState(() {});
  }

  void _selectService(BuildContext context, String specialty) {
    final normalizedSpecialty = specialty.trim();
    ref
        .read(discoveryFiltersControllerProvider.notifier)
        .setSpecialty(normalizedSpecialty.isEmpty ? null : normalizedSpecialty);
    context.go(Routes.homeownerDiscover);
  }

  void _openLocation(BuildContext context) {
    _runSignedIn(
      context,
      reason: context.l10n.changeLocationDescription,
      action: () => context.push(Routes.homeownerEditProfile),
    );
  }

  void _openNotifications(BuildContext context) {
    _runSignedIn(
      context,
      reason: context.l10n.notificationsTitle,
      action: () => context.push(Routes.notifications),
    );
  }

  void _startProject(BuildContext context) {
    _runSignedIn(
      context,
      reason: context.l10n.homeReferenceClosingTitle,
      action: () => context.push(Routes.homeownerNewPost),
    );
  }

  void _createCommunityPost(BuildContext context) {
    _runSignedIn(
      context,
      reason: context.l10n.homeReferenceWritePost,
      action: () => context.push(Routes.homeownerExploreCreatePost),
    );
  }

  void _openProfessional(BuildContext context, String id) {
    context.push(Routes.homeownerContractorProfilePath(id));
  }

  void _requestQuote(BuildContext context, String id) {
    if (id.startsWith('preview-')) {
      _startProject(context);
      return;
    }
    _runSignedIn(
      context,
      reason: context.l10n.homeReferenceRequestQuote,
      action: () => context.push(Routes.homeownerSendBriefPath(id)),
    );
  }

  void _toggleSaved(BuildContext context, String id) {
    if (id.startsWith('preview-')) {
      setState(() {
        if (!_previewSavedIds.add(id)) _previewSavedIds.remove(id);
      });
      return;
    }
    _runSignedIn(
      context,
      reason: context.l10n.saveTooltip,
      action: () =>
          unawaited(ref.read(savedControllerProvider.notifier).toggle(id)),
    );
  }

  void _openProject(BuildContext context, ReferenceHomeProject item) {
    if (item.isPreview) {
      context.go(Routes.homeownerRequests);
      return;
    }
    context.push(Routes.homeownerBriefDetailPath(item.id));
  }

  void _openWork(BuildContext context, ReferenceHomeWork item) {
    if (item.isPreview) {
      context.push(Routes.homeownerCompletedWork);
      return;
    }
    context.push(Routes.homeownerProjectDetailPath(item.contractorId, item.id));
  }

  void _openCommunity(BuildContext context, ReferenceHomeCommunityPost post) {
    if (post.isPreview) {
      context.go(Routes.homeownerExplore);
      return;
    }
    context.push(Routes.homeownerCommunityPostPath(post.id));
  }

  void _runSignedIn(
    BuildContext context, {
    required String reason,
    required VoidCallback action,
  }) {
    unawaited(runSignedIn(context, ref, reason: reason, action: action));
  }

  ReferenceHomeProject _mapBriefToProject(
    Brief brief,
    AsyncValue<List<Quote>>? quoteState,
  ) {
    final offerCount =
        quoteState?.maybeWhen(
          data: (quotes) => quotes
              .where((quote) => quote.status != QuoteStatus.withdrawn)
              .length,
          orElse: () => 0,
        ) ??
        0;
    final progress = switch (brief.stage) {
      BriefStage.open => 0.25,
      BriefStage.hired => 0.5,
      BriefStage.completionRequested => 0.8,
      BriefStage.completed => 1.0,
    };
    return ReferenceHomeProject(
      id: brief.id,
      title: brief.projectTitle?.trim().isNotEmpty == true
          ? brief.projectTitle!.trim()
          : brief.workDescription,
      location: [
        brief.district,
        brief.city,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join('، '),
      imageUrl: brief.photoUrls.firstOrNull ?? '',
      progress: progress,
      stage: _stageLabel(context, brief.stage),
      offerCount: offerCount,
    );
  }

  String _stageLabel(BuildContext context, BriefStage stage) {
    return switch (stage) {
      BriefStage.open => context.l10n.homeReferenceStageOpen,
      BriefStage.hired => context.l10n.homeReferenceStageHired,
      BriefStage.completionRequested => context.l10n.homeReferenceStageReview,
      BriefStage.completed => context.l10n.homeReferenceStageCompleted,
    };
  }

  String _displayName(BuildContext context, String? value, bool preview) {
    final name = value?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (preview) return 'أحمد';
    return context.l10n.homeownerAccountRole;
  }

  String _displayLocation(
    BuildContext context,
    dynamic homeowner,
    bool preview,
  ) {
    final parts = <String?>[homeowner?.district, homeowner?.city]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isNotEmpty) return parts.join('، ');
    return preview
        ? context.l10n.cityNewCairo
        : context.l10n.homeReferenceLocationUnset;
  }

  ReferenceHomeProfessional _mapProfessional(ContractorListing listing) {
    final mapped = ReferenceHomeProfessional.fromListing(listing);
    if (mapped.coverPhotoUrl?.trim().isNotEmpty == true) return mapped;
    final portfolio = ref
        .watch(portfolioForContractorProvider(mapped.id))
        .asData
        ?.value;
    final matching = portfolio
        ?.where(
          (project) =>
              project.contractorId == mapped.id &&
              project.coverPhotoUrl.trim().isNotEmpty,
        )
        .firstOrNull;
    if (matching == null) return mapped;
    return ReferenceHomeProfessional(
      id: mapped.id,
      name: mapped.name,
      specialty: mapped.specialty,
      location: mapped.location,
      avatarUrl: mapped.avatarUrl,
      coverPhotoUrl: matching.coverPhotoUrl,
      rating: mapped.rating,
      reviewCount: mapped.reviewCount,
      projectsCompleted: mapped.projectsCompleted,
      verified: mapped.verified,
      sponsored: mapped.sponsored,
    );
  }

  Brief? _activeBrief(List<Brief> briefs) {
    for (final brief in briefs) {
      if ((brief.status == BriefStatus.open && !brief.isCompleted) ||
          brief.awaitsCompletionConfirmation) {
        return brief;
      }
    }
    return null;
  }

  String _relativeTime(BuildContext context, DateTime dateTime) {
    final elapsed = DateTime.now().difference(dateTime);
    if (elapsed.inSeconds < 60) return context.l10n.agoNow;
    if (elapsed.inMinutes < 60) {
      final value = elapsed.inMinutes;
      final template = value == 1 ? context.l10n.agoMin : context.l10n.agoMins;
      return template.replaceFirst('%s', _arabicDigits(value));
    }
    if (elapsed.inHours < 24) {
      final value = elapsed.inHours;
      final template = value == 1
          ? context.l10n.agoHour
          : context.l10n.agoHours;
      return template.replaceFirst('%s', _arabicDigits(value));
    }
    final value = elapsed.inDays;
    final template = value == 1 ? context.l10n.agoDay : context.l10n.agoDays;
    return template.replaceFirst('%s', _arabicDigits(value));
  }

  String _arabicDigits(int value) {
    const latin = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    return value
        .toString()
        .split('')
        .map((digit) => arabic[latin.indexOf(digit)])
        .join();
  }
}
