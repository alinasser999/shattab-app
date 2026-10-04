import 'package:flutter/foundation.dart';
import '../../../discovery/domain/professional_reference_fixture.dart';
import '../../../discovery/presentation/widgets/professional_reference_components.dart'
    show ReferenceMedia, ReferencePremiumSurface, ReferencePremiumBadge;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/professional_reference_theme.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/widgets/professional_reference_primitives.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../domain/reference_home_data.dart';
import 'home_live_states.dart';

typedef _T = ProfessionalReferenceTheme;

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
          onOpen: onOpenProject,
          onOffers: onOpenProjectOffers,
          onDetails: onOpenProjectDetails,
          showOfferCount: showOfferCount,
        );
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: ProfessionalReferenceSearch(
                controller: searchController,
                hint: context.l10n.homeownerReferenceSearchHint,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
                onClear: onSearchClear,
              ),
            ),
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
            _Title(
              context.l10n.homeReferenceServicesTitle,
              onOpenFeaturedProfessionals,
            ),
            _Services(onSelect: onSelectService),
            _Title(
              context.l10n.homeownerReferenceProfessionalsTitle,
              onOpenFeaturedProfessionals,
            ),
            _SourceState(
              loading: professionalsLoading,
              error: professionalsError,
              onRetry: onRetryProfessionals,
              child: _professionalRail(context, featuredProfessionals),
            ),
            _Title(
              context.l10n.homeownerReferenceWorkTitle,
              onOpenCompletedWork,
            ),
            _SourceState(
              loading: workLoading,
              error: workError,
              onRetry: onRetryWork,
              child: work == null
                  ? _empty(context.l10n.noWorksMessage)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _EditorialCard(
                        title: work!.title,
                        detail: work!.location,
                        photo: work!.galleryUrls.firstOrNull ?? work!.afterUrl,
                        action: context.l10n.homeReferenceCaseDetails,
                        onTap: () => onOpenWork(work!),
                      ),
                    ),
            ),
            if (topRatedLoading ||
                topRatedError != null ||
                topRatedProfessionals.isNotEmpty) ...[
              _Title(context.l10n.topRated, onOpenTopRated),
              _SourceState(
                loading: topRatedLoading,
                error: topRatedError,
                onRetry: onRetryTopRated,
                child: _professionalRail(context, topRatedProfessionals),
              ),
            ],
            _Title(
              context.l10n.homeReferenceCommunityTitle,
              onOpenCommunityFeed,
            ),
            _SourceState(
              loading: communityLoading,
              error: communityError,
              onRetry: onRetryCommunity,
              child: Column(
                children: [
                  for (final post in communityPosts)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _EditorialCard(
                        title: post.authorName,
                        detail: post.caption,
                        photo: post.imageUrl,
                        action: post.timeLabel,
                        onTap: () => onOpenCommunity(post),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _T.cream,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.l10n.homeReferenceCommunityInviteTitle,
                            style: _T.text(20, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.homeReferenceCommunityInviteBody,
                            style: _T.text(16, color: _T.muted),
                          ),
                          const SizedBox(height: 12),
                          _Action(
                            context.l10n.homeReferenceWritePost,
                            onCreatePost,
                            primary: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
      : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: SizedBox(
                      width: 264,
                      child: _ProfessionalCard(
                        item: item,
                        saved: savedProfessionalIds.contains(item.id),
                        onOpen: () => onOpenProfessional(item.id),
                        onQuote: () => onRequestQuote(item.id),
                        onSave: () => onToggleSaved(item.id),
                      ),
                    ),
                  ),
              ],
            ),
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
  });
  final String locationLabel, homeownerName;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback onLocationTap, onNotificationTap, onAccountTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ProfessionalReferenceBrand(label: context.l10n.appName),
            const Spacer(),
            IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              visualDensity: VisualDensity.standard,
              tooltip: context.l10n.notificationsTitle,
              onPressed: onNotificationTap,
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: _T.navy,
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
                      radius: 19,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.greetingPersonalized(
            context.l10n.greetingEvening,
            homeownerName,
          ),
          style: _T.text(22, weight: FontWeight.w800),
        ),
        InkWell(
          onTap: onLocationTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: _T.orange,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationLabel,
                    style: _T.text(14, color: _T.muted),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: _T.navy),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onStart,
    required this.onExplore,
    required this.onOpen,
    required this.onOffers,
    required this.onDetails,
    required this.showOfferCount,
  });
  final ReferenceHomeProject? project;
  final VoidCallback onStart, onExplore;
  final ValueChanged<ReferenceHomeProject> onOpen, onOffers, onDetails;
  final bool showOfferCount;
  @override
  Widget build(BuildContext context) {
    final p = project;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.cream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.home_outlined, color: _T.orange, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p == null
                      ? context.l10n.homeownerReferenceStartTitle
                      : context.l10n.homeReferenceProjectStatus,
                  style: _T.text(22, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p == null ? context.l10n.homeownerReferenceStartBody : p.title,
            style: _T.text(
              p == null ? 16 : 20,
              color: p == null ? _T.muted : _T.navy,
              weight: p == null ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
          if (p == null) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.homeownerReferenceStartSteps,
              style: _T.text(14, color: _T.muted),
            ),
          ],
          if (p != null) ...[
            const SizedBox(height: 8),
            if (p.location.isNotEmpty)
              Text(p.location, style: _T.text(14, color: _T.muted)),
            const SizedBox(height: 8),
            Text(p.stage, style: _T.text(16)),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          if (p != null && showOfferCount)
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
                      style: _T.text(
                        14,
                        color: _T.action,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final primary = _Action(
                p == null
                    ? context.l10n.homeReferenceHeroPrimary
                    : context.l10n.homeReferenceProjectFollow,
                p == null ? onStart : () => onOpen(p),
              );
              final secondary = _Action(
                p == null
                    ? context.l10n.homeReferenceHeroSecondary
                    : context.l10n.homeReferenceClosingAction,
                p == null ? onExplore : onStart,
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

class _Action extends StatelessWidget {
  const _Action(this.label, this.onTap, {this.primary = true});
  final String label;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) => primary
      ? ProfessionalReferencePrimaryButton(label: label, onPressed: onTap)
      : TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: _T.text(16, color: _T.action, weight: FontWeight.w700),
          ),
        );
}

class _Title extends StatelessWidget {
  const _Title(this.title, this.onTap);
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: _T.text(22, weight: FontWeight.w800)),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            context.l10n.viewAll,
            style: _T.text(14, color: _T.action, weight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _Services extends StatelessWidget {
  const _Services({required this.onSelect});
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in [
          'full_reno',
          'design',
          'kitchen',
          'bathroom',
          'electrical',
          'plumbing',
          'more',
        ])
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: SizedBox(
              width: 100,
              child: ProfessionalReferenceCategory(
                label: key == 'more'
                    ? context.l10n.more
                    : key == 'full_reno'
                    ? context.l10n.homeReferenceServiceFullRenovationLabel
                    : localizedSpecialtyLabel(context, key),
                icon: switch (key) {
                  'full_reno' => Icons.home_outlined,
                  'design' => Icons.chair_outlined,
                  'kitchen' => Icons.kitchen_outlined,
                  'bathroom' => Icons.bathtub_outlined,
                  'electrical' => Icons.lightbulb_outline,
                  'plumbing' => Icons.plumbing,
                  _ => Icons.more_horiz,
                },
                onTap: () => onSelect(key == 'more' ? '' : key),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({
    required this.item,
    required this.saved,
    required this.onOpen,
    required this.onQuote,
    required this.onSave,
  });
  final ReferenceHomeProfessional item;
  final bool saved;
  final VoidCallback onOpen, onQuote, onSave;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: ReferencePremiumSurface(
      premium: item.sponsored,
      child: Container(
        decoration: BoxDecoration(
          color: item.sponsored ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe7e5e0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    button: true,
                    label: context.l10n.homeReferenceViewProfile,
                    child: InkWell(
                      onTap: onOpen,
                      child: _Photo(url: item.coverPhotoUrl),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 152),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              visualDensity: VisualDensity.standard,
                              tooltip: saved
                                  ? context.l10n.unsaveTooltip
                                  : context.l10n.saveTooltip,
                              onPressed: onSave,
                              icon: Icon(
                                saved ? Icons.favorite : Icons.favorite_border,
                                color: _T.action,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.sponsored) ...[
                        const SizedBox(height: 6),
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ReferencePremiumBadge(readable: true),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IdentityAvatar(
                        imageUrl: item.avatarUrl,
                        name: item.name,
                        radius: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: _T.text(18, weight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    localizedSpecialtyLabel(context, item.specialty),
                    style: _T.text(16, color: _T.muted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.reviewCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xffffb72a),
                            ),
                            Text(
                              '${item.rating.toStringAsFixed(1)} (${item.reviewCount})',
                              style: _T.text(14),
                            ),
                          ],
                        ),
                      if (item.verified)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified,
                              color: Color(0xff287951),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.verified,
                              style: _T.text(14, weight: FontWeight.w700),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (item.location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(item.location, style: _T.text(14, color: _T.muted)),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${item.projectsCompleted} ${context.l10n.completedProjectsShort}',
                    style: _T.text(14, color: _T.muted),
                  ),
                  const SizedBox(height: 14),
                  _Action(context.l10n.homeReferenceRequestQuote, onQuote),
                  _Action(
                    context.l10n.homeReferenceViewProfile,
                    onOpen,
                    primary: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EditorialCard extends StatelessWidget {
  const _EditorialCard({
    required this.title,
    required this.detail,
    required this.photo,
    required this.action,
    required this.onTap,
  });
  final String title, detail, action;
  final String? photo;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo?.isNotEmpty == true)
            AspectRatio(aspectRatio: 1.7, child: _Photo(url: photo)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _T.text(20, weight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(detail, style: _T.text(16, color: _T.muted)),
                const SizedBox(height: 12),
                Text(
                  action,
                  style: _T.text(16, color: _T.action, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
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
    if (kDebugMode &&
        ProfessionalReferenceFixture.allowedMediaPaths.contains(imageUrl)) {
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
