import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/analytics/marketplace_events.dart';
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
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_photo_viewer.dart';
import '../../../../core/widgets/batsh_sheet.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../../core/widgets/contact_buttons.dart';
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
import 'mockup_assets.dart';
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
      0 => _aboutKey,
      1 => _workKey,
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
    final highlightedReview = _reviewWithComment(reviewsAsync.value);
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
            child: ProfileSectionTabs(
              labels: [
                context.l10n.profileTabAbout,
                context.l10n.profileTabWork,
                listing.hasReviews
                    ? '${context.l10n.profileTabReviews} (${listing.reviewCount})'
                    : context.l10n.profileTabReviews,
              ],
              currentIndex: _tabIndex,
              onSelect: _goToSection,
            ),
          ),
        ),

        if (bio != null && bio.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              key: _aboutKey,
              title: context.l10n.profileAboutCompany,
              child: ProfileAboutCard(text: bio),
            ),
          ),

        if (listing.specialties.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              title: context.l10n.profileServicesTitle,
              padHorizontally: false,
              child: ProfileServicesRow(specialties: listing.specialties),
            ),
          ),

        SliverToBoxAdapter(
          child: _Section(
            key: _workKey,
            title: context.l10n.profileProjectsTitle,
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
            title: context.l10n.communityPostsTitle,
            child: ContractorCommunityPosts(contractorId: listing.id),
          ),
        ),

        SliverToBoxAdapter(
          child: _Section(
            key: _reviewsKey,
            title: context.l10n.fromOurClients,
            actionLabel: context.l10n.viewAllReviews,
            onAction: () => showReviewsSheet(context, listing.id),
            child: _ReviewProof(
              review: highlightedReview,
              average: listing.rating,
              count: listing.reviewCount,
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

  static const double _height = 52;

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
    final visibleItem = items[visibleIndex];

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
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(BatshRadius.xxl),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        itemCount: items.length,
                        onPageChanged: onPageChanged,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          final image = MockupImage(
                            url: item.url,
                            memCacheWidth: 1440,
                          );
                          return Semantics(
                            button: true,
                            image: true,
                            label: item.isPlaceholder
                                ? '${item.project?.title ?? name}, ${context.l10n.sampleImagesLabel}'
                                : item.project?.title ?? name,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => BatshPhotoViewer.show(
                                context,
                                urls: [for (final entry in items) entry.url],
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
                      const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x76000000),
                                Color(0x00000000),
                                Color(0x8C000000),
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
                      if (visibleItem.isPlaceholder)
                        PositionedDirectional(
                          start: BatshSpacing.md,
                          top: listing.verified ? 106 : 64,
                          child: const MockupSampleBadge(),
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
                color: Colors.white.withValues(alpha: i == index ? 0.95 : 0.55),
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
          color: Colors.black.withValues(alpha: 0.62),
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
                  color: Colors.white,
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
          child: listing.logoUrl?.isNotEmpty == true
              ? MockupImage(url: listing.logoUrl, memCacheWidth: 220)
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
        .map((key) => localizedSpecialtyLabel(context, key))
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
      child: IconButton(
        tooltip: context.l10n.verifiedIdentityTitle,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: BatshSpacing.minHitArea,
          minHeight: BatshSpacing.minHitArea,
        ),
        icon: Icon(
          Icons.verified_rounded,
          color: context.colorScheme.secondary,
          size: BatshIconSize.md,
        ),
        onPressed: () {
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
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(context.l10n.done),
                ),
              ],
            ),
          );
        },
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: profileGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: context.l10n.requestPriceQuote,
            child: Material(
              color: context.colorScheme.primary,
              borderRadius: BatshRadius.brFull,
              child: InkWell(
                onTap: onRequestQuote,
                borderRadius: BatshRadius.brFull,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: BatshSpacing.md,
                  ),
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.send_outlined,
                          color: context.colorScheme.onPrimary,
                          size: BatshIconSize.md,
                        ),
                        const SizedBox(width: BatshSpacing.xs),
                        Flexible(
                          child: Text(
                            context.l10n.requestPriceQuote,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.titleMd.copyWith(
                              color: context.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
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
          const SizedBox(height: BatshSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: context.l10n.contactViaWhatsApp,
                  onTap: onWhatsApp,
                  child: ExcludeSemantics(
                    child: OutlinedButton.icon(
                      onPressed: onWhatsApp,
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        size: BatshIconSize.md,
                        color: BatshColors.whatsApp,
                      ),
                      label: Text(
                        context.l10n.whatsappShort,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colorScheme.onSurface,
                        side: BorderSide(color: context.colorScheme.outline),
                        minimumSize: const Size.fromHeight(
                          BatshSpacing.minHitArea,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(child: CallButton(phone: phone)),
            ],
          ),
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
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
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
              TextButton(
                onPressed: onRetry,
                child: Text(context.l10n.tryAgain),
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

    return ProfileProjectsGrid(
      projects: projects,
      onOpen: (project) => context.push(
        Routes.homeownerProjectDetailPath(listing.id, project.id),
      ),
    );
  }
}

// ─── Reviews ─────────────────────────────────────────────────────────────────

class _ReviewProof extends StatelessWidget {
  const _ReviewProof({
    required this.review,
    required this.average,
    required this.count,
  });

  final Review? review;
  final double? average;
  final int count;

  @override
  Widget build(BuildContext context) {
    final hasRating = average != null && count > 0;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 64,
            child: Container(
              padding: const EdgeInsets.all(BatshSpacing.md),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerLowest,
                borderRadius: BatshRadius.brCard,
                border: Border.all(color: context.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: context.colorScheme.primary.withValues(alpha: 0.45),
                    size: BatshIconSize.lg,
                  ),
                  const SizedBox(height: BatshSpacing.xs),
                  Text(
                    review?.comment?.trim().isNotEmpty == true
                        ? review!.comment!.trim()
                        : context.l10n.noRatingsYet,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.bodyMd.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: BatshIconSize.inline,
                          color: context.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: BatshSpacing.xs),
                      Expanded(
                        child: Text(
                          context.l10n.shattabClient,
                          style: BatshTypography.labelSm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (review != null) _Stars(value: review!.rating),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            flex: 36,
            child: Container(
              padding: const EdgeInsets.all(BatshSpacing.md),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerLowest,
                borderRadius: BatshRadius.brCard,
                border: Border.all(color: context.colorScheme.outlineVariant),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasRating ? average!.toStringAsFixed(1) : '—',
                    style: BatshTypography.displayMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasRating) ...[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _Stars(value: average!.round()),
                    ),
                    const SizedBox(height: BatshSpacing.xs),
                    Text(
                      '$count ${context.l10n.reviewsCount}',
                      textAlign: TextAlign.center,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else
                    Text(
                      context.l10n.noRatingsYet,
                      textAlign: TextAlign.center,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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
    return Material(
      color: context.colorScheme.surfaceContainerLowest.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(
          icon,
          color: selected
              ? context.colorScheme.primary
              : context.colorScheme.onSurface,
        ),
        onPressed: onPressed,
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
  // One clearly labelled visual placeholder keeps the profile from feeling
  // broken without making illustrative imagery look like a real portfolio.
  // Real project media is the only source that can add gallery items beyond
  // the cover image.
  if (items.isEmpty) add(mockupHeroImage, null, true);
  return items.take(12).toList();
}

Review? _reviewWithComment(List<Review>? reviews) {
  if (reviews == null) return null;
  for (final review in reviews) {
    if (review.comment?.trim().isNotEmpty ?? false) return review;
  }
  return null;
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
