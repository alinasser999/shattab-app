import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/analytics/marketplace_events.dart';
import '../../../../core/cache/media_cache.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_initial_plate.dart';
import '../../../../core/widgets/batsh_photo_viewer.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/batsh_sheet.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../../core/widgets/tier_badge.dart';
import '../../../../core/utils/support_contact.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../../explore/presentation/widgets/contractor_community_posts.dart';
import '../../../portfolio/domain/portfolio_project.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../../reviews/domain/review.dart';
import '../../../reviews/presentation/providers/reviews_providers.dart';
import '../../../reviews/presentation/reviews_sheet.dart';
import '../../../saved/presentation/providers/saved_providers.dart';
import '../../../moderation/data/moderation_repository.dart';
import '../../../moderation/presentation/report_sheet.dart';
import '../../domain/contractor_listing.dart';
import 'professional_profile_sections.dart';

/// The public professional profile.
///
/// One continuous argument, in the order a homeowner builds trust: the work,
/// then who did it, then what the record says about them, then how to reach
/// them, then the evidence — about, services, finished projects, what they post
/// in the community, what clients said — closing by asking again.
///
/// The section tabs navigate rather than swap. A `TabBarView` here would hide
/// the projects behind the reviews and the reviews behind the projects, and the
/// whole reason this page is long is that a hiring decision wants all of it.
class PublicProfessionalProfile extends ConsumerStatefulWidget {
  const PublicProfessionalProfile({super.key, required this.listing});

  final ContractorListing listing;

  @override
  ConsumerState<PublicProfessionalProfile> createState() =>
      _PublicProfessionalProfileState();
}

