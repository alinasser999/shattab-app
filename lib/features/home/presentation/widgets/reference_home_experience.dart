import 'package:flutter/foundation.dart';
import '../../../discovery/domain/professional_reference_fixture.dart';
import '../../../discovery/presentation/widgets/professional_reference_components.dart'
    show ReferenceMedia, ReferencePremiumBadge;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import 'homeowner_reference_style.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../domain/reference_home_data.dart';
import 'home_live_states.dart';

typedef _T = HomeownerReferenceStyle;

class ReferenceHomeExperience extends StatelessWidget {
  const ReferenceHomeExperience({
    super.key,
    required this.locationLabel,
    required this.homeownerName,
    required this.avatarUrl,
    required this.unreadCount,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onAccountTap,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onStartProject,
    required this.onOpenAssistant,
    required this.onSelectService,
    required this.onOpenProject,
    required this.onOpenProjectOffers,
    required this.onOpenProjectDetails,
    required this.onOpenFeaturedProfessionals,
    required this.onOpenTopRated,
    required this.onOpenWork,
    required this.onOpenCompletedWork,
    required this.onOpenCommunity,
    required this.onOpenCommunityFeed,
    required this.onCreatePost,
    required this.onOpenClosingCta,
    required this.featuredProfessionals,
    required this.topRatedProfessionals,
    required this.project,
    required this.work,
    required this.communityPosts,
    required this.savedProfessionalIds,
    required this.onOpenProfessional,
    required this.onRequestQuote,
    required this.onToggleSaved,
    this.nearbyProfessionals = const [],
    this.kitchenProfessionals = const [],
    this.finishingProfessionals = const [],
    this.selectedServiceLabel,
    this.onServiceFilter,
    this.onFilters,
    this.onOpenNearby,
    this.onOpenKitchens,
    this.onOpenFinishing,
    this.showHeader = true,
    this.professionalsLoading = false,
    this.professionalsError,
    this.onRetryProfessionals,
    this.topRatedLoading = false,
    this.topRatedError,
    this.onRetryTopRated,
    this.workLoading = false,
    this.workError,
    this.onRetryWork,
    this.communityLoading = false,
    this.communityError,
    this.onRetryCommunity,
    this.showOfferCount = true,
    this.staticPreview = false,
  });

  final String locationLabel;
  final String homeownerName;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onAccountTap;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onStartProject;
  final VoidCallback onOpenAssistant;
  final ValueChanged<String> onSelectService;
  final ValueChanged<ReferenceHomeProject> onOpenProject;
  final ValueChanged<ReferenceHomeProject> onOpenProjectOffers;
  final ValueChanged<ReferenceHomeProject> onOpenProjectDetails;
  final VoidCallback onOpenFeaturedProfessionals;
  final VoidCallback onOpenTopRated;
  final ValueChanged<ReferenceHomeWork> onOpenWork;
  final VoidCallback onOpenCompletedWork;
  final ValueChanged<ReferenceHomeCommunityPost> onOpenCommunity;
  final VoidCallback onOpenCommunityFeed;
  final VoidCallback onCreatePost;
  final VoidCallback onOpenClosingCta;
  final List<ReferenceHomeProfessional> featuredProfessionals;
  final List<ReferenceHomeProfessional> topRatedProfessionals;
  final ReferenceHomeProject? project;
  final ReferenceHomeWork? work;
  final List<ReferenceHomeCommunityPost> communityPosts;
  final Set<String> savedProfessionalIds;
  final ValueChanged<String> onOpenProfessional;
  final ValueChanged<String> onRequestQuote;
  final ValueChanged<String> onToggleSaved;
  final List<ReferenceHomeProfessional> nearbyProfessionals,
      kitchenProfessionals,
      finishingProfessionals;
  final String? selectedServiceLabel;
  final VoidCallback? onServiceFilter,
      onFilters,
      onOpenNearby,
      onOpenKitchens,
      onOpenFinishing;
  final bool showHeader;
  final bool professionalsLoading;
  final String? professionalsError;
  final VoidCallback? onRetryProfessionals;
  final bool topRatedLoading;
  final String? topRatedError;
  final VoidCallback? onRetryTopRated;
  final bool workLoading;
  final String? workError;
  final VoidCallback? onRetryWork;
  final bool communityLoading;
  final String? communityError;
  final VoidCallback? onRetryCommunity;
  final bool showOfferCount;
  final bool staticPreview;

