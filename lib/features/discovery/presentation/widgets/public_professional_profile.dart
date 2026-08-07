import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_photo_viewer.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../../portfolio/domain/portfolio_project.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../../reviews/domain/review.dart';
import '../../../reviews/presentation/providers/reviews_providers.dart';
import '../../../reviews/presentation/reviews_sheet.dart';
import '../../../saved/presentation/providers/saved_providers.dart';
import '../../../explore/presentation/widgets/contractor_community_posts.dart';
import '../../domain/contractor_listing.dart';
import 'mockup_assets.dart';

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

  ContractorListing get listing => widget.listing;

  @override
  void initState() {
    super.initState();
    unawaited(AppAnalytics.track('professional_profile_view'));
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

    final content = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _ProfileGallery(
                listing: listing,
                items: gallery,
                currentIndex: _galleryIndex,
                isSaved: isSaved,
                onPageChanged: (index) => setState(() => _galleryIndex = index),
                onSave: () => _toggleSave(context),
                onShare: () => _shareProfessional(context, listing),
              ),
              Transform.translate(
                offset: const Offset(0, -32),
                child: Column(
                  children: [
                    _IdentityPanel(
                      listing: listing,
                      isSaved: isSaved,
                      onSave: () => _toggleSave(context),
                      onContact: () => _openWhatsApp(context, listing.phone),
                      onRequestQuote: () => _openRequest(context),
                    ),
                    _ProfileSection(
                      title: context.l10n.communityPostsTitle,
                      child: ContractorCommunityPosts(contractorId: listing.id),
                    ),
                    _ProfileSection(
                      title:
                          projects.isEmpty &&
                              !portfolioAsync.isLoading &&
                              !portfolioAsync.hasError
                          ? context.l10n.workInspirationTitle
                          : context.l10n.professionalWorkTitle,
                      actionLabel: context.l10n.viewAll,
                      onAction: () => context.push(
                        Routes.homeownerContractorPortfolioPath(listing.id),
                      ),
                      child: _PortfolioProof(
                        listing: listing,
                        projects: projects,
                        loading: portfolioAsync.isLoading,
                        failed: portfolioAsync.hasError,
                        onRetry: () => ref.invalidate(
                          portfolioForContractorProvider(listing.id),
                        ),
                      ),
                    ),
                    _ProfileSection(
                      title: context.l10n.fromOurClients,
                      actionLabel: context.l10n.viewAllReviews,
                      onAction: () => showReviewsSheet(context, listing.id),
                      child: _ReviewProof(
                        review: highlightedReview,
                        average: listing.rating,
                        count: listing.reviewCount,
                      ),
                    ),
                    if (listing.bio?.trim().isNotEmpty == true)
                      _ProfileSection(
                        title: context.l10n.aboutProfessional,
                        child: _AboutProfessional(listing: listing),
                      ),
                    const SizedBox(height: 164),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (MediaQuery.disableAnimationsOf(context)) return content;
    return content.animate().fadeIn(
      duration: BatshMotion.normal,
      curve: BatshMotion.easeOut,
    );
  }

  void _openRequest(BuildContext context) {
    context.push(Routes.homeownerSendBriefPath(listing.id));
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

class ProfessionalProfileActionBar extends ConsumerWidget {
  const ProfessionalProfileActionBar({super.key, required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? const {};
    final isSaved = savedIds.contains(listing.id);
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: context.colorScheme.outlineVariant),
        ),
        boxShadow: BatshShadows.raised,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.marginMobile,
            BatshSpacing.sm,
            BatshSpacing.marginMobile,
            BatshSpacing.sm,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                _SquareAction(
                  tooltip: isSaved
                      ? context.l10n.unsaveTooltip
                      : context.l10n.saveTooltip,
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  selected: isSaved,
                  onPressed: () => runSignedIn(
                    context,
                    ref,
                    reason: context.l10n.signInToSave,
                    action: () => ref
                        .read(savedControllerProvider.notifier)
                        .toggle(listing.id),
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: BatshButton(
                    label: context.l10n.requestPriceQuote,
                    icon: Icons.send_outlined,
                    onPressed: () =>
                        context.push(Routes.homeownerSendBriefPath(listing.id)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileGallery extends StatelessWidget {
  const _ProfileGallery({
    required this.listing,
    required this.items,
    required this.currentIndex,
    required this.isSaved,
    required this.onPageChanged,
    required this.onSave,
    required this.onShare,
  });

  final ContractorListing listing;
  final List<_GalleryItem> items;
  final int currentIndex;
  final bool isSaved;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final name = _professionalName(listing);
    final visibleIndex = currentIndex.clamp(0, items.length - 1).toInt();
    final visibleItem = items[visibleIndex];
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          PageView.builder(
            itemCount: items.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, index) {
              final item = items[index];
              final image = MockupImage(url: item.url, memCacheWidth: 1440);
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
                    Color(0x65000000),
                  ],
                  stops: [0, 0.42, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned(
                  left: BatshSpacing.md,
                  top: BatshSpacing.sm,
                  child: _CircleAction(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  right: BatshSpacing.md,
                  top: BatshSpacing.sm,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            end: BatshSpacing.md,
            bottom: BatshSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.sm,
                vertical: BatshSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BatshRadius.brFull,
              ),
              child: Text(
                '${currentIndex + 1} / ${items.length}',
                textDirection: TextDirection.ltr,
                style: BatshTypography.labelSm.copyWith(color: Colors.white),
              ),
            ),
          ),
          if (visibleItem.isPlaceholder)
            const Positioned(
              left: BatshSpacing.md,
              top: 64,
              child: MockupSampleBadge(),
            ),
          if (items.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: BatshSpacing.md,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (
                    var index = 0;
                    index < (items.length > 5 ? 5 : items.length);
                    index++
                  )
                    AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : BatshMotion.fast,
                      width: index == currentIndex ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: index == currentIndex ? 0.95 : 0.55,
                        ),
                        borderRadius: BatshRadius.brFull,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({
    required this.listing,
    required this.isSaved,
    required this.onSave,
    required this.onContact,
    required this.onRequestQuote,
  });

  final ContractorListing listing;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onContact;
  final VoidCallback onRequestQuote;

  @override
  Widget build(BuildContext context) {
    final name = _professionalName(listing);
    final specialty = listing.specialties.firstOrNull;
    final location = listing.serviceAreas.take(2).join(' • ');
    final metrics = [
      _MetricData(
        value: listing.hasReviews ? listing.reviewAvg.toStringAsFixed(1) : '—',
        label: listing.hasReviews
            ? '${listing.reviewCount} ${context.l10n.reviewsCount}'
            : context.l10n.noRatingsYet,
        icon: Icons.star_rounded,
      ),
      _MetricData(
        value: listing.projectsCompleted > 0
            ? '${listing.projectsCompleted}'
            : '—',
        label: context.l10n.projects,
        icon: Icons.home_work_outlined,
      ),
      _MetricData(
        value: listing.yearsExperience != null
            ? '${listing.yearsExperience}'
            : '—',
        label: context.l10n.yearsExperience,
        icon: Icons.workspace_premium_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.marginMobile,
        40,
        BatshSpacing.marginMobile,
        BatshSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BatshRadius.xxl),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: BatshSpacing.xs),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 96),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: BatshTypography.headlineLgMobile.copyWith(
                              fontSize: 25,
                              height: 1.12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (listing.verified) ...[
                          const SizedBox(width: BatshSpacing.xs),
                          Icon(
                            Icons.verified_rounded,
                            color: const Color(0xFF287AD5),
                            size: BatshIconSize.md,
                            semanticLabel: context.l10n.verified,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xs),
                  Text(
                    [
                      if (specialty != null)
                        localizedSpecialtyLabel(context, specialty),
                      if (location.isNotEmpty) location,
                    ].join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: BatshTypography.bodyMd.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.md),
                  _MetricsRow(metrics: metrics),
                  const SizedBox(height: BatshSpacing.sm),
                  _StatusStrip(
                    text: listing.verified
                        ? context.l10n.shattabVerifiedProfessional
                        : context.l10n.contactViaWhatsApp,
                    icon: listing.verified
                        ? Icons.verified_user_outlined
                        : Icons.phone_in_talk_outlined,
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  _ProfileActions(
                    isSaved: isSaved,
                    onSave: onSave,
                    onContact: onContact,
                    onRequestQuote: onRequestQuote,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: BatshSpacing.marginMobile,
            top: -16,
            child: _ProfileLogo(listing: listing),
          ),
        ],
      ),
    );
  }
}

class _ProfileLogo extends StatelessWidget {
  const _ProfileLogo({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: BatshShadows.elevated,
      ),
      child: ClipOval(
        child: listing.logoUrl?.isNotEmpty == true
            ? MockupImage(url: listing.logoUrl, memCacheWidth: 220)
            : AvatarWithInitials(name: _professionalName(listing), radius: 44),
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.isSaved,
    required this.onSave,
    required this.onContact,
    required this.onRequestQuote,
  });

  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onContact;
  final VoidCallback onRequestQuote;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          _SquareAction(
            width: 48,
            height: 48,
            tooltip: isSaved
                ? context.l10n.unsaveTooltip
                : context.l10n.saveTooltip,
            icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
            selected: isSaved,
            onPressed: onSave,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Semantics(
              button: true,
              label: context.l10n.contactViaWhatsApp,
              onTap: onContact,
              child: ExcludeSemantics(
                child: OutlinedButton(
                  onPressed: onContact,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: context.colorScheme.onSurface,
                    side: BorderSide(color: context.colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BatshRadius.brDefault,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.phone_in_talk_outlined,
                        color: BatshColors.whatsApp,
                      ),
                      const SizedBox(width: BatshSpacing.xs),
                      Text(
                        context.l10n.whatsappShort,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelSm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onRequestQuote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BatshSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BatshRadius.brDefault,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(context.l10n.requestPriceQuote),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: BatshSpacing.xs),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: context.colorScheme.outlineVariant),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            for (var index = 0; index < metrics.length; index++) ...[
              if (index > 0)
                Container(
                  width: 1,
                  height: 38,
                  color: context.colorScheme.outlineVariant,
                ),
              Expanded(child: _Metric(metric: metrics[index])),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${metric.value} ${metric.label}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                metric.icon,
                size: BatshIconSize.inline,
                color: metric.icon == Icons.star_rounded
                    ? context.colorScheme.tertiary
                    : context.colorScheme.primary,
              ),
              const SizedBox(width: BatshSpacing.xxs),
              Flexible(
                child: Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.md,
        vertical: BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer.withValues(alpha: 0.52),
        borderRadius: BatshRadius.brMd,
        border: Border.all(
          color: context.colorScheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: BatshIconSize.inline,
            color: context.colorScheme.secondary,
          ),
          const SizedBox(width: BatshSpacing.xs),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: BatshTypography.labelMd.copyWith(
                color: context.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.marginMobile,
        BatshSpacing.md,
        BatshSpacing.marginMobile,
        0,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: BatshSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _PortfolioProof extends StatelessWidget {
  const _PortfolioProof({
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
      return const SizedBox(
        height: 174,
        child: BatshShimmerBox(height: 174, borderRadius: BatshRadius.brImage),
      );
    }
    if (failed) {
      return Container(
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
            TextButton(onPressed: onRetry, child: Text(context.l10n.tryAgain)),
          ],
        ),
      );
    }

    final cards = <_PortfolioCardData>[
      for (final project in projects.take(3))
        _PortfolioCardData(
          url: project.coverPhotoUrl,
          title: project.title,
          subtitle: project.location ?? project.category ?? '',
          onTap: () => context.push(
            Routes.homeownerProjectDetailPath(listing.id, project.id),
          ),
          isPlaceholder: false,
        ),
    ];
    for (var index = cards.length; index < 3; index++) {
      final specialty = switch (index) {
        0 => 'full_reno',
        1 => 'design',
        _ => 'paint',
      };
      cards.add(
        _PortfolioCardData(
          url: mockupPortfolioImages[index],
          title: localizedSpecialtyLabel(context, specialty),
          subtitle: context.l10n.recentWorkTitle,
          isPlaceholder: true,
        ),
      );
    }

    return SizedBox(
      height: 174,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0) const SizedBox(width: BatshSpacing.sm),
              Expanded(child: _PortfolioTile(data: cards[index])),
            ],
          ],
        ),
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.data});

  final _PortfolioCardData data;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BatshRadius.brImage,
      child: BatshPressable(
        onTap: data.onTap,
        semanticLabel: data.isPlaceholder
            ? '${data.title}, ${context.l10n.sampleImagesLabel}'
            : data.title,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MockupImage(url: data.url, memCacheWidth: 520),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Color(0xD9000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
            if (data.isPlaceholder)
              const PositionedDirectional(
                top: BatshSpacing.sm,
                end: BatshSpacing.sm,
                child: MockupSampleBadge(),
              ),
            PositionedDirectional(
              start: BatshSpacing.sm,
              end: BatshSpacing.sm,
              bottom: BatshSpacing.sm,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (data.subtitle.isNotEmpty)
                      Text(
                        data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelSm.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ProofStrip extends StatelessWidget {
  const _ProofStrip({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final values = [
      (
        icon: Icons.verified_user_outlined,
        value: listing.verified
            ? context.l10n.verified
            : context.l10n.newProfessional,
        label: context.l10n.verifiedIdentity,
      ),
      (
        icon: Icons.home_work_outlined,
        value: '${listing.projectsCompleted}',
        label: context.l10n.projects,
      ),
      (
        icon: Icons.workspace_premium_outlined,
        value: listing.yearsExperience == null
            ? '—'
            : '${listing.yearsExperience}',
        label: context.l10n.yearsExperience,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.marginMobile,
        BatshSpacing.lg,
        BatshSpacing.marginMobile,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brCard,
          border: Border.all(color: context.colorScheme.outlineVariant),
          boxShadow: BatshShadows.soft,
        ),
        child: Row(
          children: [
            for (var index = 0; index < values.length; index++) ...[
              if (index > 0)
                Container(
                  width: 1,
                  height: 34,
                  color: context.colorScheme.outlineVariant,
                ),
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      values[index].icon,
                      color: context.colorScheme.secondary,
                      size: BatshIconSize.md,
                    ),
                    const SizedBox(height: BatshSpacing.xxs),
                    Text(
                      values[index].value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      values[index].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
    return SizedBox(
      height: 180,
      child: Directionality(
        textDirection: TextDirection.ltr,
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
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.45,
                        ),
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
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
            ),
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
              color: context.colorScheme.tertiary,
            ),
        ],
      ),
    );
  }
}

class _AboutProfessional extends StatelessWidget {
  const _AboutProfessional({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BatshSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BatshRadius.brCard,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(listing.bio!, style: BatshTypography.bodyLg),
            if (listing.specialties.isNotEmpty) ...[
              const SizedBox(height: BatshSpacing.md),
              Wrap(
                spacing: BatshSpacing.xs,
                runSpacing: BatshSpacing.xs,
                children: [
                  for (final specialty in listing.specialties.take(5))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BatshSpacing.sm,
                        vertical: BatshSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceContainerLowest,
                        borderRadius: BatshRadius.brFull,
                        border: Border.all(
                          color: context.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        localizedSpecialtyLabel(context, specialty),
                        style: BatshTypography.labelSm,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.width = 54,
    this.height = 56,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: selected
              ? context.colorScheme.primary
              : context.colorScheme.onSurface,
          side: BorderSide(color: context.colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BatshRadius.brDefault),
        ),
        child: Icon(icon, semanticLabel: tooltip),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class _PortfolioCardData {
  const _PortfolioCardData({
    required this.url,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isPlaceholder = false,
  });

  final String url;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isPlaceholder;
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
    if (url == null || url.isEmpty || !seen.add(url)) return;
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
  if (items.isEmpty) add(mockupHeroImage, null, true);
  for (var index = 0; items.length < 4; index++) {
    add(
      mockupPortfolioImages[index % mockupPortfolioImages.length],
      null,
      true,
    );
  }
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
