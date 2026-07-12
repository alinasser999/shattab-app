import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../portfolio/domain/portfolio_project.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../../saved/presentation/providers/saved_providers.dart';
import '../../domain/contractor_listing.dart';

/// How the showcase is being viewed.
/// - [public]: a homeowner browsing the contractor (save, share, contact CTAs).
/// - [owner]: the contractor viewing their own profile (edit + sign out).
enum ShowcaseMode { public, owner }

/// The full LinkedIn-style contractor profile body, shared by the public
/// discover screen and the contractor's own profile tab. Renders a
/// [CustomScrollView]; the host supplies the [Scaffold].
class ContractorShowcase extends ConsumerWidget {
  const ContractorShowcase({
    super.key,
    required this.listing,
    this.mode = ShowcaseMode.public,
    this.rating,
    this.reviewCount,
    this.onEdit,
    this.onSignOut,
    this.showInlineContact = true,
  });

  final ContractorListing listing;
  final ShowcaseMode mode;

  /// When false, the inline contact CTA block is omitted — the host screen is
  /// expected to render a pinned (sticky) contact bar instead, so the primary
  /// action stays reachable no matter how far the user scrolls.
  final bool showInlineContact;

  /// Real average rating; falls back to [ContractorListing.computedRating]
  /// until M4 reviews are wired in.
  final double? rating;
  final int? reviewCount;

  /// Owner-mode callbacks.
  final VoidCallback? onEdit;
  final VoidCallback? onSignOut;

  bool get _isOwner => mode == ShowcaseMode.owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? const {};
    final isSaved = savedIds.contains(listing.id);
    final portfolio =
        ref.watch(portfolioForContractorProvider(listing.id)).value ??
            const <PortfolioProject>[];
    final effectiveRating = rating ?? listing.displayRating;
    final effectiveCount = reviewCount ?? listing.reviewCount;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
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
                      color:
                          isSaved ? BatshColors.primary : BatshColors.onSurface,
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
                    onPressed: () => _shareContractor(context, listing),
                  ),
                ],
          flexibleSpace: FlexibleSpaceBar(
            background: _CoverHero(coverUrl: listing.coverPhotoUrl),
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -56),
            child: Column(
              children: [
                _AvatarRing(logoUrl: listing.logoUrl),
                const SizedBox(height: BatshSpacing.md),
                _NameHeadline(contractor: listing),
                const SizedBox(height: BatshSpacing.md),
                _RatingPill(
                  rating: effectiveRating,
                  reviewCount: effectiveCount,
                ),
                const SizedBox(height: BatshSpacing.lg),
                _StatsRow(contractor: listing),
                const SizedBox(height: BatshSpacing.lg),
                if (_isOwner)
                  _OwnerActions(onEdit: onEdit)
                else if (showInlineContact)
                  _CtaBlock(contractor: listing),
                const SizedBox(height: BatshSpacing.xl),
                if (listing.bio != null && listing.bio!.isNotEmpty)
                  _BioSection(bio: listing.bio!),
                const SizedBox(height: BatshSpacing.xl),
                _ChipsSection(
                  title: S.specialtiesLabel,
                  labels: listing.specialties
                      .map((s) => OnboardingCatalog.specialtiesCatalog[s] ?? s)
                      .toList(),
                ),
                const SizedBox(height: BatshSpacing.lg),
                _ChipsSection(
                  title: S.worksIn,
                  labels: listing.serviceAreas,
                ),
                const SizedBox(height: BatshSpacing.xl),
                _PortfolioSection(
                  contractor: listing,
                  projects: portfolio,
                  isOwner: _isOwner,
                ),
                if (_isOwner && onSignOut != null) ...[
                  const SizedBox(height: BatshSpacing.xl),
                  _SignOutBlock(onSignOut: onSignOut!),
                ],
                const SizedBox(height: 96),
              ],
            ),
          ).animate().fadeIn(duration: 220.ms),
        ),
      ],
    );
  }
}