  @override
  Widget build(BuildContext context) => Theme(
    data: _T.scopedTheme(Theme.of(context)),
    child: Builder(
      builder: (context) {
        final stateCard = _ProjectCard(
          project: project,
          onStart: onStartProject,
          onExplore: onOpenFeaturedProfessionals,
          onAssistant: onOpenAssistant,
          onOpen: onOpenProject,
          onOffers: onOpenProjectOffers,
          onDetails: onOpenProjectDetails,
          showOfferCount: showOfferCount,
        );
        Widget collection(
          String key,
          String title,
          List<ReferenceHomeProfessional> items,
          VoidCallback onAll, {
          bool rows = false,
          bool cream = false,
          bool ranked = false,
        }) {
          final loading = ranked ? topRatedLoading : professionalsLoading;
          final error = ranked ? topRatedError : professionalsError;
          final retry = ranked ? onRetryTopRated : onRetryProfessionals;
          final body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Title(
                title,
                onAll,
                horizontalInset: cream ? 8 : 16,
                bottomGap: 8,
              ),
              if (key == 'home-clone-featured')
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                  child: Text(
                    referenceHomePreviewEnabled
                        ? context.l10n.homeCloneEditorialSubtitle
                        : context.l10n.homeCloneFeaturedSubtitle,
                    style: _T.text(13, color: _T.muted),
                  ),
                ),
              _SourceState(
                loading: loading,
                error: error,
                onRetry: retry,
                child: rows
                    ? _professionalRows(context, items, inset: cream ? 8 : 16)
                    : _professionalRail(context, items),
              ),
            ],
          );
          return Padding(
            key: ValueKey(key),
            padding: EdgeInsets.only(
              top: 20,
              left: cream ? 12 : 0,
              right: cream ? 12 : 0,
            ),
            child: cream
                ? Container(
                    decoration: BoxDecoration(
                      color: _T.cream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: body,
                  )
                : body,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeader)
              ReferenceHomeHeader(
                locationLabel: locationLabel,
                homeownerName: homeownerName,
                avatarUrl: avatarUrl,
                unreadCount: unreadCount,
                onLocationTap: onLocationTap,
                onNotificationTap: onNotificationTap,
                onAccountTap: onAccountTap,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HomeHero(
                homeownerName: homeownerName,
                locationLabel: locationLabel,
                onLocationTap: onLocationTap,
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
                onClear: onSearchClear,
              ),
            ),
            const SizedBox(height: 8),
            _Services(onSelect: onSelectService),
            const SizedBox(height: 8),
            if (staticPreview)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: stateCard,
              )
            else
              HomeLiveStateSection(
                onOpenRequests: project == null
                    ? onStartProject
                    : () => onOpenProject(project!),
                onOpenNotifications: onNotificationTap,
                onStartRequest: onStartProject,
                childHorizontalInset: 16,
                child: stateCard,
              ),
            if (project != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AssistantEntry(onTap: onOpenAssistant),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FilterToolbar(
                service:
                    selectedServiceLabel ?? context.l10n.homeCloneServiceAll,
                area: locationLabel,
                onService: onServiceFilter ?? onOpenFeaturedProfessionals,
                onArea: onLocationTap,
                onFilters: onFilters ?? onOpenFeaturedProfessionals,
              ),
            ),
            collection(
              'home-clone-featured',
              context.l10n.homeCloneFeatured,
              featuredProfessionals,
              onOpenFeaturedProfessionals,
            ),
            collection(
              'home-clone-nearby',
              context.l10n.homeCloneNearby,
              nearbyProfessionals,
              onOpenNearby ?? onOpenFeaturedProfessionals,
              rows: true,
              cream: true,
            ),
            _Title(
              work?.mediaKind == ReferenceHomeWorkMediaKind.verifiedBeforeAfter
                  ? context.l10n.homeCloneStory
                  : context.l10n.homeownerReferenceWorkTitle,
              onOpenCompletedWork,
              topGap: 20,
              bottomGap: 8,
            ),
            _SourceState(
              loading: workLoading,
              error: workError,
              onRetry: onRetryWork,
              child: work == null
                  ? _empty(context.l10n.statePublicWorksMessage)
                  : Padding(
                      key: const ValueKey('home-clone-story'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _WorkStory(
                        work: work!,
                        onTap: () => onOpenWork(work!),
                      ),
                    ),
            ),
            collection(
              'home-clone-top-rated',
              context.l10n.topRated,
              topRatedProfessionals,
              onOpenTopRated,
              rows: true,
              ranked: true,
            ),
            collection(
              'home-clone-kitchens',
              context.l10n.homeCloneKitchen,
              kitchenProfessionals,
              onOpenKitchens ?? onOpenFeaturedProfessionals,
            ),
            collection(
              'home-clone-finishing',
              context.l10n.homeCloneFinishing,
              finishingProfessionals,
              onOpenFinishing ?? onOpenFeaturedProfessionals,
            ),
            Padding(
              key: const ValueKey('home-clone-community'),
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: _T.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Title(
                      context.l10n.homeCloneCommunity,
                      onOpenCommunityFeed,
                      horizontalInset: 0,
                      bottomGap: 8,
                    ),
                    _SourceState(
                      loading: communityLoading,
                      error: communityError,
                      onRetry: onRetryCommunity,
                      child: communityPosts.isEmpty
                          ? _empty(
                              context.l10n.homeReferenceCommunityInviteBody,
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final stacked =
                                    constraints.maxWidth < 320 ||
                                    MediaQuery.textScalerOf(context).scale(1) >
                                        1.2;
                                final posts = communityPosts.take(2).toList();
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (final post in posts)
                                      SizedBox(
                                        width: stacked
                                            ? constraints.maxWidth
                                            : (constraints.maxWidth - 12) / 2,
                                        child: _CommunityCard(
                                          post: post,
                                          onTap: () => onOpenCommunity(post),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    _Action(
                      context.l10n.homeCloneShare,
                      onCreatePost,
                      primary: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    ),
  );
  Widget _professionalRail(
    BuildContext context,
    List<ReferenceHomeProfessional> items,
  ) => items.isEmpty
      ? _empty(context.l10n.noContractorsTitle)
      : LayoutBuilder(
          builder: (context, constraints) {
            final scaled = MediaQuery.textScalerOf(context).scale(1) > 1.2;
            final width = scaled
                ? (constraints.maxWidth - 48).clamp(220.0, 360.0)
                : (constraints.maxWidth - 32 - 10) / 2;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: SizedBox(
                        width: width,
                        child: _ProfessionalCard(
                          item: item,
                          saved: savedProfessionalIds.contains(item.id),
                          onOpen: () => onOpenProfessional(item.id),
                          onSave: () => onToggleSaved(item.id),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
  Widget _professionalRows(
    BuildContext context,
    List<ReferenceHomeProfessional> items, {
    required double inset,
  }) => items.isEmpty
      ? _empty(context.l10n.noContractorsTitle)
      : Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Column(
            children: [
              for (final item in items.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProfessionalRow(
                    item: item,
                    saved: savedProfessionalIds.contains(item.id),
                    onOpen: () => onOpenProfessional(item.id),
                    onSave: () => onToggleSaved(item.id),
                  ),
                ),
            ],
          ),
        );
}

Widget _empty(String label) => Padding(
  padding: const EdgeInsets.all(16),
  child: Text(label, style: _T.text(16, color: _T.muted)),
);

class ReferenceHomeHeader extends StatelessWidget {
  const ReferenceHomeHeader({
    super.key,
    required this.locationLabel,
    required this.homeownerName,
    required this.avatarUrl,
    required this.unreadCount,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onAccountTap,
    this.compactLocation = false,
  });
  final String locationLabel, homeownerName;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback onLocationTap, onNotificationTap, onAccountTap;
  final bool compactLocation;
  @override
  Widget build(BuildContext context) => Theme(
    data: _T.scopedTheme(Theme.of(context)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: LayoutBuilder(
          builder: (context, headerConstraints) {
            final brand = Semantics(
              image: true,
              label: context.l10n.appName,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                textDirection: TextDirection.ltr,
                children: [
                  Text(
                    context.l10n.appName,
                    style: _T.text(
                      24,
                      color: _T.orange,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.home_rounded, size: 24, color: _T.orange),
                ],
              ),
            );
            final brandPainter = TextPainter(
              text: TextSpan(
                text: context.l10n.appName,
                style: _T.text(24, weight: FontWeight.w800),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              locale: Localizations.localeOf(context),
            )..layout();
            final stackLocation =
                compactLocation &&
                brandPainter.width + 28 + 96 + 48 > headerConstraints.maxWidth;
            brandPainter.dispose();
            final locationControl = Tooltip(
              message: locationLabel,
              child: InkWell(
                onTap: onLocationTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: _T.orange,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              locationLabel,
                              style: _T.text(12),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (constraints.maxWidth >= 48)
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: _T.navy,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            final headerRow = Row(
              children: [
                brand,
                if (compactLocation && !stackLocation)
                  Expanded(child: locationControl)
                else
                  const Spacer(),
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  tooltip: context.l10n.notificationsTitle,
                  onPressed: onNotificationTap,
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: _T.navy,
                      size: 24,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: context.l10n.profileTitle,
                  child: InkWell(
                    onTap: onAccountTap,
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: _IdentityAvatar(
                          imageUrl: avatarUrl,
                          name: homeownerName,
                          radius: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [headerRow, if (stackLocation) locationControl],
            );
          },
        ),
      ),
    ),
  );
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.homeownerName,
    required this.locationLabel,
    required this.onLocationTap,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });
  final String homeownerName, locationLabel;
  final VoidCallback onLocationTap, onClear;
  final TextEditingController controller;
  final ValueChanged<String> onChanged, onSubmitted;
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('homeowner-architectural-hero'),
    constraints: const BoxConstraints(minHeight: 138),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xfff1e7d9),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Stack(
      children: [
        PositionedDirectional(
          start: 0,
          end: 0,
          top: 0,
          bottom: 0,
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(ReferenceHomePreviewData.heroImage),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Directionality.of(context) == TextDirection.rtl
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                end: Directionality.of(context) == TextDirection.rtl
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                colors: const [
                  Color(0xfff4eee5),
                  Color(0xeef4eee5),
                  Color(0x00f4eee5),
                ],
                stops: const [0, .45, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 0),
                child: Text(
                  context.l10n.homeCloneWelcome(homeownerName),
                  style: _T.text(16, weight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 4, 12),
                child: Text(
                  context.l10n.homeCloneHeroTitle,
                  style: _T.text(24, weight: FontWeight.w800),
                ),
              ),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        onSubmitted: onSubmitted,
                        textInputAction: TextInputAction.search,
                        style: _T.text(14),
                        decoration: InputDecoration(
                          hintText: context.l10n.homeownerReferenceSearchHint,
                          semanticCounterText:
                              context.l10n.homeownerReferenceSearchHint,
                          hintStyle: _T.text(14, color: _T.muted),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: _T.navy),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      tooltip: controller.text.isNotEmpty
                          ? context.l10n.clearSearch
                          : context.l10n.homeownerReferenceSearchHint,
                      onPressed: controller.text.isNotEmpty
                          ? onClear
                          : () => onSubmitted(controller.text),
                      icon: Icon(
                        controller.text.isNotEmpty ? Icons.close : Icons.search,
                        color: _T.navy,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AssistantEntry extends StatelessWidget {
  const _AssistantEntry({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: Color(0xffefeff1)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xff1684cf),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.homeownerAssistantEntryHint,
                      style: _T.text(12),
                    ),
                    Text(
                      context.l10n.homeownerAssistantEntryTitle,
                      style: _T.text(16, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left,
                size: 22,
                color: _T.navy,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onStart,
    required this.onExplore,
    required this.onAssistant,
    required this.onOpen,
    required this.onOffers,
    required this.onDetails,
    required this.showOfferCount,
  });
  final ReferenceHomeProject? project;
  final VoidCallback onStart, onExplore, onAssistant;
  final ValueChanged<ReferenceHomeProject> onOpen, onOffers, onDetails;
  final bool showOfferCount;
  @override
  Widget build(BuildContext context) {
    final p = project;
    if (p == null) {
      return _StarterCard(onStart: onStart, onAssistant: onAssistant);
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.home_outlined, color: _T.orange, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.homeReferenceProjectStatus,
                  style: _T.text(18, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(p.title, style: _T.text(16, weight: FontWeight.w700)),
          if (p.location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(p.location, style: _T.text(14, color: _T.muted)),
          ],
          const SizedBox(height: 4),
          Text(p.stage, style: _T.text(14)),
          if (showOfferCount)
            TextButton(
              onPressed: () => onOffers(p),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                alignment: AlignmentDirectional.centerStart,
                padding: EdgeInsets.zero,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: _T.navy,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      context.l10n.homeownerReferenceOffers(p.offerCount),
                      style: _T.text(14, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final primary = _Action(
                context.l10n.homeReferenceProjectFollow,
                () => onOpen(p),
              );
              final secondary = _Action(
                context.l10n.homeReferenceClosingAction,
                onStart,
                primary: false,
              );
              if (constraints.maxWidth >= 300 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.1) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: primary),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: secondary),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [primary, secondary],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({required this.onStart, required this.onAssistant});
  final VoidCallback onStart, onAssistant;
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('homeowner-start-project-card'),
    decoration: BoxDecoration(
      color: _T.cream,
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.1;
        final detail = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.homeCloneStartTitle,
              style: _T.text(18, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.homeCloneStartBody,
              style: _T.text(14, height: 1.4),
            ),
            const SizedBox(height: 4),
            _Action(context.l10n.homeReferenceHeroPrimary, onStart),
          ],
        );
        final image = Column(
          children: [
            ExcludeSemantics(
              child: SizedBox(
                height: 64,
                width: 110,
                child: Image.asset(
                  ReferenceHomePreviewData.projectImage,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            TextButton(
              onPressed: onAssistant,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                context.l10n.homeCloneAssistant,
                textAlign: TextAlign.center,
                style: _T.text(13, weight: FontWeight.w700),
              ),
            ),
          ],
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [detail, image],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: detail),
            const SizedBox(width: 8),
            SizedBox(width: 118, child: image),
          ],
        );
      },
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.onTap, {this.primary = true});
  final String label;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: primary ? _T.action : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: _T.text(
                16,
                color: primary ? Colors.white : _T.navy,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(
    this.title,
    this.onTap, {
    this.topGap = 0,
    this.bottomGap = 0,
    this.horizontalInset = 16,
  });
  final String title;
  final VoidCallback onTap;
  final double topGap, bottomGap, horizontalInset;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      horizontalInset,
      topGap,
      horizontalInset,
      bottomGap,
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: _T.text(18, weight: FontWeight.w800)),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsetsDirectional.only(start: 8),
            ),
            child: Text(context.l10n.viewAll, style: _T.text(14)),
          ),
        ],
      ),
    ),
  );
}

class _Services extends StatelessWidget {
  const _Services({required this.onSelect});
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        const keys = [
          'full_reno',
          'design',
          'kitchen',
          'electrical',
          'plumbing',
        ];
        final large = MediaQuery.textScalerOf(context).scale(1) > 1.1;
        final width = large
            ? (constraints.maxWidth - 24) / 3
            : (constraints.maxWidth - 40) / 5;
        return Wrap(
          spacing: large ? 12 : 10,
          runSpacing: 12,
          children: [
            for (final key in keys)
              SizedBox(
                width: width,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelect(key),
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CustomPaint(
                                  painter: _ServiceIconPainter(key),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              key == 'full_reno'
                                  ? context
                                        .l10n
                                        .homeReferenceServiceFullRenovationLabel
                                  : key == 'design'
                                  ? context
                                        .l10n
                                        .homeownerServiceDesignShortLabel
                                  : localizedSpecialtyLabel(context, key),
                              textAlign: TextAlign.center,
                              style: _T.text(13, weight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _ServiceIconPainter extends CustomPainter {
  const _ServiceIconPainter(this.service);
  final String service;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 28, size.height / 28);
    final p = Paint()
      ..color = _T.orange
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (service) {
      case 'full_reno':
        canvas.drawPath(
          Path()
            ..moveTo(3, 12)
            ..lineTo(14, 3)
            ..lineTo(25, 12)
            ..lineTo(25, 25)
            ..lineTo(18, 25)
            ..lineTo(18, 17)
            ..lineTo(10, 17)
            ..lineTo(10, 25)
            ..lineTo(3, 25)
            ..close(),
          p,
        );
      case 'design':
        canvas.drawRect(const Rect.fromLTWH(3, 3, 22, 22), p);
        canvas.drawPath(
          Path()
            ..moveTo(10, 3)
            ..lineTo(10, 19)
            ..lineTo(25, 19)
            ..moveTo(10, 11)
            ..lineTo(17, 11)
            ..lineTo(17, 3)
            ..moveTo(3, 16)
            ..lineTo(6, 16)
            ..moveTo(20, 7)
            ..lineTo(22, 7),
          p,
        );
      case 'kitchen':
        canvas.drawRect(const Rect.fromLTWH(3, 12, 22, 13), p);
        canvas.drawRect(const Rect.fromLTWH(10, 3, 8, 9), p);
        canvas.drawLine(const Offset(3, 17), const Offset(25, 17), p);
        canvas.drawLine(const Offset(14, 17), const Offset(14, 25), p);
        canvas.drawLine(const Offset(7, 21), const Offset(10, 21), p);
        canvas.drawLine(const Offset(18, 21), const Offset(21, 21), p);
      case 'electrical':
        canvas.drawPath(
          Path()
            ..moveTo(10, 20)
            ..lineTo(10, 17)
            ..cubicTo(3, 11, 8, 3, 14, 3)
            ..cubicTo(21, 3, 25, 11, 18, 17)
            ..lineTo(18, 20)
            ..close()
            ..moveTo(11, 24)
            ..lineTo(17, 24),
          p,
        );
      case 'plumbing':
        canvas.drawPath(
          Path()
            ..moveTo(17, 4)
            ..cubicTo(24, 0, 28, 8, 23, 12)
            ..lineTo(19, 12)
            ..lineTo(8, 24)
            ..quadraticBezierTo(3, 28, 2, 23)
            ..lineTo(15, 10)
            ..lineTo(14, 6)
            ..lineTo(18, 3)
            ..lineTo(18, 8)
            ..lineTo(22, 8)
            ..lineTo(23, 4),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ServiceIconPainter oldDelegate) =>
      oldDelegate.service != service;
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({
    required this.item,
    required this.saved,
    required this.onOpen,
    required this.onSave,
  });
  final ReferenceHomeProfessional item;
  final bool saved;
  final VoidCallback onOpen, onSave;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xffeef0f4)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 2,
          child: Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label:
                      '${context.l10n.homeReferenceViewProfile}: ${item.name}',
                  child: InkWell(
                    onTap: onOpen,
                    child: _Photo(url: item.coverPhotoUrl),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 0,
                end: 0,
                child: _SaveHeart(item: item, saved: saved, onSave: onSave),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IdentityAvatar(
                  imageUrl: item.avatarUrl,
                  name: item.name,
                  radius: 16,
                ),
                const SizedBox(width: 6),
                Expanded(child: _ProfessionalMetadata(item: item)),
              ],
            ),
          ),
        ),
        if (item.sponsored)
          const Padding(
            padding: EdgeInsets.all(6),
            child: ReferencePremiumBadge(readable: true),
          ),
      ],
    ),
  );
}

class _ProfessionalRow extends StatelessWidget {
  const _ProfessionalRow({
    required this.item,
    required this.saved,
    required this.onOpen,
    required this.onSave,
  });
  final ReferenceHomeProfessional item;
  final bool saved;
  final VoidCallback onOpen, onSave;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xffeef0f4)),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 76),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 0, 8),
                child: Row(
                  children: [
                    _IdentityAvatar(
                      imageUrl: item.avatarUrl,
                      name: item.name,
                      radius: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _ProfessionalMetadata(item: item)),
                  ],
                ),
              ),
            ),
          ),
          _SaveHeart(item: item, saved: saved, onSave: onSave),
        ],
      ),
    ),
  );
}

