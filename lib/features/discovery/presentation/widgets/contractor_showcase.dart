import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../../core/widgets/tier_badge.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../portfolio/domain/portfolio_project.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../../reviews/presentation/reviews_sheet.dart';
import '../../../saved/presentation/providers/saved_providers.dart';
import '../../domain/contractor_listing.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/widgets/batsh_badge.dart';

/// How the showcase is being viewed.
/// - [public]: a homeowner browsing the contractor (save, share, contact CTAs).
/// - [owner]: the contractor viewing their own profile (edit + sign out).
enum ShowcaseMode { public, owner }

/// The full contractor profile body, shared by the public discover screen and
/// the contractor's own profile tab. Renders a [CustomScrollView]; the host
/// supplies the [Scaffold].
///
/// Section order is deliberate: identity, then **proof of work**, then
/// credentials, then the long tail. Portfolio used to sit last, below the
/// service-area chips, so a homeowner had to scroll past six blocks of metadata
/// to reach the one thing that decides a hire.
class ContractorShowcase extends ConsumerWidget {
  const ContractorShowcase({
    super.key,
    required this.listing,
    this.mode = ShowcaseMode.public,
    this.rating,
    this.reviewCount,
    this.onEdit,
    this.onSignOut,
    this.onGoPro,
    this.showInlineContact = true,
  });

  final ContractorListing listing;
  final ShowcaseMode mode;

  /// When false, the inline contact block is omitted — the host renders a
  /// pinned [ContractorContactBar] instead, so the primary action stays
  /// reachable no matter how far the user scrolls. The body then reserves
  /// trailing scroll space so nothing hides behind it.
  final bool showInlineContact;

  /// Override for the average rating. Null (here or on the listing) means
  /// "not reviewed yet" and renders as a neutral "جديد" badge, never as stars.
  final double? rating;
  final int? reviewCount;

  /// Owner-mode callbacks.
  final VoidCallback? onEdit;
  final VoidCallback? onSignOut;
  final VoidCallback? onGoPro;

  bool get _isOwner => mode == ShowcaseMode.owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? const {};
    final isSaved = savedIds.contains(listing.id);
    // A failed portfolio fetch used to be indistinguishable from "no projects":
    // `.value ?? []` collapses error and empty into the same blank section, so
    // a contractor with twelve projects looked like one with none. Keep the
    // async state so the section can say which it is.
    final portfolioAsync = ref.watch(
      portfolioForContractorProvider(listing.id),
    );
    final portfolio = portfolioAsync.value ?? const <PortfolioProject>[];
    final effectiveRating = rating ?? listing.rating;
    final effectiveCount = reviewCount ?? listing.reviewCount;

