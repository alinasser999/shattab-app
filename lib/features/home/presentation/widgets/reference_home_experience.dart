import 'package:flutter/material.dart';

import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart' as core;
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/batsh_search_bar.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../domain/reference_home_data.dart';
import 'home_live_states.dart';
import 'home_reference_sections.dart';

/// Geometry for the homeowner mobile composition. These values stay local to
/// the reference surface so the repair can restore the approved breathing
/// room without changing unrelated product screens.
abstract final class _ReferenceHomeMetrics {
  static const double pageGutter = 14;
  static const double headingGap = 8;
  static const double sectionGap = 18;
  static const double mediaHeadingGap = 8;
  static const double heroHeight = 195;
  static const double projectHeight = 190;
  static const double featuredRailHeight = 264;
  static const double topRatedRailHeight = 240;
  static const double featuredLargeTextRailMinimumHeight = 736;
  static const double topRatedLargeTextRailMinimumHeight = 656;
  static const double workHeight = 151;
  static const double communityCardHeight = 142;
  static const double serviceRailHeight = 64;
}

const Color _homeServiceRailBorder = Color(0xFFEDE2D5);
const Color _homeCommunityInviteSurface = Color(0xFFFDF9F4);
const Color _homeClosingGradientStart = Color(0xFFA13D1E);
const Color _homeClosingGradientMiddle = Color(0xFFB44B2A);
const Color _homeClosingGradientEnd = Color(0xFFC45735);

bool _usesResponsiveProfessionalCardText(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 360 ||
    MediaQuery.textScalerOf(context).scale(1) > 1.2;

bool _usesCompactProfessionalCardActions(BuildContext context) =>
    _usesResponsiveProfessionalCardText(context);

double _professionalRailHeight(
  BuildContext context, {
  required double referenceHeight,
  required List<ReferenceHomeProfessional> items,
  required double Function(BuildContext, ReferenceHomeProfessional)
  measureCardHeight,
  double? largeTextMinimumHeight,
}) {
  final textScale = MediaQuery.textScalerOf(context).scale(1);
  if (!_usesResponsiveProfessionalCardText(context)) return referenceHeight;

  var railHeight = referenceHeight * (textScale < 1 ? 1 : textScale);
  if (items.isEmpty) return railHeight;

  var tallestCardHeight = 0.0;
  for (final item in items) {
    final measuredHeight = measureCardHeight(context, item);
    if (measuredHeight > tallestCardHeight) {
      tallestCardHeight = measuredHeight;
    }
  }

  // Keep a small allowance for paragraph rounding and row baselines; all
  // content heights themselves are measured at each card's actual width.
  final measuredRailHeight = tallestCardHeight + 16;
  if (measuredRailHeight > railHeight) railHeight = measuredRailHeight;

  // The 320dp / 1.6x Stitch fixtures need these minimum extents. The text
  // measurement above still grows the rail further for longer live listings.
  if (textScale >= 1.6 && largeTextMinimumHeight != null) {
    if (largeTextMinimumHeight > railHeight) {
      railHeight = largeTextMinimumHeight;
    }
  }
  return railHeight;
}

double _measuredProfessionalTextHeight(
  BuildContext context, {
  required String text,
  required TextStyle style,
  required double maxWidth,
  TextDirection? textDirection,
}) {
  if (text.isEmpty) return 0;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection ?? Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.localeOf(context),
  )..layout(maxWidth: maxWidth);
  return painter.height;
}

double _largerHeight(double first, double second) =>
    first > second ? first : second;

double _featuredProfessionalCardHeight(
  BuildContext context,
  ReferenceHomeProfessional item,
) {
  const detailWidth = 125.0;
  final specialty = _specialtyLabel(context, item.specialty);
  final nameHeight = _measuredProfessionalTextHeight(
    context,
    text: item.name,
    style: _HomeTypography.labelLg.copyWith(
      fontSize: 16,
      height: 23 / 16,
      fontWeight: FontWeight.w700,
    ),
    maxWidth: detailWidth,
  );
  final specialtyHeight = _measuredProfessionalTextHeight(
    context,
    text: specialty,
    style: _HomeTypography.labelSm.copyWith(fontSize: 14, height: 20 / 14),
    maxWidth: detailWidth,
  );
  final ratingHeight = _largerHeight(
    18,
    _measuredProfessionalTextHeight(
      context,
      text: '${_ratingText(item)} (${item.reviewCount})',
      style: _HomeTypography.labelSm.copyWith(
        fontSize: 13,
        height: 19 / 13,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: detailWidth - 20,
      textDirection: TextDirection.ltr,
    ),
  );
  final projectHeight = _largerHeight(
    16,
    _measuredProfessionalTextHeight(
      context,
      text: '${item.projectsCompleted} ${context.l10n.completedProjectsShort}',
      style: _HomeTypography.labelSm.copyWith(fontSize: 13, height: 19 / 13),
      maxWidth: detailWidth - 18,
    ),
  );
  final locationHeight = _largerHeight(
    16,
    _measuredProfessionalTextHeight(
      context,
      text: item.location,
      style: _HomeTypography.labelSm.copyWith(fontSize: 13, height: 19 / 13),
      maxWidth: detailWidth - 18,
    ),
  );
  final quoteButtonHeight = _largerHeight(
    BatshSpacing.minHitArea,
    _measuredProfessionalTextHeight(
      context,
      text: context.l10n.homeReferenceRequestQuote,
      style: _HomeTypography.labelMd.copyWith(
        color: context.colorScheme.onPrimary,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: detailWidth - (2 * BatshSpacing.sm),
    ),
  );
  final detailContentHeight =
      nameHeight +
      BatshSpacing.xxxs +
      specialtyHeight +
      BatshSpacing.xxxs +
      ratingHeight +
      BatshSpacing.xxxs +
      projectHeight +
      BatshSpacing.xxxs +
      locationHeight +
      BatshSpacing.minHitArea +
      BatshSpacing.xs +
      quoteButtonHeight;
  return 88 + 20 + detailContentHeight;
}

double _rankedProfessionalCardHeight(
  BuildContext context,
  ReferenceHomeProfessional item,
) {
  const cardContentWidth = 99.0;
  final nameHeight = _measuredProfessionalTextHeight(
    context,
    text: item.name,
    style: _HomeTypography.labelLg.copyWith(
      fontSize: 17,
      height: 24 / 17,
      fontWeight: FontWeight.w700,
    ),
    maxWidth: cardContentWidth,
  );
  final specialtyHeight = _measuredProfessionalTextHeight(
    context,
    text: _specialtyLabel(context, item.specialty),
    style: _HomeTypography.labelSm.copyWith(fontSize: 14, height: 20 / 14),
    maxWidth: cardContentWidth,
  );
  final ratingHeight = _largerHeight(
    18,
    _measuredProfessionalTextHeight(
      context,
      text: '${_ratingText(item)} (${item.reviewCount})',
      style: _HomeTypography.labelSm.copyWith(
        fontSize: 13,
        height: 19 / 13,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: cardContentWidth - 20,
      textDirection: TextDirection.ltr,
    ),
  );
  final locationHeight = _largerHeight(
    16,
    _measuredProfessionalTextHeight(
      context,
      text: item.location,
      style: _HomeTypography.labelSm.copyWith(fontSize: 13, height: 19 / 13),
      maxWidth: cardContentWidth - 17,
    ),
  );
  final buttonHeight = _largerHeight(
    BatshSpacing.minHitArea,
    _measuredProfessionalTextHeight(
      context,
      text: context.l10n.homeReferenceViewProfile,
      style: _HomeTypography.labelMd.copyWith(
        color: context.colorScheme.onPrimary,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: cardContentWidth - (2 * BatshSpacing.sm),
    ),
  );
  return (2 * BatshSpacing.sm) +
      48 +
      BatshSpacing.xs +
      nameHeight +
      BatshSpacing.xxxs +
      specialtyHeight +
      BatshSpacing.xxxs +
      ratingHeight +
      BatshSpacing.xxxs +
      locationHeight +
      BatshSpacing.xxxs +
      buttonHeight;
}

/// Applies Stitch's locally bundled face without changing shared typography.
abstract final class _HomeTypography {
  static const String _family = 'Tajawal';

  static TextStyle get titleLg =>
      core.BatshTypography.titleLg.copyWith(fontFamily: _family);
  static TextStyle get titleMd =>
      core.BatshTypography.titleMd.copyWith(fontFamily: _family);
  static TextStyle get headlineSm =>
      core.BatshTypography.headlineSm.copyWith(fontFamily: _family);
  static TextStyle get bodySm =>
      core.BatshTypography.bodySm.copyWith(fontFamily: _family);
  static TextStyle get labelLg =>
      core.BatshTypography.labelLg.copyWith(fontFamily: _family);
  static TextStyle get labelMd =>
      core.BatshTypography.labelMd.copyWith(fontFamily: _family);
  static TextStyle get labelSm =>
      core.BatshTypography.labelSm.copyWith(fontFamily: _family);
}

/// The homeowner landing composition from the supplied Shattab references.
///
/// This widget owns presentation only. The screen supplies real provider data
/// and callbacks for routing/repository actions, which keeps every control
/// testable without making this large visual surface a second data layer.
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
  Widget build(BuildContext context) {
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
        _HomeEntrance(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: BatshSpacing.sm),
              ReferenceHomeHero(
                onStartProject: onStartProject,
                onExploreProfessionals: onOpenFeaturedProfessionals,
                child: _ReferenceHero(
                  controller: searchController,
                  onSubmitted: onSearchSubmitted,
                  onChanged: onSearchChanged,
                  onClear: onSearchClear,
                  onStartProject: onStartProject,
                  onSelectService: onSelectService,
                  imageUrl: ReferenceHomePreviewData.heroImage,
                ),
              ),
              const SizedBox(height: BatshSpacing.ml),
              if (staticPreview)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _ReferenceHomeMetrics.pageGutter,
                  ),
                  child: _ReferenceProjectSection(
                    project: project,
                    onStartProject: onStartProject,
                    onOpenProject: onOpenProject,
                    onOpenOffers: onOpenProjectOffers,
                    onOpenDetails: onOpenProjectDetails,
                    showOfferCount: showOfferCount,
                  ),
                )
              else
                HomeLiveStateSection(
                  onOpenRequests: onStartProject,
                  onOpenNotifications: onNotificationTap,
                  onStartRequest: onStartProject,
                  childHorizontalInset: _ReferenceHomeMetrics.pageGutter,
                  child: _ReferenceProjectSection(
                    project: project,
                    onStartProject: onStartProject,
                    onOpenProject: onOpenProject,
                    onOpenOffers: onOpenProjectOffers,
                    onOpenDetails: onOpenProjectDetails,
                    showOfferCount: showOfferCount,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: _ReferenceHomeMetrics.sectionGap),
        _ReferenceSectionHeader(
          title: context.l10n.homeReferenceFeaturedTitle,
          iconEmoji: '👑',
          onViewAll: onOpenFeaturedProfessionals,
        ),
        const SizedBox(height: _ReferenceHomeMetrics.headingGap),
        _FeaturedProfessionalsRail(
          items: featuredProfessionals,
          loading: professionalsLoading,
          error: professionalsError,
          onRetry: onRetryProfessionals,
          savedIds: savedProfessionalIds,
          onOpen: onOpenProfessional,
          onQuote: onRequestQuote,
          onToggleSaved: onToggleSaved,
          onViewAll: onOpenFeaturedProfessionals,
        ),
        const SizedBox(height: _ReferenceHomeMetrics.sectionGap),
        _ReferenceSectionHeader(
          title: context.l10n.homeReferenceServicesTitle,
          onViewAll: onOpenFeaturedProfessionals,
        ),
        const SizedBox(height: _ReferenceHomeMetrics.headingGap),
        _ServiceRail(onSelect: onSelectService),
        const SizedBox(height: _ReferenceHomeMetrics.sectionGap),
        _ReferenceSectionHeader(
          title: context.l10n.topRated,
          subtitle: context.l10n.homeReferenceTopRatedSubtitle,
          onViewAll: onOpenTopRated,
        ),
        const SizedBox(height: _ReferenceHomeMetrics.headingGap),
        _TopRatedRail(
          items: topRatedProfessionals,
          loading: topRatedLoading,
          error: topRatedError,
          onRetry: onRetryTopRated,
          savedIds: savedProfessionalIds,
          onOpen: onOpenProfessional,
          onQuote: onRequestQuote,
          onToggleSaved: onToggleSaved,
          onViewAll: onOpenTopRated,
        ),
        const SizedBox(height: _ReferenceHomeMetrics.sectionGap),
        _ReferenceSectionHeader(
          title: context.l10n.recentWorkTitle,
          onViewAll: onOpenCompletedWork,
        ),
        const SizedBox(height: _ReferenceHomeMetrics.mediaHeadingGap),
        _WorkSection(
          work: work,
          loading: workLoading,
          error: workError,
          onRetry: onRetryWork,
          onOpen: onOpenWork,
          onViewAll: onOpenCompletedWork,
        ),
        const SizedBox(height: _ReferenceHomeMetrics.sectionGap),
        _ReferenceSectionHeader(
          title: context.l10n.homeReferenceCommunityTitle,
          onViewAll: onOpenCommunityFeed,
        ),
        const SizedBox(height: _ReferenceHomeMetrics.mediaHeadingGap),
        _CommunitySection(
          posts: communityPosts,
          loading: communityLoading,
          error: communityError,
          onRetry: onRetryCommunity,
          onOpen: onOpenCommunity,
          onCreatePost: onCreatePost,
        ),
        const SizedBox(height: _ReferenceHomeMetrics.sectionGap),
        _ClosingCta(onTap: onOpenClosingCta),
      ],
    );
  }
}