class _ProfessionalMetadata extends StatelessWidget {
  const _ProfessionalMetadata({required this.item});
  final ReferenceHomeProfessional item;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(item.name, style: _T.text(15, weight: FontWeight.w800)),
      Text(
        [
          localizedSpecialtyLabel(context, item.specialty),
          item.location,
        ].where((part) => part.isNotEmpty).join(' · '),
        style: _T.text(13, color: _T.muted, height: 1.4),
      ),
      if (item.reviewCount > 0)
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xffc47f00), size: 16),
            Text(
              item.rating.toStringAsFixed(1),
              textDirection: TextDirection.ltr,
              style: _T.text(13, weight: FontWeight.w700),
            ),
            Text(
              context.l10n.homeCloneReviews(item.reviewCount),
              style: _T.text(13, color: _T.muted),
            ),
          ],
        )
      else
        Text(
          context.l10n.homeCloneUnrated,
          style: _T.text(13, color: _T.muted),
        ),
      if (item.sponsored)
        Text(context.l10n.homeReferenceSponsored, style: _T.text(13)),
    ],
  );
}

class _SaveHeart extends StatelessWidget {
  const _SaveHeart({
    required this.item,
    required this.saved,
    required this.onSave,
  });
  final ReferenceHomeProfessional item;
  final bool saved;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: saved,
    child: IconButton(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      tooltip:
          '${saved ? context.l10n.unsaveTooltip : context.l10n.saveTooltip}: ${item.name}',
      onPressed: onSave,
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          saved ? Icons.favorite : Icons.favorite_border,
          color: _T.action,
          size: 22,
        ),
      ),
    ),
  );
}

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({
    required this.service,
    required this.area,
    required this.onService,
    required this.onArea,
    required this.onFilters,
  });
  final String service, area;
  final VoidCallback onService, onArea, onFilters;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wrap =
          constraints.maxWidth < 320 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.1;
      Widget button(
        String text,
        IconData icon,
        VoidCallback onTap,
        double width,
      ) => SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            side: const BorderSide(color: Color(0xffe4e8ef)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: _T.text(13, weight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: _T.navy),
            ],
          ),
        ),
      );
      if (wrap) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            button(service, Icons.expand_more, onService, constraints.maxWidth),
            button(
              area,
              Icons.location_on_outlined,
              onArea,
              (constraints.maxWidth - 8) / 2,
            ),
            button(
              context.l10n.homeCloneFilters,
              Icons.tune,
              onFilters,
              (constraints.maxWidth - 8) / 2,
            ),
          ],
        );
      }
      final width = (constraints.maxWidth - 16) / 3;
      return Row(
        children: [
          button(service, Icons.expand_more, onService, width),
          const SizedBox(width: 8),
          button(area, Icons.location_on_outlined, onArea, width),
          const SizedBox(width: 8),
          button(context.l10n.homeCloneFilters, Icons.tune, onFilters, width),
        ],
      );
    },
  );
}