    final hasPortfolio = portfolio.isNotEmpty || portfolioAsync.hasError;
    final hasBio = listing.bio != null && listing.bio!.isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 268,
          pinned: true,
          automaticallyImplyLeading: !_isOwner,
          backgroundColor: BatshColors.background,
          foregroundColor: BatshColors.onSurface,
          elevation: 0,
          leading: _isOwner ? null : const _BackButton(),
          actions: _isOwner
              ? [
                  IconButton(
                    tooltip: S.editLabel,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                ]
              : [
                  IconButton(
                    tooltip: isSaved ? S.unsaveTooltip : S.saveTooltip,
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved
                          ? BatshColors.primary
                          : BatshColors.onSurface,
                    ),
                    onPressed: () => runSignedIn(
                      context,
                      ref,
                      reason: S.signInToSave,
                      action: () => ref
                          .read(savedControllerProvider.notifier)
                          .toggle(listing.id),
                    ),
                  ),
                  IconButton(
                    tooltip: S.share,
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareContractor(listing),
                  ),
                ],
          // The avatar is anchored to the bottom of the hero rather than pulled
          // up into the body with a negative offset. The previous version used
          // `Transform.translate(-56)` plus a compensating trailing spacer: two
          // magic numbers that had to agree with `expandedHeight` and the
          // toolbar height, and silently misaligned at large text scales.
          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              FlexibleSpaceBar(
                background: _CoverHero(coverUrl: listing.coverPhotoUrl),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: BatshSpacing.md),
                  child: _AvatarRing(logoUrl: listing.logoUrl),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: BatshSpacing.md),
              _NameHeadline(contractor: listing),
              const SizedBox(height: BatshSpacing.md),
              _RatingPill(
                rating: effectiveRating,
                reviewCount: effectiveCount,
                onTap: () => showReviewsSheet(context, listing.id),
              ),
              const SizedBox(height: BatshSpacing.lg),
              if (_isOwner) ...[
                _OwnerActions(onEdit: onEdit),
                if (onGoPro != null) ...[
                  const SizedBox(height: BatshSpacing.md),
                  _GoProBanner(onTap: onGoPro!),
                ],
              ] else if (showInlineContact)
                ContractorContactBar(listing: listing),

              // Proof of work, immediately after identity.
              if (hasPortfolio) ...[
                const SizedBox(height: BatshSpacing.xl),
                _PortfolioSection(
                  contractor: listing,
                  projects: portfolio,
                  isOwner: _isOwner,
                  failed: portfolioAsync.hasError,
                  onRetry: () => ref.invalidate(
                    portfolioForContractorProvider(listing.id),
                  ),
                ),
              ],

              // Credentials. Tiles with nothing to report are dropped rather
              // than rendered as "0" / "—": a big elevated card announcing
              // "0 مشروع منجز" is the same cold-start mistake as showing empty
              // stars instead of the neutral "new" badge.
              _StatsRow(contractor: listing),

              if (hasBio) ...[
                const SizedBox(height: BatshSpacing.xl),
                _BioSection(bio: listing.bio!),
              ],
              if (listing.specialties.isNotEmpty) ...[
                const SizedBox(height: BatshSpacing.xl),
                _ServicesSection(specialtyKeys: listing.specialties),
              ],
              if (listing.serviceAreas.isNotEmpty) ...[
                const SizedBox(height: BatshSpacing.lg),
                _ChipsSection(title: S.worksIn, labels: listing.serviceAreas),
              ],
              if (_isOwner && onSignOut != null) ...[
                const SizedBox(height: BatshSpacing.xl),
                _SignOutBlock(onSignOut: onSignOut!),
              ],
              // Clearance for the host's pinned contact bar when there is one.
              SizedBox(height: showInlineContact ? BatshSpacing.xl : 148),
            ],
          ).animate().fadeIn(duration: 220.ms),
        ),
      ],
    );
  }
}

/// Shares the contractor through the OS share sheet — the same path the feed's
/// post card uses. This previously wrote to the clipboard and showed a
/// "copied" snackbar, which meant the app had two different share behaviours
/// depending on which screen you were on.
///
/// The blurb still carries no link: there is no public profile URL yet. Add one
/// here the moment App Links / a web profile exist, since a shareable link is
/// the whole point of the button.
void _shareContractor(ContractorListing listing) {
  final name = listing.businessName.isNotEmpty
      ? listing.businessName
      : listing.fullName;
  final blurb = StringBuffer(S.seeOnShattab.replaceFirst('%s', name));
  if (listing.headline != null && listing.headline!.isNotEmpty) {
    blurb.write(' - ${listing.headline}');
  }
  blurb.write('\n${S.forContact}: ${listing.phone}');
  Share.share(blurb.toString(), subject: name);
}

/// Grows a fixed-height horizontal strip with the user's text scale.
///
/// `app.dart` clamps scaling at 1.5x, and at 1.5x a two-line Arabic label in an
/// 84x96 tile clips. Only the label lines grow, so the base height is padded by
/// the per-line delta instead of being multiplied wholesale.
double _scaledStripHeight(BuildContext context, double base, int labelLines) {
  const labelFontSize = 13.0; // BatshTypography.labelSm
  final delta =
      (MediaQuery.textScalerOf(context).scale(labelFontSize) - labelFontSize) *
      labelLines;
  return base + delta.clamp(0.0, 64.0);
}