class _PublicProfessionalProfileState
    extends ConsumerState<PublicProfessionalProfile> {
  int _galleryIndex = 0;
  // Works is the approved landing tab. About and Reviews remain real
  // sections on the same continuous profile, not separate fake routes.
  int _tabIndex = 0;

  final _aboutKey = GlobalKey();
  final _workKey = GlobalKey();
  final _reviewsKey = GlobalKey();

  ContractorListing get listing => widget.listing;

  @override
  void initState() {
    super.initState();
    unawaited(AppAnalytics.track('professional_profile_view'));
  }

  void _goToSection(int index) {
    setState(() => _tabIndex = index);
    final key = switch (index) {
      0 => _workKey,
      1 => _aboutKey,
      _ => _reviewsKey,
    };
    final target = key.currentContext;
    // A section can be absent — no bio, no reviews yet. Silently staying put
    // beats scrolling to nothing.
    if (target == null) return;
    unawaited(
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : BatshMotion.normal,
        curve: BatshMotion.easeOut,
        alignment: 0.05,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(
      portfolioForContractorProvider(listing.id),
    );
    final reviewsAsync = ref.watch(reviewsForContractorProvider(listing.id));
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? const {};
    final isSaved = savedIds.contains(listing.id);
    final projects = portfolioAsync.value ?? const <PortfolioProject>[];
    final gallery = _galleryItems(listing, projects);
    final bio = listing.bio?.trim();

    final content = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileGallery(
            listing: listing,
            items: gallery,
            currentIndex: _galleryIndex,
            isSaved: isSaved,
            onPageChanged: (index) => setState(() => _galleryIndex = index),
            onSave: () => _toggleSave(context),
            onShare: () => _shareProfessional(context, listing),
            onSafetyTap: () => _openSafetyActions(context),
          ),
        ),
        SliverToBoxAdapter(child: _IdentityBlock(listing: listing)),
        const SliverToBoxAdapter(child: SizedBox(height: BatshSpacing.md)),
        SliverToBoxAdapter(child: ProfileStatTiles(listing: listing)),
        const SliverToBoxAdapter(child: SizedBox(height: BatshSpacing.md)),
        SliverToBoxAdapter(child: ProfileTrustEvidence(listing: listing)),
        const SliverToBoxAdapter(child: SizedBox(height: BatshSpacing.md)),
        SliverToBoxAdapter(
          child: _ContactActions(
            phone: listing.phone,
            onRequestQuote: () => _openRequest(context),
            onWhatsApp: () => _openWhatsApp(context, listing.phone),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: BatshSpacing.lg)),
        // Pinned so the navigator stays reachable through a long page.
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabsHeaderDelegate(
            child: _ProfileStickyHeader(
              listing: listing,
              isSaved: isSaved,
              onBack: () => Navigator.of(context).maybePop(),
              onSave: () => _toggleSave(context),
              onShare: () => _shareProfessional(context, listing),
              tabs: ProfileSectionTabs(
                labels: [
                  context.l10n.profileTabWork,
                  context.l10n.profileTabAbout,
                  listing.hasReviews
                      ? '${context.l10n.profileTabReviews} (${listing.reviewCount})'
                      : context.l10n.profileTabReviews,
                ],
                currentIndex: _tabIndex,
                onSelect: _goToSection,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _Section(
            key: _workKey,
            title: context.l10n.profileWorkHeading(_professionalName(listing)),
            actionLabel: context.l10n.viewAll,
            onAction: () => context.push(
              Routes.homeownerContractorPortfolioPath(listing.id),
            ),
            padHorizontally: false,
            child: _ProjectsBody(
              listing: listing,
              projects: projects,
              loading: portfolioAsync.isLoading,
              failed: portfolioAsync.hasError,
              onRetry: () =>
                  ref.invalidate(portfolioForContractorProvider(listing.id)),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _Section(
            key: _aboutKey,
            title: context.l10n.profileAboutHeading(_professionalName(listing)),
            child: _AboutExperience(
              listing: listing,
              bio: bio,
              onExploreWork: () => _goToSection(0),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _Section(
            title: context.l10n.communityPostsTitle,
            child: ContractorCommunityPosts(contractorId: listing.id),
          ),
        ),

        SliverToBoxAdapter(
          child: _Section(
            key: _reviewsKey,
            title: context.l10n.fromOurClients,
            child: _ProfileReviewsBody(
              listing: listing,
              reviewsAsync: reviewsAsync,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: BatshSpacing.xl)),
        SliverToBoxAdapter(
          child: ProfileClosingCta(onRequestQuote: () => _openRequest(context)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: BatshSpacing.xxl)),
      ],
    );

    if (MediaQuery.disableAnimationsOf(context)) return content;
    return content.animate().fadeIn(
      duration: BatshMotion.normal,
      curve: BatshMotion.easeOut,
    );
  }

  void _openRequest(BuildContext context) {
    unawaited(
      AppAnalytics.track(
        MarketplaceEvents.requestStarted,
        properties: const {'source': 'professional_profile'},
      ),
    );
    context.push(Routes.homeownerSendBriefPath(listing.id));
  }

  Future<void> _openSafetyActions(BuildContext context) async {
    final action = await BatshSheet.show<String>(
      context,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.gutter,
        vertical: BatshSpacing.sm,
      ),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.profileSafetyTitle, style: BatshTypography.titleLg),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            context.l10n.profileSafetyBody,
            textAlign: TextAlign.center,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(context.l10n.reportProfileAction),
            onTap: () => Navigator.of(sheetContext).pop('report'),
          ),
          ListTile(
            leading: Icon(
              Icons.block_outlined,
              color: context.colorScheme.error,
            ),
            title: Text(
              context.l10n.blockProfileAction,
              style: TextStyle(color: context.colorScheme.error),
            ),
            onTap: () => Navigator.of(sheetContext).pop('block'),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: Text(context.l10n.helpSupport),
            onTap: () => Navigator.of(sheetContext).pop('support'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (action == 'report') {
      await showReportSheet(
        context,
        target: ReportTarget.profile,
        targetId: listing.id,
      );
      if (!context.mounted) return;
    } else if (action == 'block') {
      final blocked = await confirmAndBlock(context, ref, listing.id);
      if (!context.mounted) return;
      if (blocked) context.pop();
    } else if (action == 'support') {
      openShattabSupport(context);
    }
  }

  void _toggleSave(BuildContext context) {
    runSignedIn(
      context,
      ref,
      reason: context.l10n.signInToSave,
      action: () =>
          ref.read(savedControllerProvider.notifier).toggle(listing.id),
    );
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    if (!isValidContactPhone(phone)) return;
    HapticFeedback.lightImpact();
    final digits = whatsappPhoneDigits(phone);
    if (digits.isEmpty) {
      if (context.mounted) {
        BatshSnack.error(context, context.l10n.couldNotOpenApp);
      }
      return;
    }

    final whatsappUri = Uri.parse('https://wa.me/$digits');
    var opened = false;
    try {
      opened = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }

    if (!opened) {
      final phoneUri = Uri.parse('tel:+$digits');
      try {
        opened = await launchUrl(phoneUri);
      } catch (_) {
        opened = false;
      }
    }

    if (!opened && context.mounted) {
      BatshSnack.error(context, context.l10n.couldNotOpenApp);
    }
    if (opened) {
      unawaited(
        AppAnalytics.track(
          'contact_whatsapp',
          properties: const {'channel': 'whatsapp'},
        ),
      );
    }
  }
}

/// Keeps the section navigator on screen once it has been scrolled past.
class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabsHeaderDelegate({required this.child});

  final Widget child;

  static const double _height = 112;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox(height: _height, child: child);

  @override
  bool shouldRebuild(_TabsHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}

class _ProfileStickyHeader extends StatelessWidget {
  const _ProfileStickyHeader({
    required this.listing,
    required this.isSaved,
    required this.onBack,
    required this.onSave,
    required this.onShare,
    required this.tabs,
  });

  final ContractorListing listing;
  final bool isSaved;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final Widget tabs;

  @override
  Widget build(BuildContext context) {
    final name = _professionalName(listing);
    return Material(
      color: context.colorScheme.surface,
      elevation: 3,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: profileGutter),
                child: Row(
                  children: [
                    _CircleAction(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      icon: Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                      onPressed: onBack,
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    AvatarWithInitials(
                      imageUrl: listing.logoUrl,
                      name: name,
                      radius: 22,
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.titleMd.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            listing.providerKind.label(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.bodySm.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CircleAction(
                      tooltip: context.l10n.share,
                      icon: Icons.share_outlined,
                      onPressed: onShare,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    _CircleAction(
                      tooltip: isSaved
                          ? context.l10n.unsaveTooltip
                          : context.l10n.saveTooltip,
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      selected: isSaved,
                      onPressed: onSave,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 52, child: tabs),
          ],
        ),
      ),
    );
  }
}

class _AboutExperience extends StatelessWidget {
  const _AboutExperience({
    required this.listing,
    required this.bio,
    required this.onExploreWork,
  });

  final ContractorListing listing;
  final String? bio;
  final VoidCallback onExploreWork;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bio != null && bio!.trim().isNotEmpty)
          ProfileAboutCard(text: bio!.trim())
        else
          _NeutralProfilePanel(label: context.l10n.notSpecified),
        if (listing.specialties.isNotEmpty) ...[
          const SizedBox(height: BatshSpacing.md),
          Text(
            context.l10n.services,
            style: BatshTypography.titleLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          ProfileServicesRow(specialties: listing.specialties),
        ],
        if (listing.serviceAreas.isNotEmpty) ...[
          const SizedBox(height: BatshSpacing.md),
          Text(
            context.l10n.workArea,
            style: BatshTypography.titleLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          _NeutralProfilePanel(
            label: listing.serviceAreas.join(' · '),
            icon: Icons.place_outlined,
          ),
        ],
        if (listing.projectsCompleted > 0) ...[
          const SizedBox(height: BatshSpacing.md),
          _NeutralProfilePanel(
            label:
                '${listing.projectsCompleted} ${context.l10n.projectsCompleted}',
            icon: Icons.home_work_outlined,
          ),
        ],
        const SizedBox(height: BatshSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: onExploreWork,
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(context.l10n.exploreWork),
          ),
        ),
      ],
    );
  }
}

class _NeutralProfilePanel extends StatelessWidget {
  const _NeutralProfilePanel({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.md),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: context.colorScheme.primary),
              const SizedBox(width: BatshSpacing.sm),
            ],
            Expanded(child: Text(label, style: BatshTypography.bodyMd)),
          ],
        ),
      ),
    );
  }
}