class _WorkStory extends StatelessWidget {
  const _WorkStory({required this.work, required this.onTap});
  final ReferenceHomeWork work;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final pair =
        work.mediaKind == ReferenceHomeWorkMediaKind.verifiedBeforeAfter;
    Widget photo(String url, String? label) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Stack(
          children: [
            Positioned.fill(child: _Photo(url: url)),
            if (label != null)
              PositionedDirectional(
                bottom: 6,
                start: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: _T.navy,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    label,
                    style: _T.text(
                      13,
                      color: Colors.white,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pair)
              Row(
                children: [
                  Expanded(
                    child: photo(work.afterUrl, context.l10n.homeCloneAfter),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: photo(work.beforeUrl, context.l10n.homeCloneBefore),
                  ),
                ],
              )
            else
              photo(work.galleryUrls.firstOrNull ?? '', null),
            const SizedBox(height: 8),
            Text(work.title, style: _T.text(16, weight: FontWeight.w800)),
            Text(
              work.isPreview
                  ? context.l10n.homeCloneStoryBody
                  : [
                      localizedSpecialtyLabel(context, work.category),
                      work.location,
                    ].where((s) => s.isNotEmpty).join(' · '),
              style: _T.text(14, color: _T.muted, height: 1.4),
            ),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                alignment: AlignmentDirectional.centerStart,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                context.l10n.homeCloneStoryDetails,
                style: _T.text(14, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.post, required this.onTap});
  final ReferenceHomeCommunityPost post;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _IdentityAvatar(
                  imageUrl: post.authorAvatarUrl,
                  name: post.authorName,
                  radius: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    post.authorName,
                    style: _T.text(15, weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(post.caption, style: _T.text(14, height: 1.4)),
            if (post.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: _Photo(url: post.imageUrl),
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  post.isQuestion
                      ? context.l10n.homeCloneQuestion
                      : context.l10n.homeCloneReadStory,
                  style: _T.text(13, weight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SourceState extends StatelessWidget {
  const _SourceState({
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.child,
  });
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: _T.navy)),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(error!, style: _T.text(16)),
            if (onRetry != null)
              _Action(context.l10n.tryAgain, onRetry!, primary: false),
          ],
        ),
      );
    }
    return child;
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: const Color(0xffeeece7),
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          color: _T.muted,
          semanticLabel: context.l10n.homeownerReferencePhotoUnavailable,
        ),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    if (professionalReferenceEnabled) {
      if (url == ProfessionalReferenceFixture.livingRoomImage) {
        return const ReferenceMedia(
          url: 'assets/images/professional_reference_living_card.png',
          fit: BoxFit.cover,
        );
      }
      if (url == ProfessionalReferenceFixture.bathroomImage) {
        return const ReferenceMedia(
          url: 'assets/images/professional_reference_bathroom_card.png',
          fit: BoxFit.cover,
        );
      }
    }
    if ((referenceHomePreviewEnabled && url!.startsWith('assets/')) ||
        (kDebugMode &&
            ProfessionalReferenceFixture.allowedMediaPaths.contains(url))) {
      return Image.asset(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (!isDisplayableImageUrl(url)) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class _IdentityAvatar extends StatelessWidget {
  const _IdentityAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
  });
  final String? imageUrl;
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) {
    if ((referenceHomePreviewEnabled &&
            imageUrl?.startsWith('assets/images/home_clone_') == true) ||
        (kDebugMode &&
            ProfessionalReferenceFixture.allowedMediaPaths.contains(
              imageUrl,
            ))) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.asset(imageUrl!, fit: BoxFit.cover),
        ),
      );
    }
    return AvatarWithInitials(imageUrl: imageUrl, name: name, radius: radius);
  }
}
