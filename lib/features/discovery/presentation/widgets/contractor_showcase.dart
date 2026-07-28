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
import 'package:batsh/core/l10n/l10n_extension.dart';
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

import 'package:batsh/core/theme/theme_extension.dart';
part 'contractor_showcase_header.dart';
part 'contractor_showcase_sections.dart';

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
          backgroundColor: context.colorScheme.background,
          foregroundColor: context.colorScheme.onSurface,
          elevation: 0,
          leading: _isOwner ? null : const _BackButton(),
          actions: _isOwner
              ? [
                  IconButton(
                    tooltip: context.l10n.editLabel,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                ]
              : [
                  IconButton(
                    tooltip: isSaved
                        ? context.l10n.unsaveTooltip
                        : context.l10n.saveTooltip,
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurface,
                    ),
                    onPressed: () => runSignedIn(
                      context,
                      ref,
                      reason: context.l10n.signInToSave,
                      action: () => ref
                          .read(savedControllerProvider.notifier)
                          .toggle(listing.id),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.share,
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareContractor(context, listing),
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
                _ChipsSection(
                  title: context.l10n.worksIn,
                  labels: listing.serviceAreas,
                ),
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
void _shareContractor(BuildContext context, ContractorListing listing) {
  final name = listing.businessName.isNotEmpty
      ? listing.businessName
      : listing.fullName;
  final blurb = StringBuffer(
    context.l10n.seeOnShattab.replaceFirst('%s', name),
  );
  if (listing.headline != null && listing.headline!.isNotEmpty) {
    blurb.write(' - ${listing.headline}');
  }
  blurb.write('\n${context.l10n.forContact}: ${listing.phone}');
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
        WhatsAppButton(
          phone: listing.phone,
          message: context.l10n.profileGreeting,
        ),
        const SizedBox(height: BatshSpacing.sm),
        Row(
          children: [
            Expanded(
              child: BatshButton(
                label: context.l10n.sendProjectDetails,
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
          label: context.l10n.projectsCompleted,
          icon: Icons.home_work_outlined,
        ),
      if (contractor.yearsExperience != null)
        _StatCard(
          value: '${contractor.yearsExperience}',
          label: context.l10n.experienceYears,
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
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXl,
        boxShadow: BatshShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: context.colorScheme.primary,
            size: BatshIconSize.md,
          ),
          const SizedBox(height: BatshSpacing.md),
          // Plain text, no count-up tween. The tween began at 0 on every build,
          // and this widget's ancestor watches the saved-contractors provider —
          // so tapping the bookmark made the stats visibly re-count from zero.
          // Animating 0→3 was never worth that.
          Text(
            value,
            style: BatshTypography.displayMd.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            label,
            maxLines: 2,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                context.colorScheme.primary,
                context.colorScheme.onPrimaryFixedVariant,
              ],
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          context.colorScheme.tertiaryContainer,
                          context.colorScheme.tertiary,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: BatshIconSize.md,
                      color: context.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.upgradeToProShort,
                          style: BatshTypography.titleMd.copyWith(
                            color: context.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          context.l10n.proValueLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.bodySm.copyWith(
                            color: context.colorScheme.onPrimary.withValues(
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
                    color: context.colorScheme.onPrimary.withValues(alpha: 0.9),
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
            label: context.l10n.editProfileButton,
            style: BatshButtonStyle.secondary,
            onPressed: onEdit,
          ),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: BatshIconSize.sm,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                context.l10n.clientsPreview,
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
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
        label: context.l10n.signOutButton,
        style: BatshButtonStyle.ghost,
        onPressed: onSignOut,
      ),
    );
  }
}