// ─── Cover ───────────────────────────────────────────────────────────────────

class _ProfileGallery extends StatelessWidget {
  const _ProfileGallery({
    required this.listing,
    required this.items,
    required this.currentIndex,
    required this.isSaved,
    required this.onPageChanged,
    required this.onSave,
    required this.onShare,
    required this.onSafetyTap,
  });

  final ContractorListing listing;
  final List<_GalleryItem> items;
  final int currentIndex;
  final bool isSaved;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onSafetyTap;

  @override
  Widget build(BuildContext context) {
    final name = _professionalName(listing);
    final visibleIndex = currentIndex.clamp(0, items.length - 1).toInt();
    return Padding(
      // Room for the crest to hang below the photograph.
      padding: const EdgeInsets.only(bottom: 34),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BatshRadius.brXxl,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        itemCount: items.length,
                        onPageChanged: onPageChanged,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          final image = item.isPlaceholder
                              ? BatshInitialPlate(name: name)
                              : _ProfilePhoto(url: item.url);
                          return Semantics(
                            button: true,
                            image: true,
                            label: item.project?.title ?? name,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: item.isPlaceholder
                                  ? null
                                  : () => BatshPhotoViewer.show(
                                      context,
                                      urls: [
                                        for (final entry in items)
                                          if (!entry.isPlaceholder) entry.url,
                                      ],
                                      initialIndex: index,
                                    ),
                              child: index == 0
                                  ? Hero(
                                      tag: 'professional-gallery-${listing.id}',
                                      child: image,
                                    )
                                  : image,
                            ),
                          );
                        },
                      ),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                BatshColors.scrim.withValues(alpha: 0.48),
                                BatshColors.scrim.withValues(alpha: 0),
                                BatshColors.scrim.withValues(alpha: 0.55),
                              ],
                              stops: [0, 0.42, 1],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        start: BatshSpacing.md,
                        top: BatshSpacing.sm,
                        child: _CircleAction(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          // Back points the way the language came from.
                          icon: Directionality.of(context) == TextDirection.rtl
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      PositionedDirectional(
                        end: BatshSpacing.md,
                        top: BatshSpacing.sm,
                        child: Row(
                          children: [
                            _CircleAction(
                              tooltip: context.l10n.share,
                              icon: Icons.share_outlined,
                              onPressed: onShare,
                            ),
                            const SizedBox(width: BatshSpacing.xs),
                            _CircleAction(
                              tooltip: isSaved
                                  ? context.l10n.unsaveTooltip
                                  : context.l10n.saveTooltip,
                              icon: isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              selected: isSaved,
                              onPressed: onSave,
                            ),
                            const SizedBox(width: BatshSpacing.xs),
                            _CircleAction(
                              tooltip: context.l10n.profileSafetyTitle,
                              icon: Icons.more_horiz_rounded,
                              onPressed: onSafetyTap,
                            ),
                          ],
                        ),
                      ),
                      // The trust mark rides the photograph, as in the
                      // reference — and only when the record earns it.
                      if (listing.verified)
                        const PositionedDirectional(
                          start: BatshSpacing.md,
                          top: 64,
                          child: _CoverVerifiedPill(),
                        ),
                    ],
                  ),
                ),
                if (listing.hasReviews)
                  PositionedDirectional(
                    start: BatshSpacing.md,
                    bottom: BatshSpacing.md,
                    child: _CoverRatingPill(listing: listing),
                  ),
                if (items.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: BatshSpacing.xs,
                    child: _GalleryDots(
                      count: items.length,
                      index: visibleIndex,
                    ),
                  ),
              ],
            ),
          ),
          PositionedDirectional(
            end: BatshSpacing.lg,
            bottom: 0,
            child: _ProfileLogo(listing: listing),
          ),
        ],
      ),
    );
  }
}