/// Shares the contractor. No public profile URL / deep link exists yet, so we
/// copy a ready-to-send Arabic blurb to the clipboard and confirm via snackbar.
/// Swap this for share_plus's native share sheet once deep links land.
void _shareContractor(BuildContext context, ContractorListing listing) {
  final name =
      listing.businessName.isNotEmpty ? listing.businessName : listing.fullName;
  final blurb = StringBuffer(S.seeOnShattab.replaceFirst('%s', name));
  if (listing.headline != null && listing.headline!.isNotEmpty) {
    blurb.write(' — ${listing.headline}');
  }
  blurb.write('\n${S.forContact}: ${listing.phone}');
  Clipboard.setData(ClipboardData(text: blurb.toString()));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(S.copiedData),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: IconButton(
          icon: const Icon(Icons.arrow_forward, color: BatshColors.onSurface),
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
            imageUrl: coverUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                const ColoredBox(color: BatshColors.surfaceContainer),
            errorWidget: (_, _, _) => const _CoverFallback(),
          )
        else
          const _CoverFallback(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BatshColors.primary.withValues(alpha: 0.0),
                BatshColors.primary.withValues(alpha: 0.45),
                BatshColors.background.withValues(alpha: 0.95),
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
      width: 116,
      height: 116,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BatshColors.background,
        shape: BoxShape.circle,
        boxShadow: BatshShadows.raised,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: BatshColors.surfaceContainer,
          border: Border.all(color: BatshColors.primary, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: logoUrl != null
            ? CachedNetworkImage(
                imageUrl: logoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const ColoredBox(color: BatshColors.surfaceContainer),
              )
            : const Icon(Icons.engineering_outlined,
                size: 48, color: BatshColors.primary),
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
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
      child: Column(
        children: [
          Text(name,
              textAlign: TextAlign.center,
              style: BatshTypography.headlineMd),
          if (contractor.headline != null &&
              contractor.headline!.isNotEmpty) ...[
            const SizedBox(height: BatshSpacing.xs),
            Text(
              contractor.headline!,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating, this.reviewCount});
  final double rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    // Cold-start: a brand-new contractor has no reviews. Showing empty stars +
    // "0.0" reads as *bad*; a neutral "جديد" badge reads as *new*. Same data,
    // opposite trust signal (Airbnb/Upwork pattern). Icon + text, not colour
    // alone, so it survives accessibility/colour-blind checks.
    if (reviewCount == null || reviewCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.gutter, vertical: BatshSpacing.sm),
        decoration: BoxDecoration(
          color: BatshColors.secondaryContainer,
          borderRadius: BatshRadius.brFull,
          border: Border.all(color: BatshColors.secondary, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome,
                size: 16, color: BatshColors.onSecondaryContainer),
            const SizedBox(width: BatshSpacing.xs),
            Text(
              S.newContractor,
              style: BatshTypography.labelMd.copyWith(
                color: BatshColors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.gutter, vertical: BatshSpacing.sm),
      decoration: BoxDecoration(
        color: BatshColors.tertiaryFixed,
        borderRadius: BatshRadius.brFull,
        border: Border.all(color: BatshColors.tertiary, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = i < rating.floor();
              final half = !filled && i == rating.floor() && rating % 1 >= 0.4;
              return Icon(
                half ? Icons.star_half : Icons.star,
                size: 14,
                color: filled || half
                    ? BatshColors.tertiary
                    : BatshColors.surfaceContainerHigh,
              );
            }),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Text(
            rating.toStringAsFixed(1),
            style: BatshTypography.labelMd.copyWith(
              color: BatshColors.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (reviewCount != null && reviewCount! > 0) ...[
            const SizedBox(width: BatshSpacing.xs),
            Text(
              '($reviewCount ${S.reviewsCount})',
              style: BatshTypography.labelSm
                  .copyWith(color: BatshColors.onTertiaryContainer),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.contractor});
  final ContractorListing contractor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
      child: Row(
        children: [
          // Response-rate tile removed — the value was a hardcoded default
          // (100%) for everyone, never measured. Bring back when tracked.
          Expanded(
            child: _StatCard(
              value: '${contractor.projectsCompleted}',
              label: S.projectsCompleted,
              icon: Icons.home_work_outlined,
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: _StatCard(
              value: contractor.yearsExperience != null
                  ? '${contractor.yearsExperience}'
                  : '—',
              label: S.experienceYears,
              icon: Icons.workspace_premium_outlined,
            ),
          ),
        ],
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
          vertical: BatshSpacing.md, horizontal: BatshSpacing.sm),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: BatshColors.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: BatshColors.primary, size: 20),
          const SizedBox(height: BatshSpacing.xs),
          Text(value,
              style: BatshTypography.titleLg.copyWith(
                  color: BatshColors.onSurface, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: BatshTypography.labelSm
                  .copyWith(color: BatshColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _CtaBlock extends StatelessWidget {
  const _CtaBlock({required this.contractor});
  final ContractorListing contractor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
      child: Column(
        children: [
          BatshButton(
            label: S.sendProjectDetails,
            onPressed: () =>
                context.push(Routes.homeownerSendBriefPath(contractor.id)),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            children: [
              Expanded(
                child: WhatsAppButton(
                  phone: contractor.phone,
                  message: S.profileGreeting,
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(child: CallButton(phone: contractor.phone)),
            ],
          ),
        ],
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
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
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
              const Icon(Icons.visibility_outlined,
                  size: 14, color: BatshColors.onSurfaceVariant),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                S.clientsPreview,
                style: BatshTypography.labelSm
                    .copyWith(color: BatshColors.onSurfaceVariant),
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
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
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
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(BatshSpacing.gutter),
        decoration: BoxDecoration(
          color: BatshColors.surfaceContainerLow,
          borderRadius: BatshRadius.brLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.aboutContractor,
                style: BatshTypography.labelMd.copyWith(
                  color: BatshColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: BatshSpacing.sm),
            Text(bio, style: BatshTypography.bodyLg),
          ],
        ),
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
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: BatshTypography.titleLg
                  .copyWith(color: BatshColors.onSurface)),
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.sm,
            runSpacing: BatshSpacing.sm,
            children: [
              for (final label in labels)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.gutter,
                      vertical: BatshSpacing.sm),
                  decoration: BoxDecoration(
                    color: BatshColors.surfaceContainer,
                    borderRadius: BatshRadius.brFull,
                    border:
                        Border.all(color: BatshColors.outlineVariant, width: 1),
                  ),
                  child: Text(label,
                      style: BatshTypography.labelMd.copyWith(
                          color: BatshColors.onSurface,
                          fontWeight: FontWeight.w600)),
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
  });
  final ContractorListing contractor;
  final List<PortfolioProject> projects;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
          child: Row(
            children: [
              Text(S.portfolioGalleryTitle,
                  style: BatshTypography.titleLg
                      .copyWith(color: BatshColors.onSurface)),
              const Spacer(),
              TextButton(
                onPressed: () => isOwner
                    ? context.go(Routes.contractorPortfolio)
                    : context.push(
                        Routes.homeownerContractorPortfolioPath(contractor.id)),
                child: Text(S.viewAll),
              ),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        SizedBox(
          height: 234,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.marginMobile),
            itemCount: projects.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: BatshSpacing.gutter),
            itemBuilder: (context, i) {
              final p = projects[i];
              return _PortfolioTile(
                project: p,
                onTap: () => isOwner
                    ? context.push(Routes.contractorPortfolioEditPath(p.id))
                    : context.push(Routes.homeownerProjectDetailPath(
                        contractor.id, p.id)),
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
      child: Material(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: project.coverPhotoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const ColoredBox(color: BatshColors.surfaceContainer),
                  errorWidget: (_, _, _) => Container(
                      color: BatshColors.surfaceContainer,
                      child: const Icon(Icons.image_outlined,
                          color: BatshColors.onSurfaceVariant)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(BatshSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (project.category != null) ...[
                      const SizedBox(height: 2),
                      Text(project.category!,
                          style: BatshTypography.labelSm.copyWith(
                              color: BatshColors.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