/// Primary contact block: WhatsApp first.
///
/// Previously three near-equal filled CTAs competed for the same glance, and
/// the block was defined twice — once here and once as a private sticky bar in
/// the profile screen. One definition now, mounted inline (owner preview) or
/// pinned (`sticky: true`).
///
/// WhatsApp leads because in Egypt it *is* the conversion; "send project
/// details" stays reachable as the secondary that feeds the quote funnel.
class ContractorContactBar extends StatelessWidget {
  const ContractorContactBar({
    super.key,
    required this.listing,
    this.sticky = false,
  });

  final ContractorListing listing;

  /// Adds the surface, top border, shadow and safe-area inset needed when the
  /// bar is pinned to the bottom of a [Scaffold].
  final bool sticky;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WhatsAppButton(phone: listing.phone, message: S.profileGreeting),
        const SizedBox(height: BatshSpacing.sm),
        Row(
          children: [
            Expanded(
              child: BatshButton(
                label: S.sendProjectDetails,
                style: BatshButtonStyle.secondary,
                onPressed: () =>
                    context.push(Routes.homeownerSendBriefPath(listing.id)),
              ),
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(child: CallButton(phone: listing.phone)),
          ],
        ),
      ],
    );

    if (!sticky) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.marginMobile,
        ),
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        border: const Border(
          top: BorderSide(color: BatshColors.outlineVariant),
        ),
        boxShadow: BatshShadows.raised,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.marginMobile,
            BatshSpacing.md,
            BatshSpacing.marginMobile,
            BatshSpacing.md,
          ),
          child: content,
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        // Was a raw `Colors.white` scrim, which also stayed white in dark mode.
        color: BatshColors.surfaceContainerLowest.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: IconButton(
          // `Icons.arrow_back` is declared with matchTextDirection, so it
          // mirrors to point right in Arabic and left in English. The previous
          // hardcoded `arrow_forward` was correct only in RTL.
          icon: const Icon(Icons.arrow_back, color: BatshColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

class _CoverHero extends StatelessWidget {
  const _CoverHero({this.coverUrl});
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverUrl != null)
          CachedNetworkImage(
            imageUrl: sizedImageUrl(coverUrl!, width: 900),
            fit: BoxFit.cover,
            memCacheWidth: 900,
            placeholder: (_, _) =>
                const ColoredBox(color: BatshColors.surfaceContainer),
            errorWidget: (_, _, _) => const _CoverFallback(),
          )
        else
          const _CoverFallback(),
        // Neutral photographic scrim. The previous ramp reached the page
        // background at 92% with 0.86 alpha, which erased the bottom third of
        // the photo — a cover you cannot see reads as a rendering accident.
        // This keeps the image legible under the avatar and stops short of
        // painting over it.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x00000000),
                const Color(0x14000000),
                BatshColors.background.withValues(alpha: 0.55),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();
  @override
  Widget build(BuildContext context) {
    return const BatshGradientFallback();
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({this.logoUrl});
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BatshColors.background,
        shape: BoxShape.circle,
        boxShadow: BatshShadows.elevated,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: BatshColors.surfaceContainer,
          border: Border.all(
            color: BatshColors.primary.withValues(alpha: 0.55),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: logoUrl != null
            ? CachedNetworkImage(
                imageUrl: sizedImageUrl(logoUrl!, width: 200),
                fit: BoxFit.cover,
                memCacheWidth: 200,
                placeholder: (_, _) =>
                    const ColoredBox(color: BatshColors.surfaceContainer),
              )
            : const Icon(
                Icons.engineering_outlined,
                size: BatshIconSize.xxl,
                color: BatshColors.primary,
              ),
      ),
    );
  }
}

class _NameHeadline extends StatelessWidget {
  const _NameHeadline({required this.contractor});
  final ContractorListing contractor;