/// Introduces only the first renovation decision and the current project.
/// The controller belongs to this mounted experience, so provider rebuilds
/// update the content without replaying its entrance.
class _HomeEntrance extends StatefulWidget {
  const _HomeEntrance({required this.child});

  final Widget child;

  @override
  State<_HomeEntrance> createState() => _HomeEntranceState();
}

class _HomeEntranceState extends State<_HomeEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: BatshMotion.slow,
    value: 0,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: BatshMotion.easeOut,
  );
  late final Animation<Offset> _position = Tween<Offset>(
    begin: const Offset(0, 0.025),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: BatshMotion.heroEase));

  var _motionResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_motionResolved) {
      _motionResolved = true;
      if (reduceMotion) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    } else if (reduceMotion && !_controller.isCompleted) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      alwaysIncludeSemantics: true,
      child: SlideTransition(position: _position, child: widget.child),
    );
  }
}

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

  final String locationLabel;
  final String homeownerName;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) {
    final greeting = context.l10n.greetingPersonalized(
      context.l10n.greetingEvening,
      homeownerName,
    );

    return Semantics(
      container: true,
      label: '$greeting، $locationLabel',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 340;
            final accountButton = BatshPressable(
              onTap: onAccountTap,
              semanticLabel: context.l10n.profileTitle,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: _ReferenceAvatar(
                    imageUrl: avatarUrl,
                    name: homeownerName,
                    radius: 18,
                  ),
                ),
              ),
            );
            final notificationButton = _HeaderCircleButton(
              icon: Icons.notifications_none_rounded,
              label: unreadCount > 0
                  ? '${context.l10n.notificationsTitle}، $unreadCount'
                  : context.l10n.notificationsTitle,
              onTap: onNotificationTap,
              badgeCount: unreadCount,
            );
            final locationPill = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 104 : 108),
              child: _LocationPill(label: locationLabel, onTap: onLocationTap),
            );
            final brand = SizedBox(
              width: 66,
              child: Semantics(
                image: true,
                label: context.l10n.appName,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            Icons.home_rounded,
                            size: 18,
                            color: context.colorScheme.primary,
                          ),
                          Text(
                            'شَطّب',
                            style: _HomeTypography.titleMd.copyWith(
                              fontSize: 16,
                              height: 18 / 16,
                              color: context.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'S H A T T A B',
                      textDirection: TextDirection.ltr,
                      style: _HomeTypography.labelSm.copyWith(
                        fontSize: 5.5,
                        height: 7 / 5.5,
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
            final greetingCopy = Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  greeting,
                  maxLines: compact ? null : 1,
                  overflow: compact
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: _HomeTypography.titleMd.copyWith(
                    fontSize: 13,
                    height: 17 / 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  context.l10n.homeReferenceGreetingTagline,
                  maxLines: compact ? null : 1,
                  overflow: compact
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: _HomeTypography.labelSm.copyWith(
                    fontSize: 9.5,
                    height: 12 / 9.5,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        accountButton,
                        notificationButton,
                        const Spacer(),
                        brand,
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(child: greetingCopy),
                      const SizedBox(width: 4),
                      locationPill,
                    ],
                  ),
                ],
              );
            }

            return SizedBox(
              height: 52,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        accountButton,
                        notificationButton,
                        const SizedBox(width: 2),
                        Expanded(child: greetingCopy),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  locationPill,
                  const SizedBox(width: 8),
                  brand,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReferenceAvatar extends StatelessWidget {
  const _ReferenceAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
  });

  final String? imageUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final value = imageUrl?.trim() ?? '';
    if (!value.startsWith('assets/')) {
      return AvatarWithInitials(imageUrl: imageUrl, name: name, radius: radius);
    }
    return ClipOval(
      child: Image.asset(
        value,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            AvatarWithInitials(imageUrl: null, name: name, radius: radius),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.badgeCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BatshPressable(
          onTap: onTap,
          semanticLabel: label,
          child: SizedBox(
            width: BatshSpacing.minHitArea,
            height: BatshSpacing.minHitArea,
            child: Icon(
              icon,
              size: BatshIconSize.action,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
        if (badgeCount > 0)
          PositionedDirectional(
            top: 8,
            end: 7,
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: const SizedBox(width: 9, height: 9),
              ),
            ),
          ),
      ],
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: '${context.l10n.changeLocation}: $label',
      child: Container(
        constraints: const BoxConstraints(minHeight: BatshSpacing.minHitArea),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brFull,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.location_on_rounded,
              color: context.colorScheme.error,
              size: 18,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _HomeTypography.labelMd.copyWith(
                  fontSize: 13,
                  height: 19 / 13,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ReferenceHero extends StatelessWidget {
  const _ReferenceHero({
    required this.controller,
    required this.onSubmitted,
    required this.onChanged,
    required this.onClear,
    required this.onStartProject,
    required this.onSelectService,
    required this.imageUrl,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onStartProject;
  final ValueChanged<String> onSelectService;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _ReferenceHomeMetrics.pageGutter,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final extraHeight = ((textScale - 1) * 520).clamp(0, 680).toDouble();
          final compactWidthExtra = constraints.maxWidth < 300 ? 36.0 : 0.0;
          final compactShortcuts = constraints.maxWidth < 322;
          final shortcutHeight = compactShortcuts
              ? 40 + (36 * textScale)
              : 62.0;
          return SizedBox(
            height:
                _ReferenceHomeMetrics.heroHeight +
                extraHeight +
                compactWidthExtra,
            child: ClipRRect(
              borderRadius: BatshRadius.brLg,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ReferenceHeroImage(imageUrl: imageUrl),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    width: constraints.maxWidth * 0.68,
                    top: 12,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            context.l10n.homeReferenceHeroTitleLineOne,
                            maxLines: textScale <= 1 ? 1 : null,
                            textAlign: TextAlign.right,
                            style: _HomeTypography.titleLg.copyWith(
                              fontSize: 17,
                              height: 22 / 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            context.l10n.homeReferenceHeroTitleLineTwo,
                            maxLines: textScale <= 1 ? 1 : null,
                            textAlign: TextAlign.right,
                            style: _HomeTypography.titleLg.copyWith(
                              fontSize: 17,
                              height: 22 / 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.homeReferenceHeroSupportBody,
                            maxLines: textScale <= 1 ? 2 : null,
                            overflow: textScale <= 1
                                ? TextOverflow.ellipsis
                                : TextOverflow.visible,
                            textAlign: TextAlign.right,
                            style: _HomeTypography.labelSm.copyWith(
                              fontSize: 9.5,
                              height: 12 / 9.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * 0.35,
                    right: 12,
                    bottom: compactShortcuts ? shortcutHeight + 12 : 64,
                    child: BatshSearchBar(
                      controller: controller,
                      onChanged: onChanged,
                      onClear: onClear,
                      onSubmitted: onSubmitted,
                      hintText: context.l10n.homeSearchHint,
                      height: controller.text.isNotEmpty || textScale > 1.2
                          ? BatshSpacing.minHitArea
                          : 32,
                      fontFamily: 'Tajawal',
                      iconSize: 16,
                      iconColor: BatshColors.homeAction,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      clearButtonLargeTarget: true,
                      borderRadius: BatshRadius.brFull,
                      rowTextDirection: TextDirection.rtl,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      plainInput: true,
                    ),
                  ),
                  Positioned(
                    left: compactShortcuts ? 8 : constraints.maxWidth * 0.23,
                    right: 8,
                    bottom: 2,
                    child: _ServiceShortcutRow(
                      onSelect: onSelectService,
                      compact: compactShortcuts,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReferenceHeroImage extends StatelessWidget {
  const _ReferenceHeroImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallback = ColoredBox(
          color: context.colorScheme.surfaceContainerHigh,
          child: Icon(
            Icons.home_work_outlined,
            color: context.colorScheme.primary,
            size: 52,
          ),
        );
        final value = imageUrl?.trim() ?? '';
        if (value.startsWith('http')) {
          return Image.network(
            value,
            fit: BoxFit.cover,
            alignment: const Alignment(-0.16, 0.08),
            semanticLabel: context.l10n.homeReferenceHeroTitleLineTwo,
            errorBuilder: (_, _, _) => fallback,
          );
        }
        return Image.asset(
          value.startsWith('assets/')
              ? value
              : ReferenceHomePreviewData.beforeAfterImage,
          fit: BoxFit.cover,
          alignment: const Alignment(-0.16, 0.08),
          semanticLabel: context.l10n.homeReferenceHeroTitleLineTwo,
          errorBuilder: (_, _, _) => fallback,
        );
      },
    );
  }
}

class _ServiceShortcutRow extends StatelessWidget {
  const _ServiceShortcutRow({required this.onSelect, required this.compact});

  final ValueChanged<String> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData)>[
      ('plumbing', context.l10n.specialtyPlumbing, specialtyIcon('plumbing')),
      (
        'electrical',
        context.l10n.specialtyElectrical,
        specialtyIcon('electrical'),
      ),
      ('paint', context.l10n.specialtyPaint, specialtyIcon('paint')),
      ('design', context.l10n.specialtyDesign, specialtyIcon('design')),
      (
        'full_reno',
        context.l10n.specialtyFullRenovation,
        specialtyIcon('full_reno'),
      ),
    ];

    Widget shortcutItem((String, String, IconData) item, {double? width}) {
      return SizedBox(
        width: width,
        child: BatshPressable(
          onTap: () => onSelect(item.$1),
          semanticLabel: item.$2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerLowest,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      item.$3,
                      size: 18,
                      color: context.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: BatshSpacing.xxs),
                Text(
                  item.$2,
                  maxLines: compact ? 3 : 2,
                  overflow: compact
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: _HomeTypography.labelSm.copyWith(
                    fontSize: 9,
                    height: 11 / 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (compact) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      return SizedBox(
        height: 40 + (36 * textScale),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.xxs),
          itemBuilder: (context, index) =>
              shortcutItem(items[index], width: BatshSpacing.minHitArea),
        ),
      );
    }

    return Row(
      textDirection: TextDirection.rtl,
      children: [for (final item in items) Expanded(child: shortcutItem(item))],
    );
  }
}

class _ReferenceProjectSection extends StatelessWidget {
  const _ReferenceProjectSection({
    required this.project,
    required this.onStartProject,
    required this.onOpenProject,
    required this.onOpenOffers,
    required this.onOpenDetails,
    required this.showOfferCount,
  });

  final ReferenceHomeProject? project;
  final VoidCallback onStartProject;
  final ValueChanged<ReferenceHomeProject> onOpenProject;
  final ValueChanged<ReferenceHomeProject> onOpenOffers;
  final ValueChanged<ReferenceHomeProject> onOpenDetails;
  final bool showOfferCount;

  @override
  Widget build(BuildContext context) {
    final item = project;
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brCard,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: BatshShadows.soft,
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.l10n.homeLiveEmptyTitle,
                    textAlign: TextAlign.right,
                    style: _HomeTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xxs),
                  Text(
                    context.l10n.homeLiveEmptyMessage,
                    textAlign: TextAlign.right,
                    style: _HomeTypography.bodySm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            _CircleAction(
              icon: Icons.add_home_work_outlined,
              label: context.l10n.homeReferenceHeroPrimary,
              onTap: onStartProject,
            ),
          ],
        ),
      );
    }

    final percent = (item.progress * 100).round();
    final compact = MediaQuery.sizeOf(context).width < 360;
    final cardHeight = _ReferenceHomeMetrics.projectHeight;
    final previewOfferAvatars = item.isPreview
        ? item.previewOfferAvatarPaths.take(2).toList(growable: false)
        : const <String>[];
    Widget offersAction({required bool fitLabelToWidth}) => _OffersButton(
      count: item.offerCount,
      avatarPaths: previewOfferAvatars,
      onTap: () => onOpenOffers(item),
      fitLabelToWidth: fitLabelToWidth,
      minHeight: BatshSpacing.minHitArea,
    );
    Widget followAction({required bool fitLabelToWidth}) =>
        _ProjectFollowButton(
          label: context.l10n.homeReferenceProjectFollow,
          onTap: () => onOpenProject(item),
          wrapLabelForCompactText: compact,
          fitLabelToWidth: fitLabelToWidth,
        );
    final Widget actions = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showOfferCount) offersAction(fitLabelToWidth: false),
              if (showOfferCount) const SizedBox(height: BatshSpacing.xxs),
              followAction(fitLabelToWidth: false),
            ],
          )
        : Row(
            textDirection: Directionality.of(context),
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showOfferCount)
                Flexible(
                  fit: FlexFit.loose,
                  child: offersAction(fitLabelToWidth: true),
                ),
              if (showOfferCount)
                Flexible(
                  fit: FlexFit.loose,
                  child: followAction(fitLabelToWidth: true),
                )
              else
                followAction(fitLabelToWidth: false),
            ],
          );
    final projectMedia = Container(
      width: compact ? double.infinity : 112,
      height: compact ? 112 : 82,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BatshRadius.brMd),
      foregroundDecoration: BoxDecoration(
        borderRadius: BatshRadius.brMd,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ReferenceMedia(
            url: item.imageUrl,
            assetPath: item.imageUrl.startsWith('assets/')
                ? item.imageUrl
                : null,
            semanticLabel: item.title,
          ),
          Positioned(
            left: BatshSpacing.xxs,
            right: BatshSpacing.xxs,
            bottom: BatshSpacing.xxs,
            child: _ImageOverlayButton(
              label: context.l10n.homeReferenceProjectDetails,
              onTap: () => onOpenDetails(item),
            ),
          ),
        ],
      ),
    );
    final wrapProjectStatus = MediaQuery.textScalerOf(context).scale(1) > 1.0;
    final projectStatusLabel = Text(
      context.l10n.homeReferenceProjectStatus,
      maxLines: wrapProjectStatus ? 2 : null,
      softWrap: wrapProjectStatus,
      overflow: TextOverflow.ellipsis,
      style: _HomeTypography.labelSm.copyWith(
        fontSize: 10,
        height: 12 / 10,
        color: context.colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w700,
      ),
    );
    final projectDetails = Padding(
      padding: compact
          ? const EdgeInsetsDirectional.fromSTEB(
              BatshSpacing.sm,
              BatshSpacing.xs,
              BatshSpacing.sm,
              BatshSpacing.xs,
            )
          : EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.secondaryContainer,
              borderRadius: BatshRadius.brFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: Directionality.of(context),
              children: [
                if (wrapProjectStatus)
                  Flexible(fit: FlexFit.loose, child: projectStatusLabel)
                else
                  projectStatusLabel,
                const SizedBox(width: BatshSpacing.xxs),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  size: BatshIconSize.xs,
                  color: context.colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
          const SizedBox(height: BatshSpacing.xxs),
          BatshPressable(
            onTap: () => onOpenProject(item),
            semanticLabel: item.title,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                item.title,
                maxLines: compact ? 2 : 1,
                overflow: compact
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: _HomeTypography.titleMd.copyWith(
                  fontSize: 14.5,
                  height: 18 / 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.xxxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: BatshIconSize.xs,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: BatshSpacing.xxxs),
              Flexible(
                child: Text(
                  item.location,
                  maxLines: compact ? 2 : 1,
                  overflow: compact
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: _HomeTypography.labelSm.copyWith(
                    fontSize: 10.5,
                    height: 13 / 10.5,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            textDirection: Directionality.of(context),
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BatshRadius.brFull,
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: item.progress.clamp(0, 1).toDouble(),
                    backgroundColor: context.colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(
                      context.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                '$percent%',
                textDirection: TextDirection.ltr,
                style: _HomeTypography.labelSm.copyWith(
                  fontSize: 10,
                  height: 12 / 10,
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xxxs),
          Text(
            item.stage,
            maxLines: compact ? 2 : 1,
            overflow: compact ? TextOverflow.visible : TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: _HomeTypography.labelSm.copyWith(
              fontSize: 9.5,
              height: 12 / 9.5,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    final projectContent = compact
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              projectMedia,
              projectDetails,
              Padding(
                padding: const EdgeInsets.only(top: BatshSpacing.xxs),
                child: actions,
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.all(BatshSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    projectMedia,
                    const SizedBox(width: 10),
                    Expanded(child: projectDetails),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: BatshSpacing.xxs),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: context.colorScheme.outlineVariant.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ),
                  child: actions,
                ),
              ],
            ),
          );
    return Semantics(
      container: true,
      label:
          '${context.l10n.homeReferenceProjectStatus}. ${item.title}. ${item.stage}. ${context.l10n.homeReferenceProjectProgress(percent)}',
      child: Container(
        constraints: compact ? null : BoxConstraints(minHeight: cardHeight),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brLg,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: BatshShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: projectContent,
      ),
    );
  }
}

class _ReferenceSectionHeader extends StatelessWidget {
  const _ReferenceSectionHeader({
    required this.title,
    required this.onViewAll,
    this.subtitle,
    this.iconEmoji,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;
  final String? iconEmoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _ReferenceHomeMetrics.pageGutter,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Semantics(
                  header: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    textDirection: TextDirection.rtl,
                    children: [
                      if (iconEmoji != null) ...[
                        Text(
                          iconEmoji!,
                          style: const TextStyle(fontSize: 20, height: 1),
                        ),
                        const SizedBox(width: BatshSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.right,
                          style: _HomeTypography.headlineSm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: _HomeTypography.labelSm.copyWith(
                      fontSize: 11,
                      height: 14 / 11,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          if (onViewAll != null)
            BatshPressable(
              onTap: onViewAll,
              semanticLabel: context.l10n.viewAll,
              child: SizedBox(
                height: BatshSpacing.minHitArea,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        context.l10n.viewAll,
                        style: _HomeTypography.labelLg.copyWith(
                          color: context.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: BatshSpacing.xxxs),
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 19,
                        color: context.colorScheme.error,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedProfessionalsRail extends StatelessWidget {
  const _FeaturedProfessionalsRail({
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.savedIds,
    required this.onOpen,
    required this.onQuote,
    required this.onToggleSaved,
    required this.onViewAll,
  });

  final List<ReferenceHomeProfessional> items;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final Set<String> savedIds;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onQuote;
  final ValueChanged<String> onToggleSaved;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final railHeight = _professionalRailHeight(
      context,
      referenceHeight: _ReferenceHomeMetrics.featuredRailHeight,
      items: items,
      measureCardHeight: _featuredProfessionalCardHeight,
      largeTextMinimumHeight:
          _ReferenceHomeMetrics.featuredLargeTextRailMinimumHeight,
    );
    if (loading) {
      return _RailSkeleton(height: railHeight, count: 3);
    }
    if (error != null) {
      return _RailError(message: error!, onRetry: onRetry);
    }
    if (items.isEmpty) {
      return _EmptyRail(
        message: context.l10n.homeFeaturedEmptyTitle,
        action: context.l10n.homeStartDiscoverTitle,
        onTap: onViewAll,
      );
    }
    return SizedBox(
      height: railHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: _ReferenceHomeMetrics.pageGutter,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.xs),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ProfessionalCard(
            item: item,
            isSaved: savedIds.contains(item.id),
            onOpen: () => onOpen(item.id),
            onQuote: () => onQuote(item.id),
            onToggleSaved: () => onToggleSaved(item.id),
          );
        },
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({
    required this.item,
    required this.isSaved,
    required this.onOpen,
    required this.onQuote,
    required this.onToggleSaved,
  });

  final ReferenceHomeProfessional item;
  final bool isSaved;
  final VoidCallback onOpen;
  final VoidCallback onQuote;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final specialty = _specialtyLabel(context, item.specialty);
    final responsiveText = _usesResponsiveProfessionalCardText(context);
    final compactActions = _usesCompactProfessionalCardActions(context);
    return SizedBox(
      width: 145,
      child: Semantics(
        container: true,
        label: '${item.name}، $specialty، ${_ratingText(item)}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brLg,
            border: Border.all(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: BatshShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 88,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BatshPressable(
                      onTap: onOpen,
                      semanticLabel: item.name,
                      child: _ReferenceMedia(
                        url: item.avatarUrl,
                        assetPath: item.avatarUrl.startsWith('assets/')
                            ? item.avatarUrl
                            : null,
                        fit: BoxFit.cover,
                        semanticLabel: item.name,
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: _SmallIconButton(
                        icon: isSaved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: isSaved
                            ? context.l10n.unsaveTooltip
                            : context.l10n.saveTooltip,
                        active: isSaved,
                        onTap: onToggleSaved,
                        compact: true,
                      ),
                    ),
                    if (item.verified)
                      PositionedDirectional(
                        bottom: 8,
                        end: 8,
                        child: _TrustBadge(
                          label: context.l10n.verifiedByShattab,
                        ),
                      ),
                    if (item.sponsored)
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: _DisclosureBadge(
                          label: context.l10n.homeReferenceSponsored,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BatshPressable(
                        onTap: onOpen,
                        semanticLabel: item.name,
                        child: Text(
                          item.name,
                          maxLines: responsiveText ? null : 1,
                          overflow: responsiveText
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          softWrap: responsiveText,
                          textAlign: TextAlign.right,
                          style: _HomeTypography.labelLg.copyWith(
                            fontSize: 16,
                            height: 23 / 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.xxxs),
                      Text(
                        specialty,
                        maxLines: responsiveText ? null : 1,
                        overflow: responsiveText
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        softWrap: responsiveText,
                        textAlign: TextAlign.right,
                        style: _HomeTypography.labelSm.copyWith(
                          fontSize: 14,
                          height: 20 / 14,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.xxxs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        textDirection: TextDirection.rtl,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: BatshColors.starGold,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${_ratingText(item)} (${item.reviewCount})',
                              maxLines: responsiveText ? null : 1,
                              overflow: responsiveText
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              softWrap: responsiveText,
                              textAlign: TextAlign.end,
                              textDirection: TextDirection.ltr,
                              style: _HomeTypography.labelSm.copyWith(
                                fontSize: 13,
                                height: 19 / 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: BatshSpacing.xxxs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            Icons.business_center_outlined,
                            size: 16,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${item.projectsCompleted} ${context.l10n.completedProjectsShort}',
                              maxLines: responsiveText ? null : 1,
                              overflow: responsiveText
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              softWrap: responsiveText,
                              textAlign: TextAlign.right,
                              style: _HomeTypography.labelSm.copyWith(
                                fontSize: 13,
                                height: 19 / 13,
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: BatshSpacing.xxxs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              item.location,
                              maxLines: responsiveText ? null : 1,
                              overflow: responsiveText
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              softWrap: responsiveText,
                              textAlign: TextAlign.right,
                              style: _HomeTypography.labelSm.copyWith(
                                fontSize: 13,
                                height: 19 / 13,
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (compactActions) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: _SmallIconButton(
                            icon: isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            label: isSaved
                                ? context.l10n.unsaveTooltip
                                : context.l10n.saveTooltip,
                            active: isSaved,
                            outlined: true,
                            onTap: onToggleSaved,
                          ),
                        ),
                        const SizedBox(height: BatshSpacing.xs),
                        SizedBox(
                          width: double.infinity,
                          child: _PrimarySmallButton(
                            label: context.l10n.homeReferenceRequestQuote,
                            onTap: onQuote,
                            minHeight: BatshSpacing.minHitArea,
                            wrapLabel: true,
                          ),
                        ),
                      ] else
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            _SmallIconButton(
                              icon: isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              label: isSaved
                                  ? context.l10n.unsaveTooltip
                                  : context.l10n.saveTooltip,
                              active: isSaved,
                              outlined: true,
                              onTap: onToggleSaved,
                            ),
                            const SizedBox(width: BatshSpacing.xs),
                            Expanded(
                              child: _PrimarySmallButton(
                                label: context.l10n.homeReferenceRequestQuote,
                                onTap: onQuote,
                                minHeight: BatshSpacing.minHitArea,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRail extends StatelessWidget {
  const _ServiceRail({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final keys = <String>[
      'full_reno',
      'design',
      'kitchen',
      'bathroom',
      'electrical',
      'plumbing',
      'more',
    ];
    String labelFor(String key) => switch (key) {
      'more' => context.l10n.more,
      'full_reno' => context.l10n.homeReferenceServiceFullRenovationLabel,
      _ => localizedSpecialtyLabel(context, key),
    };
    final tileHeight = _referenceServiceRailTileHeight(
      context,
      keys.map(labelFor),
    );
    return SizedBox(
      height: tileHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: _ReferenceHomeMetrics.pageGutter,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: keys.length,
        separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.xs),
        itemBuilder: (context, index) {
          final key = keys[index];
          final isMore = key == 'more';
          final label = labelFor(key);
          return SizedBox(
            key: ValueKey<String>('reference-home-service-$key'),
            width: 54,
            height: tileHeight,
            child: BatshPressable(
              onTap: () => onSelect(isMore ? '' : key),
              semanticLabel: label,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BatshColors.homeSoftSurface,
                  borderRadius: BatshRadius.brMd,
                  border: Border.all(color: _homeServiceRailBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isMore
                          ? Icons.more_horiz_rounded
                          : _referenceServiceIcon(key),
                      color: BatshColors.homeAction,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: _HomeTypography.labelMd.copyWith(
                        color: BatshColors.homeInk,
                        fontSize: 9.5,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

IconData _referenceServiceIcon(String key) => switch (key) {
  'full_reno' => Icons.home_outlined,
  'design' => Icons.chair_outlined,
  'kitchen' => Icons.restaurant_menu_rounded,
  'bathroom' => Icons.bathtub_outlined,
  'electrical' => Icons.lightbulb_outline_rounded,
  'plumbing' => Icons.plumbing_outlined,
  _ => Icons.home_repair_service_outlined,
};

double _referenceServiceRailTileHeight(
  BuildContext context,
  Iterable<String> labels,
) {
  final style = _HomeTypography.labelMd.copyWith(
    color: BatshColors.homeInk,
    fontSize: 9.5,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );
  var height = _ReferenceHomeMetrics.serviceRailHeight;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.localeOf(context),
    )..layout(maxWidth: 52);
    // The icon (20dp), icon-label gap (6dp), and 10dp vertical breathing
    // room keep the normal-scale source tile at 64dp while still growing
    // naturally when a label needs additional lines.
    final measuredHeight = painter.height + 36;
    if (measuredHeight > height) height = measuredHeight;
  }
  return height;
}

class _TopRatedRail extends StatelessWidget {
  const _TopRatedRail({
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.savedIds,
    required this.onOpen,
    required this.onQuote,
    required this.onToggleSaved,
    required this.onViewAll,
  });

  final List<ReferenceHomeProfessional> items;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final Set<String> savedIds;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onQuote;
  final ValueChanged<String> onToggleSaved;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final railHeight = _professionalRailHeight(
      context,
      referenceHeight: _ReferenceHomeMetrics.topRatedRailHeight,
      items: items,
      measureCardHeight: _rankedProfessionalCardHeight,
      largeTextMinimumHeight:
          _ReferenceHomeMetrics.topRatedLargeTextRailMinimumHeight,
    );
    if (loading) {
      return _RailSkeleton(height: railHeight, count: 2);
    }
    if (error != null) {
      return _RailError(message: error!, onRetry: onRetry);
    }
    if (items.isEmpty) {
      return _EmptyRail(
        message: context.l10n.noRatedProfessionalsMessage,
        action: context.l10n.viewAll,
        onTap: onViewAll,
      );
    }
    return SizedBox(
      height: railHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: _ReferenceHomeMetrics.pageGutter,
        ),
        reverse: true,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.xs),
        itemBuilder: (context, index) {
          final item = items[index];
          return _RankedProfessionalCard(
            rank: index + 1,
            item: item,
            isSaved: savedIds.contains(item.id),
            onOpen: () => onOpen(item.id),
            onQuote: () => onQuote(item.id),
            onToggleSaved: () => onToggleSaved(item.id),
          );
        },
      ),
    );
  }
}

class _RankedProfessionalCard extends StatelessWidget {
  const _RankedProfessionalCard({
    required this.rank,
    required this.item,
    required this.isSaved,
    required this.onOpen,
    required this.onQuote,
    required this.onToggleSaved,
  });

  final int rank;
  final ReferenceHomeProfessional item;
  final bool isSaved;
  final VoidCallback onOpen;
  final VoidCallback onQuote;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final responsiveText = _usesResponsiveProfessionalCardText(context);
    final rankColor = switch (rank) {
      1 => BatshColors.starGold,
      2 => context.colorScheme.outline,
      _ => context.colorScheme.primary.withValues(alpha: 0.72),
    };
    final rankLabel = switch (rank) {
      1 => context.l10n.homeReferenceRankOne,
      2 => context.l10n.homeReferenceRankTwo,
      _ => context.l10n.homeReferenceRankThree,
    };
    return SizedBox(
      width: 115,
      child: Semantics(
        container: true,
        label: '$rankLabel، ${item.name}، ${_ratingText(item)}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brCard,
            border: Border.all(color: rankColor.withValues(alpha: 0.7)),
            boxShadow: BatshShadows.soft,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.xs,
              vertical: BatshSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    _RankBadge(rank: rank, color: rankColor),
                    const Spacer(),
                    BatshPressable(
                      onTap: onOpen,
                      semanticLabel: item.name,
                      child: _ReferenceAvatar(
                        imageUrl: item.avatarUrl,
                        name: item.name,
                        radius: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BatshSpacing.xs),
                Text(
                  item.name,
                  maxLines: responsiveText ? null : 2,
                  overflow: responsiveText
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  softWrap: responsiveText,
                  textAlign: TextAlign.center,
                  style: _HomeTypography.labelLg.copyWith(
                    fontSize: 17,
                    height: 24 / 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xxxs),
                Text(
                  _specialtyLabel(context, item.specialty),
                  maxLines: responsiveText ? null : 1,
                  overflow: responsiveText
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  softWrap: responsiveText,
                  textAlign: TextAlign.center,
                  style: _HomeTypography.labelSm.copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xxxs),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: BatshColors.starGold,
                        size: 18,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${_ratingText(item)} (${item.reviewCount})',
                          maxLines: responsiveText ? null : 1,
                          overflow: responsiveText
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          softWrap: responsiveText,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          style: _HomeTypography.labelSm.copyWith(
                            fontSize: 13,
                            height: 19 / 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BatshSpacing.xxxs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 1),
                    Flexible(
                      child: Text(
                        item.location,
                        maxLines: responsiveText ? null : 1,
                        overflow: responsiveText
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        softWrap: responsiveText,
                        textAlign: TextAlign.center,
                        style: _HomeTypography.labelSm.copyWith(
                          fontSize: 13,
                          height: 19 / 13,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _PrimarySmallButton(
                  label: context.l10n.homeReferenceViewProfile,
                  onTap: onOpen,
                  minHeight: BatshSpacing.minHitArea,
                  wrapLabel: responsiveText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.color});

  final int rank;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 47, color: color),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '$rank',
                textDirection: TextDirection.ltr,
                style: _HomeTypography.labelLg.copyWith(
                  fontSize: 15,
                  height: 19 / 15,
                  color: rank == 2
                      ? context.colorScheme.onSurface
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkSection extends StatelessWidget {
  const _WorkSection({
    required this.work,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpen,
    required this.onViewAll,
  });

  final ReferenceHomeWork? work;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<ReferenceHomeWork> onOpen;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _RailSkeleton(
        height: _ReferenceHomeMetrics.workHeight,
        count: 1,
      );
    }
    if (error != null) {
      return _RailError(message: error!, onRetry: onRetry);
    }
    final item = work;
    if (item == null) {
      return _EmptyRail(
        message: context.l10n.homeProjectsEmptyTitle,
        action: context.l10n.viewAll,
        onTap: onViewAll,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _ReferenceHomeMetrics.pageGutter,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final sideBySideDetailsWidth =
              constraints.maxWidth - (2 * BatshSpacing.sm) - 2 - 155 - 10;
          final stackMediaAndDetails =
              constraints.maxWidth < 340 ||
              textScale > 1.2 ||
              sideBySideDetailsWidth < 160;
          return BatshPressable(
            onTap: () => onOpen(item),
            semanticLabel: '${item.title}، ${item.category}',
            child: Container(
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerLowest,
                borderRadius: BatshRadius.brLg,
                border: Border.all(color: BatshColors.surfaceContainer),
                boxShadow: BatshShadows.soft,
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(BatshSpacing.sm),
                child: stackMediaAndDetails
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(
                            aspectRatio: 155 / 92,
                            child: _BeforeAfterPreview(item: item),
                          ),
                          const SizedBox(height: 10),
                          _buildDetails(context, item, minimumHeight: null),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 155,
                            height: 92,
                            child: _BeforeAfterPreview(item: item),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDetails(
                              context,
                              item,
                              minimumHeight: 92,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    ReferenceHomeWork item, {
    required double? minimumHeight,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final details = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: minimumHeight == null
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  textAlign: TextAlign.start,
                  style: _HomeTypography.labelLg.copyWith(
                    color: BatshColors.homeInk,
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: BatshColors.homeSoftSurface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 12,
                  color: BatshColors.homeMuted,
                  semanticLabel: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            item.category,
            textAlign: TextAlign.start,
            style: _HomeTypography.labelSm.copyWith(
              color: BatshColors.homeMuted,
              fontSize: 9.5,
              height: 1.3,
            ),
          ),
          if (item.rating != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: BatshColors.homeGold,
                  size: 10,
                ),
                const SizedBox(width: 4),
                Text(
                  item.rating!.toStringAsFixed(1),
                  textDirection: TextDirection.ltr,
                  style: _HomeTypography.labelSm.copyWith(
                    color: BatshColors.homeInk,
                    fontSize: 10,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '(${item.reviewCount})',
                  textDirection: TextDirection.ltr,
                  style: _HomeTypography.labelSm.copyWith(
                    color: BatshColors.homeMuted,
                    fontSize: 8.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
          if (item.isPreview) ...[
            const SizedBox(height: 4),
            Text(
              '"${context.l10n.homeReferenceCaseQuote}"',
              textAlign: TextAlign.start,
              style: _HomeTypography.labelSm.copyWith(
                color: BatshColors.homeInk,
                fontSize: 9,
                height: 1.3,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 6),
          BatshPressable(
            onTap: () => onOpen(item),
            semanticLabel: context.l10n.homeReferenceCaseDetails,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: BatshSpacing.minHitArea,
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BatshColors.homeSoftSurface,
                  borderRadius: BorderRadius.circular(BatshRadius.xs + 2),
                ),
                child: Text(
                  context.l10n.homeReferenceCaseDetails,
                  textAlign: TextAlign.center,
                  style: _HomeTypography.labelSm.copyWith(
                    color: BatshColors.homeAction,
                    fontSize: 10,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (minimumHeight == null) return details;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minimumHeight),
      child: details,
    );
  }
}

class _BeforeAfterPreview extends StatelessWidget {
  const _BeforeAfterPreview({required this.item});

  final ReferenceHomeWork item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BatshRadius.brMd,
      child: _buildMedia(context),
    );
  }

  Widget _buildMedia(BuildContext context) {
    final before = item.beforeUrl.trim();
    final after = item.afterUrl.trim();
    final hasVerifiedPair =
        item.mediaKind == ReferenceHomeWorkMediaKind.verifiedBeforeAfter &&
        before.isNotEmpty &&
        after.isNotEmpty &&
        before != after;
    if (hasVerifiedPair) {
      return _buildVerifiedPair(context, before, after);
    }

    final sourcePhotos = item.mediaKind == ReferenceHomeWorkMediaKind.gallery
        ? item.galleryUrls
        : [before, after];
    final photos = <String>{
      for (final url in sourcePhotos)
        if (url.trim().isNotEmpty) url.trim(),
    }.toList(growable: false);
    if (photos.isEmpty) return const _UnavailableWorkMedia();
    if (photos.length == 1) {
      return _WorkMediaPhoto(
        source: photos.single,
        semanticLabel: context.l10n.projectPhotoLabel,
      );
    }

    final galleryLabel = context.l10n.portfolioGalleryTitle;
    return Row(
      children: [
        Expanded(
          child: _WorkMediaPhoto(
            source: photos[0],
            semanticLabel:
                '$galleryLabel, ${context.l10n.photoIndexOf(1, photos.length)}',
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _WorkMediaPhoto(
                source: photos[1],
                semanticLabel:
                    '$galleryLabel, ${context.l10n.photoIndexOf(2, photos.length)}',
              ),
              if (photos.length > 2)
                PositionedDirectional(
                  end: BatshSpacing.xs,
                  bottom: BatshSpacing.xs,
                  child: ExcludeSemantics(
                    child: _PhotoTag(
                      label: context.l10n.morePhotosCount(photos.length - 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedPair(BuildContext context, String before, String after) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _WorkMediaPhoto(
                source: before,
                semanticLabel: context.l10n.communityBeforeLabel,
              ),
              PositionedDirectional(
                start: BatshSpacing.xs,
                bottom: BatshSpacing.xs,
                child: ExcludeSemantics(
                  child: _PhotoTag(label: context.l10n.communityBeforeLabel),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _WorkMediaPhoto(
                source: after,
                semanticLabel: context.l10n.communityAfterLabel,
              ),
              PositionedDirectional(
                end: BatshSpacing.xs,
                top: BatshSpacing.xs,
                child: ExcludeSemantics(
                  child: _PhotoTag(label: context.l10n.communityAfterLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkMediaPhoto extends StatelessWidget {
  const _WorkMediaPhoto({required this.source, required this.semanticLabel});

  final String source;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final imageSource = source.trim();
    if (imageSource.startsWith('assets/')) {
      return Image.asset(
        imageSource,
        excludeFromSemantics: true,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return Semantics(image: true, label: semanticLabel, child: child);
          }
          return ExcludeSemantics(child: _workPhotoFallback(context));
        },
        errorBuilder: (context, _, _) => _unavailablePhoto(context),
      );
    }
    if (!imageSource.startsWith('http')) {
      return _unavailablePhoto(context);
    }
    return Image.network(
      imageSource,
      excludeFromSemantics: true,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return Semantics(image: true, label: semanticLabel, child: child);
        }
        return ExcludeSemantics(child: _workPhotoFallback(context));
      },
      errorBuilder: (context, _, _) => _unavailablePhoto(context),
    );
  }
}

class _UnavailableWorkMedia extends StatelessWidget {
  const _UnavailableWorkMedia();

  @override
  Widget build(BuildContext context) => _unavailablePhoto(context);
}

Widget _unavailablePhoto(BuildContext context) {
  return Semantics(
    image: true,
    label: context.l10n.imageUnavailable,
    child: _workPhotoFallback(context),
  );
}

Widget _workPhotoFallback(BuildContext context) {
  return ColoredBox(
    color: context.colorScheme.surfaceContainerHigh,
    child: Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
        size: 28,
      ),
    ),
  );
}

class _CommunitySection extends StatelessWidget {
  const _CommunitySection({
    required this.posts,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpen,
    required this.onCreatePost,
  });

  final List<ReferenceHomeCommunityPost> posts;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<ReferenceHomeCommunityPost> onOpen;
  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _RailSkeleton(
        height: _ReferenceHomeMetrics.communityCardHeight,
        count: 2,
      );
    }
    if (error != null) {
      return _RailError(message: error!, onRetry: onRetry);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _ReferenceHomeMetrics.pageGutter,
      ),
      child: Column(
        children: [
          if (posts.isEmpty)
            _EmptyRail(
              message: context.l10n.communityNoPostsTitle,
              action: context.l10n.communityCreatePost,
              onTap: onCreatePost,
            )
          else
            for (final post in posts.take(2)) ...[
              _CommunityPreviewCard(post: post, onOpen: () => onOpen(post)),
              if (post != posts.take(2).last)
                const SizedBox(height: BatshSpacing.xs),
            ],
          const SizedBox(height: BatshSpacing.sm),
          _CommunityInvite(onTap: onCreatePost),
        ],
      ),
    );
  }
}

class _CommunityPreviewCard extends StatelessWidget {
  const _CommunityPreviewCard({required this.post, required this.onOpen});

  final ReferenceHomeCommunityPost post;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onOpen,
      semanticLabel: '${post.authorName}، ${post.timeLabel}، ${post.caption}',
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brLg,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: BatshShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(BatshSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        _ReferenceAvatar(
                          imageUrl: post.authorAvatarUrl,
                          name: post.authorName,
                          radius: 16,
                        ),
                        const SizedBox(width: BatshSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: BatshSpacing.xxs,
                                runSpacing: BatshSpacing.xxxs,
                                children: [
                                  Text(
                                    post.authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _HomeTypography.labelSm.copyWith(
                                      fontSize: 11,
                                      height: 14 / 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  _DisclosureBadge(label: post.badge),
                                ],
                              ),
                              Text(
                                post.timeLabel,
                                style: _HomeTypography.labelSm.copyWith(
                                  fontSize: 8.5,
                                  height: 11 / 8.5,
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.sm),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: ClipRRect(
                      borderRadius: BatshRadius.brSm,
                      child: _ReferenceMedia(
                        url: post.imageUrl,
                        assetPath: post.imageUrl.startsWith('assets/')
                            ? post.imageUrl
                            : null,
                        fit: BoxFit.cover,
                        semanticLabel: post.caption,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BatshSpacing.xs),
              Text(
                post.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: _HomeTypography.labelSm.copyWith(
                  fontSize: 10,
                  height: 14 / 10,
                ),
              ),
              const SizedBox(height: BatshSpacing.xs),
              Divider(
                height: 1,
                thickness: 1,
                color: context.colorScheme.surfaceContainerLow,
              ),
              const SizedBox(height: BatshSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                textDirection: TextDirection.rtl,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: BatshColors.starGold,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${post.likeCount}',
                    textDirection: TextDirection.ltr,
                    style: _HomeTypography.labelSm.copyWith(
                      fontSize: 9.5,
                      height: 12 / 9.5,
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.md),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 14,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _commentCountLabel(context, post.commentCount),
                    style: _HomeTypography.labelSm.copyWith(
                      fontSize: 9.5,
                      height: 12 / 9.5,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _commentCountLabel(BuildContext context, int count) {
  final label = count == 1
      ? context.l10n.commentLabel
      : context.l10n.commentsTitle;
  return '$count $label';
}

class _CommunityInvite extends StatelessWidget {
  const _CommunityInvite({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackActions =
            constraints.maxWidth < 344 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2;
        final copy = Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: BatshColors.homeSoftSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: BatshColors.homeAction,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.l10n.homeReferenceCommunityInviteTitle,
                    textAlign: TextAlign.right,
                    style: _HomeTypography.labelLg.copyWith(
                      fontSize: 11.5,
                      height: 15 / 11.5,
                      color: BatshColors.homeInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    context.l10n.homeReferenceCommunityInviteBody,
                    textAlign: TextAlign.right,
                    style: _HomeTypography.labelSm.copyWith(
                      fontSize: 9.5,
                      height: 1.5,
                      color: BatshColors.homeMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final action = _OutlineSmallButton(
          label: context.l10n.homeReferenceWritePost,
          onTap: onTap,
          minHeight: BatshSpacing.minHitArea,
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _homeCommunityInviteSurface,
            borderRadius: BatshRadius.brLg,
            border: Border.all(color: BatshColors.homeBorder),
          ),
          child: stackActions
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    copy,
                    const SizedBox(height: BatshSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: action,
                    ),
                  ],
                )
              : Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: BatshSpacing.xs),
                    action,
                  ],
                ),
        );
      },
    );
  }
}

class _ClosingCta extends StatelessWidget {
  const _ClosingCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _ReferenceHomeMetrics.pageGutter,
      ),
      child: ClipRRect(
        borderRadius: BatshRadius.brLg,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _homeClosingGradientStart,
                      _homeClosingGradientMiddle,
                      _homeClosingGradientEnd,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.homeReferenceClosingTitle,
                          textAlign: TextAlign.right,
                          style: _HomeTypography.titleLg.copyWith(
                            fontSize: 14,
                            height: 18 / 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.homeReferenceClosingBody,
                          textAlign: TextAlign.right,
                          style: _HomeTypography.labelSm.copyWith(
                            fontSize: 9.5,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: _LightButton(
                            label: context.l10n.homeReferenceClosingAction,
                            onTap: onTap,
                            minHeight: BatshSpacing.minHitArea,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.xs),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          borderRadius: BatshRadius.brMd,
                          boxShadow: BatshShadows.soft,
                        ),
                        child: ClipRRect(
                          borderRadius: BatshRadius.brSm,
                          child: _ReferenceMedia(
                            assetPath:
                                'assets/images/stitch_home_closing_badge.jpg',
                            fit: BoxFit.cover,
                            semanticLabel:
                                context.l10n.homeReferenceClosingTitle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.homeReferenceClosingQuote,
                        textAlign: TextAlign.center,
                        style: _HomeTypography.labelSm.copyWith(
                          fontSize: 8,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _ReferenceMedia extends StatelessWidget {
  const _ReferenceMedia({
    this.url,
    this.assetPath,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String? url;
  final String? assetPath;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: context.colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
          size: 28,
        ),
      ),
    );
    if (assetPath != null) {
      return Semantics(
        image: true,
        label: semanticLabel,
        child: Image.asset(
          assetPath!,
          fit: fit,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }
    final value = url?.trim() ?? '';
    if (value.isEmpty || !value.startsWith('http')) return fallback;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Image.network(
        value,
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return fallback;
        },
      ),
    );
  }
}

class _PhotoTag extends StatelessWidget {
  const _PhotoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BatshRadius.brFull,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xxs,
        ),
        child: Text(
          label,
          style: _HomeTypography.labelSm.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ImageOverlayButton extends StatelessWidget {
  const _ImageOverlayButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BatshRadius.brFull,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            const Icon(Icons.image_outlined, color: Colors.white, size: 16),
            const SizedBox(width: BatshSpacing.xxs),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.clip,
                style: _HomeTypography.labelSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: BatshSpacing.minHitArea,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.transparent,
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(
                    BatshSpacing.minHitArea,
                    BatshSpacing.minHitArea,
                  ),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(color: Colors.transparent),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: badge,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrimarySmallButton extends StatelessWidget {
  const _PrimarySmallButton({
    required this.label,
    required this.onTap,
    this.minHeight = BatshSpacing.minHitArea,
    this.wrapLabel = false,
  });

  final String label;
  final VoidCallback onTap;
  final double minHeight;
  final bool wrapLabel;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
        decoration: BoxDecoration(
          color: context.colorScheme.primary,
          borderRadius: BatshRadius.brMd,
        ),
        child: wrapLabel
            ? Text(
                label,
                textAlign: TextAlign.center,
                softWrap: true,
                style: _HomeTypography.labelMd.copyWith(
                  color: context.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: _HomeTypography.labelMd.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}

class _OutlineSmallButton extends StatelessWidget {
  const _OutlineSmallButton({
    required this.label,
    required this.onTap,
    this.minHeight = BatshSpacing.minHitArea,
  });

  final String label;
  final VoidCallback onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brMd,
          border: Border.all(color: context.colorScheme.primary),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: _HomeTypography.labelMd.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LightButton extends StatelessWidget {
  const _LightButton({
    required this.label,
    required this.onTap,
    this.minHeight = BatshSpacing.minHitArea,
  });

  final String label;
  final VoidCallback onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brMd,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: _HomeTypography.labelLg.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _OffersButton extends StatelessWidget {
  const _OffersButton({
    required this.count,
    required this.avatarPaths,
    required this.onTap,
    this.fitLabelToWidth = false,
    this.minHeight = BatshSpacing.minHitArea,
  });

  final int count;
  final List<String> avatarPaths;
  final VoidCallback onTap;
  final bool fitLabelToWidth;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.homeReferenceNewOffers(count);
    final labelWidget = Text(
      label,
      maxLines: fitLabelToWidth ? null : 1,
      softWrap: fitLabelToWidth,
      style: _HomeTypography.labelSm.copyWith(
        fontSize: 10.5,
        height: 14 / 10.5,
        color: context.colorScheme.error,
        fontWeight: FontWeight.w700,
      ),
    );
    final offersRow = Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: Directionality.of(context),
      children: [
        Icon(
          Icons.description_outlined,
          size: 14,
          color: context.colorScheme.error,
          semanticLabel: null,
        ),
        const SizedBox(width: BatshSpacing.xxs),
        if (fitLabelToWidth)
          Flexible(fit: FlexFit.loose, child: labelWidget)
        else
          labelWidget,
        if (avatarPaths.isNotEmpty) ...[
          const SizedBox(width: BatshSpacing.xxs),
          _ProjectOfferAvatars(paths: avatarPaths),
        ],
        const SizedBox(width: BatshSpacing.xxs),
        Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.chevron_left
              : Icons.chevron_right,
          size: BatshIconSize.xs,
          color: context.colorScheme.error,
          semanticLabel: null,
        ),
      ],
    );
    return BatshPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        alignment: fitLabelToWidth ? null : Alignment.center,
        child: fitLabelToWidth
            ? Align(
                alignment: Alignment.center,
                widthFactor: 1,
                heightFactor: 1,
                child: offersRow,
              )
            : offersRow,
      ),
    );
  }
}

class _ProjectOfferAvatars extends StatelessWidget {
  const _ProjectOfferAvatars({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: paths.length > 1 ? 26 : 16,
      height: 16,
      child: Stack(
        children: [
          if (paths.length > 1)
            PositionedDirectional(
              start: 10,
              child: _ProjectOfferAvatar(path: paths[1]),
            ),
          if (paths.isNotEmpty)
            PositionedDirectional(
              start: 0,
              child: _ProjectOfferAvatar(path: paths[0]),
            ),
        ],
      ),
    );
  }
}

class _ProjectOfferAvatar extends StatelessWidget {
  const _ProjectOfferAvatar({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white),
      ),
      child: Image.asset(path, fit: BoxFit.cover, excludeFromSemantics: true),
    );
  }
}

class _ProjectFollowButton extends StatelessWidget {
  const _ProjectFollowButton({
    required this.label,
    required this.onTap,
    required this.wrapLabelForCompactText,
    this.fitLabelToWidth = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool wrapLabelForCompactText;
  final bool fitLabelToWidth;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final wrapLabel =
        wrapLabelForCompactText &&
        MediaQuery.textScalerOf(context).scale(1) > 1.0;
    final constrainLabel = wrapLabel || fitLabelToWidth;
    final labelWidget = Text(
      label,
      maxLines: constrainLabel ? null : 1,
      softWrap: constrainLabel,
      style: _HomeTypography.labelSm.copyWith(
        fontSize: 11,
        height: 14 / 11,
        color: context.colorScheme.onPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BatshRadius.brSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: wrapLabel ? MainAxisSize.max : MainAxisSize.min,
          textDirection: direction,
          children: [
            if (constrainLabel)
              Flexible(fit: FlexFit.loose, child: labelWidget)
            else
              labelWidget,
            const SizedBox(width: BatshSpacing.xxs),
            Icon(
              direction == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              size: BatshIconSize.xs,
              color: context.colorScheme.onPrimary,
              semanticLabel: null,
            ),
          ],
        ),
      ),
    );
    return BatshPressable(
      onTap: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: BatshSpacing.minHitArea),
        child: fitLabelToWidth
            ? Align(
                alignment: Alignment.center,
                widthFactor: 1,
                heightFactor: 1,
                child: chip,
              )
            : Center(child: chip),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.colorScheme.primary, size: 25),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
    this.compact = false,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool compact;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: BatshSpacing.minHitArea,
        height: BatshSpacing.minHitArea,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: compact
              ? Colors.transparent
              : context.colorScheme.surfaceContainerLowest.withValues(
                  alpha: 0.93,
                ),
          shape: outlined ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: outlined ? BatshRadius.brMd : null,
          border: outlined
              ? Border.all(
                  color: context.colorScheme.primary.withValues(alpha: 0.32),
                )
              : null,
        ),
        child: Icon(
          icon,
          size: compact ? 18 : 22,
          color: compact
              ? (active ? context.colorScheme.primary : Colors.white)
              : (active
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.secondary,
        borderRadius: BatshRadius.brFull,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _HomeTypography.labelMd.copyWith(
            fontSize: 12,
            height: 17 / 12,
            color: context.colorScheme.onSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DisclosureBadge extends StatelessWidget {
  const _DisclosureBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
        borderRadius: BatshRadius.brFull,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _HomeTypography.labelMd.copyWith(
            fontSize: 12,
            height: 17 / 12,
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton({required this.height, required this.count});

  final double height;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: _ReferenceHomeMetrics.pageGutter,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.sm),
        itemBuilder: (_, _) => BatshSkeletonRegion(
          child: BatshShimmerBox(
            width: height > 200 ? 152 : 260,
            height: height,
            borderRadius: BatshRadius.brCard,
          ),
        ),
      ),
    );
  }
}

class _RailError extends StatelessWidget {
  const _RailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _ReferenceHomeMetrics.pageGutter,
      ),
      child: BatshError(message: message, onRetry: onRetry),
    );
  }
}

class _EmptyRail extends StatelessWidget {
  const _EmptyRail({required this.message, required this.action, this.onTap});

  final String message;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackActions =
            constraints.maxWidth < 344 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2;
        final messageText = Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: _HomeTypography.bodySm.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        );
        final actionButton = onTap == null
            ? null
            : _OutlineSmallButton(label: action, onTap: onTap!);

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _ReferenceHomeMetrics.pageGutter,
          ),
          child: Container(
            padding: const EdgeInsets.all(BatshSpacing.md),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerLowest,
              borderRadius: BatshRadius.brLg,
              border: Border.all(
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.55,
                ),
              ),
            ),
            child: stackActions
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      messageText,
                      if (actionButton != null) ...[
                        const SizedBox(height: BatshSpacing.xs),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: actionButton,
                        ),
                      ],
                    ],
                  )
                : Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(child: messageText),
                      if (actionButton != null) ...[
                        const SizedBox(width: BatshSpacing.sm),
                        actionButton,
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

String _ratingText(ReferenceHomeProfessional item) {
  if (item.reviewCount <= 0) return '—';
  return item.rating.toStringAsFixed(1);
}

String _specialtyLabel(BuildContext context, String value) {
  final known = {
    'paint',
    'flooring',
    'kitchen',
    'bathroom',
    'electrical',
    'plumbing',
    'carpentry',
    'design',
    'full_reno',
    'plastering',
    'gypsum_board',
    'marble_granite',
    'aluminum_upvc',
    'hvac',
  };
  return known.contains(value)
      ? localizedSpecialtyLabel(context, value)
      : value;
}