class _GalleryDots extends StatelessWidget {
  const _GalleryDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final shown = count > 5 ? 5 : count;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < shown; i++)
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : BatshMotion.fast,
              width: i == index ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: BatshColors.onPrimary.withValues(
                  alpha: i == index ? 0.95 : 0.55,
                ),
                borderRadius: BatshRadius.brFull,
              ),
            ),
        ],
      ),
    );
  }
}

/// Fixed colours: this pill sits on a contractor's own upload, so its contrast
/// cannot follow whichever surface the page is painting.
class _CoverVerifiedPill extends StatelessWidget {
  const _CoverVerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.verifiedByShattab,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: BatshColors.scrim,
          borderRadius: BatshRadius.brFull,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_rounded,
                size: BatshIconSize.inline,
                color: BatshColors.secondaryContainer,
              ),
              const SizedBox(width: BatshSpacing.xxs),
              Text(
                context.l10n.verified,
                style: BatshTypography.labelMd.copyWith(
                  color: BatshColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverRatingPill extends StatelessWidget {
  const _CoverRatingPill({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final average = listing.reviewAvg.toStringAsFixed(1);
    return Semantics(
      label:
          '${context.l10n.ratingLabel} $average, '
          '${listing.reviewCount} ${context.l10n.reviewsCount}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brFull,
          boxShadow: BatshShadows.soft,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: BatshIconSize.md,
                color: BatshColors.starGold,
              ),
              const SizedBox(width: BatshSpacing.xxs),
              Text(
                average,
                textDirection: TextDirection.ltr,
                style: BatshTypography.labelLg.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: BatshSpacing.xxs),
              Text(
                '(${listing.reviewCount}) ${context.l10n.reviewsCount}',
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLogo extends StatelessWidget {
  const _ProfileLogo({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 84,
        height: 84,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: BatshShadows.elevated,
        ),
        child: ClipOval(
          child: isDisplayableImageUrl(listing.logoUrl)
              ? CachedNetworkImage(
                  imageUrl: sizedImageUrl(listing.logoUrl!, width: 220),
                  cacheManager: mediaCacheManager,
                  fit: BoxFit.cover,
                  memCacheWidth: 220,
                  errorWidget: (_, _, _) => AvatarWithInitials(
                    name: _professionalName(listing),
                    radius: 42,
                  ),
                )
              : AvatarWithInitials(
                  name: _professionalName(listing),
                  radius: 42,
                ),
        ),
      ),
    );
  }
}

// ─── Identity ────────────────────────────────────────────────────────────────

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final name = _professionalName(listing);
    final trades = listing.specialties
        .take(3)
        .map((key) => localizedSpecialtyDisplayLabel(context, key))
        .join(' · ');
    final where = listing.serviceAreas.take(2).join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        profileGutter,
        BatshSpacing.xs,
        // Clear of the crest hanging off the cover.
        profileGutter + 76,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.headlineLgMobile.copyWith(
                    fontSize: 25,
                    height: 1.15,
                  ),
                ),
              ),
              if (listing.verified) ...[
                const SizedBox(width: BatshSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _VerificationInfoButton(),
                ),
              ],
            ],
          ),
          const SizedBox(height: BatshSpacing.xs),
          Wrap(
            spacing: BatshSpacing.xs,
            runSpacing: BatshSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    listing.providerKind.icon,
                    size: BatshIconSize.inline,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: BatshSpacing.xxs),
                  Text(
                    listing.providerKind.label(context),
                    style: BatshTypography.labelMd.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (listing.tier.isPublic) TierBadge(tier: listing.tier),
            ],
          ),
          if (trades.isNotEmpty) ...[
            const SizedBox(height: BatshSpacing.xs),
            Text(
              trades,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.bodyMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (where.isNotEmpty) ...[
            const SizedBox(height: BatshSpacing.xxs),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: BatshIconSize.inline,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: BatshSpacing.xxs),
                Flexible(
                  child: Text(
                    where,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.bodyMd.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VerificationInfoButton extends StatelessWidget {
  const _VerificationInfoButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.verifiedIdentityTitle,
      child: Tooltip(
        message: context.l10n.verifiedIdentityTitle,
        child: BatshPressable(
          semanticLabel: context.l10n.verifiedIdentityTitle,
          onTap: () {
            BatshSheet.show<void>(
              context,
              contentPadding: const EdgeInsets.fromLTRB(
                BatshSpacing.gutter,
                BatshSpacing.sm,
                BatshSpacing.gutter,
                BatshSpacing.md,
              ),
              builder: (sheetContext) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.verifiedIdentityTitle,
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xs),
                  Text(
                    context.l10n.verifiedIdentityBody,
                    style: BatshTypography.bodyMd.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  BatshButton(
                    label: context.l10n.done,
                    style: BatshButtonStyle.ghost,
                    fullWidth: false,
                    animate: false,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            );
          },
          child: SizedBox(
            width: BatshSpacing.minHitArea,
            height: BatshSpacing.minHitArea,
            child: Icon(
              Icons.verified_rounded,
              color: context.colorScheme.secondary,
              size: BatshIconSize.md,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Contact ─────────────────────────────────────────────────────────────────

/// One primary action, then the two ways to talk to somebody.
///
/// The quote request is the platform's own action and gets the fill; WhatsApp
/// and the phone are outlined and share a row, which keeps a third party's
/// green off the loudest element on a hiring screen.
class _ContactActions extends StatelessWidget {
  const _ContactActions({
    required this.phone,
    required this.onRequestQuote,
    required this.onWhatsApp,
  });

  final String phone;
  final VoidCallback onRequestQuote;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final canContact = isValidContactPhone(phone);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: profileGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onRequestQuote,
            icon: const Icon(Icons.send_outlined),
            label: Text(context.l10n.requestPriceQuote),
          ),
          if (canContact) ...[
            const SizedBox(height: BatshSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: WhatsAppButton(
                    phone: phone,
                    label: context.l10n.whatsappShort,
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(child: CallButton(phone: phone)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section frame ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.padHorizontally = true,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// False for sections that bleed to the screen edge — a horizontal rail has
  /// to scroll out of the gutter, not stop inside it.
  final bool padHorizontally;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: BatshSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              profileGutter,
              0,
              profileGutter,
              BatshSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary,
                    borderRadius: BatshRadius.brFull,
                  ),
                ),
                const SizedBox(width: BatshSpacing.xs),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: BatshTypography.titleLg.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  BatshButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    style: BatshButtonStyle.ghost,
                    fullWidth: false,
                    animate: false,
                  ),
              ],
            ),
          ),
          if (padHorizontally)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: profileGutter),
              child: child,
            )
          else
            child,
        ],
      ),
    );
  }
}

// ─── Projects ────────────────────────────────────────────────────────────────

class _ProjectsBody extends StatelessWidget {
  const _ProjectsBody({
    required this.listing,
    required this.projects,
    required this.loading,
    required this.failed,
    required this.onRetry,
  });

  final ContractorListing listing;
  final List<PortfolioProject> projects;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: profileGutter),
        child: BatshShimmerBox(height: 190, borderRadius: BatshRadius.brLg),
      );
    }
    if (failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: profileGutter),
        child: Container(
          padding: const EdgeInsets.all(BatshSpacing.md),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLow,
            borderRadius: BatshRadius.brLg,
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(child: Text(context.l10n.portfolioLoadFailed)),
              BatshButton(
                label: context.l10n.tryAgain,
                onPressed: onRetry,
                style: BatshButtonStyle.ghost,
                fullWidth: false,
                animate: false,
              ),
            ],
          ),
        ),
      );
    }
    if (projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: profileGutter),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BatshSpacing.lg),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLow,
            borderRadius: BatshRadius.brLg,
          ),
          child: Text(
            context.l10n.workInspirationTitle,
            textAlign: TextAlign.center,
            style: BatshTypography.bodyMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return _PortfolioWorkList(
      projects: projects,
      onOpen: (project) => context.push(
        Routes.homeownerProjectDetailPath(listing.id, project.id),
      ),
    );
  }
}