  @override
  Widget build(BuildContext context) {
    final name = contractor.businessName.isNotEmpty
        ? contractor.businessName
        : contractor.fullName;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.marginMobile,
      ),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: BatshTypography.headlineLgMobile,
          ),
          const SizedBox(height: BatshSpacing.sm),
          // Kind first, then verification, then the earned level: what they
          // are, whether we checked, and what the work record says. Wrap so
          // the set reflows instead of overflowing at large text scales.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: BatshSpacing.xs,
            runSpacing: BatshSpacing.xs,
            children: [
              BatshBadge(
                label: contractor.providerKind.label,
                icon: contractor.providerKind.icon,
                emphasis: BatshBadgeEmphasis.outline,
              ),
              if (contractor.verified)
                BatshBadge(
                  label: S.verified,
                  icon: Icons.verified_rounded,
                  tone: BatshBadgeTone.brand,
                ),
              // Tappable here because this is where a homeowner is actually
              // deciding, and an unexplained rank is just another glyph.
              TierBadge(tier: contractor.tier, explainOnTap: true),
            ],
          ),
          if (contractor.headline != null &&
              contractor.headline!.isNotEmpty) ...[
            const SizedBox(height: BatshSpacing.xs),
            Text(
              contractor.headline!,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd.copyWith(
                color: BatshColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What the professional calls themselves — مقاول, مهندس, مكتب هندسي, and so
/// on.
///
/// Styled as a neutral outline rather than a filled accent so it reads as a
/// statement of fact, not an award. Verification is the award, and the two must
/// not look alike.

/// Verification, labelled.
///
/// This was a bare 22px checkmark beside the name. Verification is the whole
/// point of the request flow behind migration 0015, and an unlabelled glyph is
/// the one form most users will not decode. Icon plus word, like `RoleBadge`,
/// so it survives a greyscale read.

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating, this.reviewCount, this.onTap});

  /// Null when unreviewed — the pill then shows the neutral "new" state.
  final double? rating;
  final int? reviewCount;

  /// Opens the review list.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Cold-start: a brand-new contractor has no reviews. Showing empty stars +
    // "0.0" reads as *bad*; a neutral "جديد" badge reads as *new*. Same data,
    // opposite trust signal (Airbnb/Upwork pattern). Icon + text, not colour
    // alone, so it survives accessibility/colour-blind checks.
    // Local copy: a nullable field cannot be type-promoted by the null check.
    final avg = rating;
    if (avg == null || reviewCount == null || reviewCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.gutter,
          vertical: BatshSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: BatshColors.secondaryContainer,
          borderRadius: BatshRadius.brFull,
          border: Border.all(color: BatshColors.secondary, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: BatshIconSize.sm,
              color: BatshColors.onSecondaryContainer,
            ),
            const SizedBox(width: BatshSpacing.xs),
            Text(
              S.newProfessional,
              style: BatshTypography.labelMd.copyWith(
                color: BatshColors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // One star, the number, then the tappable count. The old pill encoded the
    // same value three times — five 14px stars *and* "4.5" *and* "(12 تقييم)" —
    // and the star row also rendered 4.9 as a half star, because a half was
    // drawn whenever the fractional part cleared 0.4.
    return Material(
      color: BatshColors.tertiaryFixed,
      borderRadius: BatshRadius.brFull,
      child: InkWell(
        borderRadius: BatshRadius.brFull,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.gutter,
            vertical: BatshSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BatshRadius.brFull,
            border: Border.all(color: BatshColors.tertiary, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: BatshIconSize.md,
                color: BatshColors.tertiary,
              ),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                avg.toStringAsFixed(1),
                style: BatshTypography.labelMd.copyWith(
                  color: BatshColors.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                '· $reviewCount ${S.reviewsCount}',
                style: BatshTypography.labelSm.copyWith(
                  color: BatshColors.onTertiaryContainer,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: BatshIconSize.xs,
                  color: BatshColors.onTertiaryContainer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.contractor});
  final ContractorListing contractor;

  @override
  Widget build(BuildContext context) {
    // Response-rate tile removed earlier — the value was a hardcoded default
    // (100%) for everyone, never measured. The two survivors are only shown
    // when they carry a number: `projects_completed` stays 0 until the
    // completion trigger in migration 0019 writes to it, and years of
    // experience is optional at onboarding.
    final tiles = <Widget>[
      if (contractor.projectsCompleted > 0)
        _StatCard(
          value: '${contractor.projectsCompleted}',
          label: S.projectsCompleted,
          icon: Icons.home_work_outlined,
        ),
      if (contractor.yearsExperience != null)
        _StatCard(
          value: '${contractor.yearsExperience}',
          label: S.experienceYears,
          icon: Icons.workspace_premium_outlined,
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: BatshSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.marginMobile,
        ),
        child: Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: BatshSpacing.sm),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: BatshSpacing.lg,
        horizontal: BatshSpacing.md,
      ),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brXl,
        boxShadow: BatshShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: BatshColors.primary, size: BatshIconSize.md),
          const SizedBox(height: BatshSpacing.md),
          // Plain text, no count-up tween. The tween began at 0 on every build,
          // and this widget's ancestor watches the saved-contractors provider —
          // so tapping the bookmark made the stats visibly re-count from zero.
          // Animating 0→3 was never worth that.
          Text(
            value,
            style: BatshTypography.displayMd.copyWith(
              color: BatshColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            label,
            maxLines: 2,
            style: BatshTypography.labelMd.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoProBanner extends StatelessWidget {
  const _GoProBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.marginMobile,
      ),
      child: Material(
        borderRadius: BatshRadius.brCard,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [BatshColors.primary, BatshColors.onPrimaryFixedVariant],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(BatshSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          BatshColors.tertiaryContainer,
                          BatshColors.tertiary,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: BatshIconSize.md,
                      color: BatshColors.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.upgradeToProShort,
                          style: BatshTypography.titleMd.copyWith(
                            color: BatshColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          S.proValueLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.bodySm.copyWith(
                            color: BatshColors.onPrimary.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mirrors with text direction, unlike the previous hardcoded
                  // `chevron_left_rounded`.
                  Icon(
                    Icons.arrow_forward_ios,
                    size: BatshIconSize.sm,
                    color: BatshColors.onPrimary.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({this.onEdit});
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.marginMobile,
      ),
      child: Column(
        children: [
          BatshButton(
            label: S.editProfileButton,
            style: BatshButtonStyle.secondary,
            onPressed: onEdit,
          ),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: BatshIconSize.sm,
                color: BatshColors.onSurfaceVariant,
              ),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                S.clientsPreview,
                style: BatshTypography.labelSm.copyWith(
                  color: BatshColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignOutBlock extends StatelessWidget {
  const _SignOutBlock({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.marginMobile,
      ),
      child: BatshButton(
        label: S.signOutButton,
        style: BatshButtonStyle.ghost,
        onPressed: onSignOut,
      ),
    );
  }
}

class _BioSection extends StatelessWidget {
  const _BioSection({required this.bio});
  final String bio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.marginMobile,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(BatshSpacing.gutter),
        decoration: BoxDecoration(
          color: BatshColors.surfaceContainerLow,
          borderRadius: BatshRadius.brCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.aboutProfessional,
              style: BatshTypography.labelMd.copyWith(
                color: BatshColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(bio, style: BatshTypography.bodyLg),
          ],
        ),
      ),
    );
  }
}

/// Services as a scrollable row of icon tiles. Each specialty gets its own
/// glyph, so the row is scannable before it is read — the previous flat text
/// chips made "دهانات" and "سباكة" identical at a glance. Icon plus label, never
/// icon alone: the glyph is a scanning aid, not the meaning.
class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.specialtyKeys});

  final List<String> specialtyKeys;

  /// Specialty key → glyph. Same icon vocabulary as the opportunities filter
  /// sheet, so a contractor sees one consistent language for "كهرباء" whether
  /// they are filtering jobs or reading a profile.
  static const _icons = <String, IconData>{
    'paint': Icons.format_paint_outlined,
    'flooring': Icons.grid_on_outlined,
    'kitchen': Icons.countertops_outlined,
    'bathroom': Icons.bathtub_outlined,
    'electrical': Icons.electrical_services_outlined,
    'plumbing': Icons.plumbing_outlined,
    'carpentry': Icons.carpenter_outlined,
    'design': Icons.architecture_outlined,
    'full_reno': Icons.home_work_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (specialtyKeys.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: Text(
            S.specialtiesLabel,
            style: BatshTypography.titleLg.copyWith(
              color: BatshColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        SizedBox(
          height: _scaledStripHeight(context, 96, 2),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.marginMobile,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: specialtyKeys.length,
            separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.sm),
            itemBuilder: (_, i) {
              final key = specialtyKeys[i];
              return _ServiceTile(
                icon: _icons[key] ?? Icons.handyman_outlined,
                label: OnboardingCatalog.specialtiesCatalog[key] ?? key,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.xs,
        vertical: BatshSpacing.md,
      ),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: BatshColors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: BatshIconSize.lg, color: BatshColors.primary),
          const SizedBox(height: BatshSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.labelSm.copyWith(
                color: BatshColors.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipsSection extends StatelessWidget {
  const _ChipsSection({required this.title, required this.labels});
  final String title;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.marginMobile,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BatshTypography.titleLg.copyWith(
              color: BatshColors.onSurface,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.sm,
            runSpacing: BatshSpacing.sm,
            children: [
              for (final label in labels)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BatshSpacing.gutter,
                    vertical: BatshSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: BatshColors.surfaceContainer,
                    borderRadius: BatshRadius.brFull,
                    border: Border.all(
                      color: BatshColors.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: BatshTypography.labelMd.copyWith(
                      color: BatshColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioSection extends StatelessWidget {
  const _PortfolioSection({
    required this.contractor,
    required this.projects,
    required this.isOwner,
    this.failed = false,
    this.onRetry,
  });
  final ContractorListing contractor;
  final List<PortfolioProject> projects;
  final bool isOwner;

  /// True when the fetch errored, as opposed to returning nothing.
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty && failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.marginMobile,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: BatshIconSize.md,
              color: BatshColors.onSurfaceVariant,
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: Text(
                S.portfolioLoadFailed,
                style: BatshTypography.bodySm.copyWith(
                  color: BatshColors.onSurfaceVariant,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(S.tryAgain)),
          ],
        ),
      );
    }
    if (projects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: Row(
            children: [
              Text(
                S.portfolioGalleryTitle,
                style: BatshTypography.titleLg.copyWith(
                  color: BatshColors.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => isOwner
                    ? context.go(Routes.contractorPortfolio)
                    : context.push(
                        Routes.homeownerContractorPortfolioPath(contractor.id),
                      ),
                child: Text(S.viewAll),
              ),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        SizedBox(
          height: _scaledStripHeight(context, 234, 2),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.marginMobile,
            ),
            itemCount: projects.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: BatshSpacing.gutter),
            itemBuilder: (context, i) {
              final p = projects[i];
              return _PortfolioTile(
                project: p,
                onTap: () => isOwner
                    ? context.push(Routes.contractorPortfolioEditPath(p.id))
                    : context.push(
                        Routes.homeownerProjectDetailPath(contractor.id, p.id),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.project, required this.onTap});
  final PortfolioProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BatshRadius.brXl,
          boxShadow: BatshShadows.soft,
        ),
        child: BatshPressable(
          onTap: onTap,
          semanticLabel: project.title,
          child: Material(
            color: BatshColors.surfaceContainerLowest,
            borderRadius: BatshRadius.brXl,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: CachedNetworkImage(
                    imageUrl: sizedImageUrl(project.coverPhotoUrl, width: 520),
                    fit: BoxFit.cover,
                    // Tile is 260px wide.
                    memCacheWidth: 520,
                    placeholder: (_, _) =>
                        const ColoredBox(color: BatshColors.surfaceContainer),
                    errorWidget: (_, _, _) => Container(
                      color: BatshColors.surfaceContainer,
                      child: const Icon(
                        Icons.image_outlined,
                        color: BatshColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(BatshSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (project.category != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          project.category!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.labelSm.copyWith(
                            color: BatshColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
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