class _PortfolioWorkList extends StatelessWidget {
  const _PortfolioWorkList({required this.projects, required this.onOpen});

  final List<PortfolioProject> projects;
  final ValueChanged<PortfolioProject> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: profileGutter),
      child: Column(
        children: [
          for (var i = 0; i < projects.length; i++) ...[
            _PortfolioWorkCard(
              project: projects[i],
              onTap: () => onOpen(projects[i]),
            ),
            if (i != projects.length - 1)
              const SizedBox(height: BatshSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PortfolioWorkCard extends StatelessWidget {
  const _PortfolioWorkCard({required this.project, required this.onTap});

  final PortfolioProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final galleryCount = 1 + project.photoUrls.length;
    return Semantics(
      button: true,
      label: project.title,
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: project.title,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brLg,
            border: Border.all(color: context.colorScheme.outlineVariant),
            boxShadow: BatshShadows.soft,
          ),
          child: SizedBox(
            height: 124,
            child: ClipRRect(
              borderRadius: BatshRadius.brLg,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    SizedBox(
                      width: 142,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          isDisplayableImageUrl(project.coverPhotoUrl)
                              ? _ProfilePhoto(url: project.coverPhotoUrl)
                              : BatshInitialPlate(name: project.title),
                          PositionedDirectional(
                            start: BatshSpacing.xs,
                            bottom: BatshSpacing.xs,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: BatshSpacing.xs,
                                vertical: BatshSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: BatshColors.scrim.withValues(alpha: .82),
                                borderRadius: BatshRadius.brFull,
                              ),
                              child: Text(
                                context.l10n.portfolioPhotosCount(galleryCount),
                                style: BatshTypography.labelSm.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Padding(
                          padding: const EdgeInsets.all(BatshSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      project.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: BatshTypography.titleMd.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Directionality.of(context) ==
                                            TextDirection.rtl
                                        ? Icons.arrow_back_ios_rounded
                                        : Icons.arrow_forward_ios_rounded,
                                    size: BatshIconSize.sm,
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (project.apartmentType != null)
                                Text(
                                  project.apartmentType!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: BatshTypography.bodySm.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (project.location != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.place_outlined,
                                      size: BatshIconSize.sm,
                                      color: context.colorScheme.primary,
                                    ),
                                    const SizedBox(width: BatshSpacing.xxs),
                                    Expanded(
                                      child: Text(
                                        project.location!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: BatshTypography.bodySm.copyWith(
                                          color: context
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reviews ─────────────────────────────────────────────────────────────────

class _ProfileReviewsBody extends StatelessWidget {
  const _ProfileReviewsBody({
    required this.listing,
    required this.reviewsAsync,
  });

  final ContractorListing listing;
  final AsyncValue<List<Review>> reviewsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewSummary(listing: listing, reviewsAsync: reviewsAsync),
        const SizedBox(height: BatshSpacing.md),
        reviewsAsync.when(
          loading: () => const BatshShimmerBox(
            height: 150,
            borderRadius: BatshRadius.brLg,
          ),
          error: (_, _) => _NeutralProfilePanel(
            label: context.l10n.reviewsLoadFailed,
            icon: Icons.cloud_off_outlined,
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return _NeutralProfilePanel(
                label: context.l10n.noReviewsYet,
                icon: Icons.rate_review_outlined,
              );
            }
            final visible = reviews.take(3).toList();
            return Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _ReviewCard(review: visible[i]),
                  if (i != visible.length - 1)
                    const SizedBox(height: BatshSpacing.sm),
                ],
                if (reviews.length > visible.length)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: BatshButton(
                      label: context.l10n.viewAllReviews,
                      style: BatshButtonStyle.ghost,
                      fullWidth: false,
                      onPressed: () => showReviewsSheet(context, listing.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.listing, required this.reviewsAsync});

  final ContractorListing listing;
  final AsyncValue<List<Review>> reviewsAsync;

  @override
  Widget build(BuildContext context) {
    final reviews = reviewsAsync.value ?? const <Review>[];
    final counts = <int, int>{for (var star = 1; star <= 5; star++) star: 0};
    for (final review in reviews) {
      if (review.rating >= 1 && review.rating <= 5) {
        counts[review.rating] = counts[review.rating]! + 1;
      }
    }
    final maxCount = counts.values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 92,
              child: Column(
                children: [
                  Text(
                    listing.hasReviews
                        ? listing.reviewAvg.toStringAsFixed(1)
                        : '—',
                    style: BatshTypography.displayMd.copyWith(
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (listing.hasReviews)
                    _Stars(value: listing.reviewAvg.round()),
                  const SizedBox(height: BatshSpacing.xs),
                  Text(
                    '${listing.reviewCount} ${context.l10n.reviewsCount}',
                    textAlign: TextAlign.center,
                    style: BatshTypography.labelSm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: Column(
                children: [
                  for (var star = 5; star >= 1; star--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            child: Text(
                              '$star',
                              textAlign: TextAlign.center,
                              style: BatshTypography.labelSm,
                            ),
                          ),
                          const SizedBox(width: BatshSpacing.xs),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BatshRadius.brFull,
                              child: LinearProgressIndicator(
                                minHeight: 7,
                                value: maxCount == 0
                                    ? 0
                                    : counts[star]! / maxCount,
                                backgroundColor:
                                    context.colorScheme.surfaceContainerHigh,
                                color: context.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: BatshSpacing.xs),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${counts[star]}',
                              textAlign: TextAlign.end,
                              style: BatshTypography.labelSm.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
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
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Stars(value: review.rating),
                const Spacer(),
                Text(
                  formatRelativeTime(review.createdAt),
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (review.comment?.trim().isNotEmpty == true) ...[
              const SizedBox(height: BatshSpacing.sm),
              Text(review.comment!.trim(), style: BatshTypography.bodyMd),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${context.l10n.ratingLabel} $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < 5; index++)
            Icon(
              index < value ? Icons.star_rounded : Icons.star_border_rounded,
              size: BatshIconSize.inline,
              color: BatshColors.starGold,
            ),
        ],
      ),
    );
  }
}

// ─── Shared bits ─────────────────────────────────────────────────────────────

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: BatshPressable(
        onTap: onPressed,
        semanticLabel: tooltip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLowest.withValues(
              alpha: 0.94,
            ),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: BatshSpacing.minHitArea,
            height: BatshSpacing.minHitArea,
            child: Icon(
              icon,
              size: BatshIconSize.action,
              color: selected
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryItem {
  const _GalleryItem({
    required this.url,
    this.project,
    this.isPlaceholder = false,
  });

  final String url;
  final PortfolioProject? project;
  final bool isPlaceholder;
}

List<_GalleryItem> _galleryItems(
  ContractorListing listing,
  List<PortfolioProject> projects,
) {
  final items = <_GalleryItem>[];
  final seen = <String>{};

  void add(
    String? url, [
    PortfolioProject? project,
    bool isPlaceholder = false,
  ]) {
    if (!isDisplayableImageUrl(url) || !seen.add(url!)) return;
    items.add(
      _GalleryItem(url: url, project: project, isPlaceholder: isPlaceholder),
    );
  }

  add(listing.coverPhotoUrl);
  for (final project in projects) {
    add(project.coverPhotoUrl, project);
    for (final photo in project.photoUrls) {
      add(photo, project);
    }
  }
  // Keep the gallery shape stable without implying that a neutral plate is a
  // published project. Real project media is the only source of gallery URLs.
  if (items.isEmpty) {
    items.add(const _GalleryItem(url: '', isPlaceholder: true));
  }
  return items.take(12).toList();
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: sizedImageUrl(url, width: 1440),
      cacheManager: mediaCacheManager,
      fit: BoxFit.cover,
      memCacheWidth: 1440,
      placeholder: (_, _) => const BatshInitialPlate(),
      errorWidget: (_, _, _) => const BatshInitialPlate(),
    );
  }
}

void _shareProfessional(BuildContext context, ContractorListing listing) {
  final name = _professionalName(listing);
  final message = StringBuffer(
    context.l10n.seeOnShattab.replaceFirst('%s', name),
  );
  if (listing.headline?.isNotEmpty ?? false) {
    message.write('\n${listing.headline}');
  }
  message.write('\n${context.l10n.contactPrivacyShareHint}');
  Share.share(message.toString(), subject: name);
}

String _professionalName(ContractorListing listing) =>
    listing.businessName.isNotEmpty ? listing.businessName : listing.fullName;
