import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/shattab_experience_state.dart';
import '../../../../core/widgets/shattab_pattern.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../discovery/domain/contractor_listing.dart';
import '../../../discovery/presentation/widgets/mockup_assets.dart';
import '../../../portfolio/data/portfolio_repository.dart';
import '../../../portfolio/domain/portfolio_project.dart';
import 'home_hero.dart';
import 'home_shortcuts.dart';

/// One professional, argued for.
///
/// Landscape rather than portrait: the home page has already spent a full
/// viewport on a photograph, and a second tall image would push the work
/// gallery off the screen. The photograph keeps one half and carries the trust
/// mark; everything a hiring decision needs — who they are, what they do,
/// where, how they are rated, how much they have finished — stacks on the
/// other half above the one action that leaves the app.
class HomeFeaturedProfessionalCard extends StatelessWidget {
  const HomeFeaturedProfessionalCard({
    super.key,
    required this.listing,
    required this.onOpenProfile,
    required this.isSaved,
    required this.onToggleSave,
  });

  final ContractorListing listing;
  final VoidCallback onOpenProfile;
  final bool isSaved;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.isNotEmpty
        ? listing.businessName
        : listing.fullName;
    final trade = listing.specialties.isNotEmpty
        ? localizedSpecialtyLabel(context, listing.specialties.first)
        : listing.providerKind.label(context);
    final area = listing.serviceAreas.firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: homeGutter),
      child: Container(
        padding: const EdgeInsets.all(BatshSpacing.sm),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brCard,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: BatshShadows.soft,
        ),
        // The identity column sets the height from its own content and the
        // photograph stretches to match, so the card never has to be told a
        // pixel height it would overflow at a large text scale.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 57/43 rather than an even split. The identity column carries
              // five stacked lines and a button; the photograph carries one
              // image. At 53 the metrics row ran out of width and ellipsised
              // the project count, which is the number the card exists to show.
              Expanded(
                flex: 57,
                child: _FeaturedIdentity(
                  listing: listing,
                  name: name,
                  trade: trade,
                  area: area,
                  isSaved: isSaved,
                  onToggleSave: onToggleSave,
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                flex: 43,
                child: _FeaturedMedia(
                  listing: listing,
                  onOpenProfile: onOpenProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photograph, trust mark, and the quieter of the card's two actions.
class _FeaturedMedia extends StatelessWidget {
  const _FeaturedMedia({required this.listing, required this.onOpenProfile});

  final ContractorListing listing;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final borrowedCover = listing.coverPhotoUrl?.trim().isNotEmpty != true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BatshRadius.brLg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MockupImage(
                  url: listing.coverPhotoUrl ?? mockupPortfolioImages.first,
                  memCacheWidth: 640,
                ),
                PositionedDirectional(
                  top: BatshSpacing.xs,
                  start: BatshSpacing.xs,
                  end: BatshSpacing.xs,
                  child: Wrap(
                    spacing: BatshSpacing.xxs,
                    runSpacing: BatshSpacing.xxs,
                    children: [
                      // Only when the record says so. A trust mark that is
                      // decoration is worse than no trust mark at all.
                      if (listing.verified) const _VerifiedPill(),
                      if (borrowedCover) const MockupSampleBadge(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: BatshSpacing.xs),
        _SecondaryAction(
          label: context.l10n.homeViewProfile,
          onTap: onOpenProfile,
        ),
      ],
    );
  }
}

/// The olive trust mark. Olive and white are fixed rather than themed: this
/// pill sits on a contractor's own upload, so its contrast cannot depend on
/// which surface the page happens to be painting.
class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.verifiedByShattab,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.xs,
          vertical: BatshSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: BatshColors.secondary,
          borderRadius: BatshRadius.brFull,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, size: 13, color: Colors.white),
              const SizedBox(width: BatshSpacing.xxs),
              Text(
                context.l10n.verified,
                style: BatshTypography.labelSm.copyWith(
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

/// Who they are, and the action that starts a conversation.
class _FeaturedIdentity extends StatelessWidget {
  const _FeaturedIdentity({
    required this.listing,
    required this.name,
    required this.trade,
    required this.area,
    required this.isSaved,
    required this.onToggleSave,
  });

  final ContractorListing listing;
  final String name;
  final String trade;
  final String? area;
  final bool isSaved;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _SaveButton(isSaved: isSaved, onTap: onToggleSave),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.titleMd.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: BatshSpacing.xs),
            AvatarWithInitials(
              imageUrl: listing.logoUrl == null
                  ? null
                  : sizedImageUrl(listing.logoUrl!, width: 120),
              name: name,
              radius: 21,
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.xxs),
        Text(
          trade,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BatshTypography.bodySm.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        if (area != null && area!.isNotEmpty) ...[
          const SizedBox(height: BatshSpacing.xxxs),
          Text(
            area!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: BatshSpacing.xs),
        _FeaturedMetrics(listing: listing),
        const SizedBox(height: BatshSpacing.sm),
        WhatsAppButton(
          phone: listing.phone,
          emphasis: ContactEmphasis.primary,
          label: context.l10n.homeContactWhatsApp,
        ),
      ],
    );
  }
}

/// Rating beside finished work. Each is omitted rather than shown as zero:
/// "0.0" and "0 projects" read as a bad professional, not a new one.
class _FeaturedMetrics extends StatelessWidget {
  const _FeaturedMetrics({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final rating = listing.hasReviews
        ? '${listing.reviewAvg.toStringAsFixed(1)} (${listing.reviewCount})'
        : null;
    final completed = listing.projectsCompleted > 0
        ? '${listing.projectsCompleted} ${context.l10n.completedProjectsShort}'
        : null;

    if (rating == null && completed == null) {
      return Text(
        context.l10n.newBadge,
        style: BatshTypography.labelSm.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Shrinks to fit rather than truncating. Ellipsis on this line eats the
    // project count from the right — "200 مشروع مك…" — and the count is one of
    // the two numbers the card exists to show. The same trade is already made
    // by the discover tab's featured card for the same reason.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rating != null) ...[
            const Icon(
              Icons.star_rounded,
              size: BatshIconSize.inline,
              color: BatshColors.starGold,
            ),
            const SizedBox(width: BatshSpacing.xxs),
            Text(
              rating,
              // Digits and parentheses only: left to right whatever the page
              // is set to.
              textDirection: TextDirection.ltr,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (rating != null && completed != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.xxs),
              child: Text(
                '|',
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.outlineVariant,
                ),
              ),
            ),
          if (completed != null)
            Text(
              completed,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isSaved,
      label: context.l10n.mySaved,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: BatshSpacing.minHitArea,
            height: 36,
            child: ExcludeSemantics(
              child: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: BatshIconSize.md,
                color: isSaved
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The outlined half of the card's action pair.
class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BatshRadius.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brFull,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.xs),
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brFull,
              border: Border.all(
                color: context.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: ExcludeSemantics(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Finished work ───────────────────────────────────────────────────────────

/// Real rooms, sized to be read as rooms.
///
/// The page's closing evidence: actual finished work from the catalogue,
/// one tap from the full gallery. Tiles were originally 68dp thumbnails on
/// the theory that the strip was a teaser; with the process story and the
/// featured professional restored around them, a readable photo card carries
/// the "this marketplace is alive" argument better than a postage stamp.
class HomeProjectsRail extends ConsumerWidget {
  const HomeProjectsRail({
    super.key,
    required this.onViewAll,
    required this.onOpenProject,
  });

  final VoidCallback onViewAll;
  final void Function(String contractorId, String projectId) onOpenProject;

  /// ~2.6 cards visible at the 390dp reference width: enough to read the
  /// room, enough of a third card peeking to make the rail scrollable.
  static const double tileWidth = 132;
  static const double tileHeight = 104;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(recentProjectsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: homeGutter),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    context.l10n.recentWorkTitle,
                    style: BatshTypography.headlineSm.copyWith(
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              HomeViewAllLink(onTap: onViewAll),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.xs),
        projects.when(
          loading: () => SizedBox(
            height: tileHeight,
            child: _rail(
              itemCount: 5,
              builder: (_, _) => const BatshShimmerBox(
                width: tileWidth,
                height: tileHeight,
                borderRadius: BatshRadius.brMd,
              ),
            ),
          ),
          error: (_, _) => _stateRail(
            icon: Icons.cloud_off_outlined,
            title: context.l10n.homeProjectsLoadErrorTitle,
            message: context.l10n.homeProjectsLoadErrorMessage,
            actionLabel: context.l10n.retry,
            onAction: () => ref.invalidate(recentProjectsProvider),
          ),
          data: (all) => all.isEmpty
              ? _stateRail(
                  icon: Icons.photo_library_outlined,
                  title: context.l10n.homeProjectsEmptyTitle,
                  message: context.l10n.homeProjectsEmptyMessage,
                  actionLabel: context.l10n.viewAll,
                  onAction: onViewAll,
                )
              : SizedBox(
                  height: tileHeight,
                  child: _rail(
                    itemCount: all.length,
                    builder: (_, index) => _ProjectPreviewCard(
                      project: all[index],
                      onTap: () =>
                          onOpenProject(all[index].contractorId, all[index].id),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _stateRail({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: homeGutter),
    child: ShattabExperienceState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      compact: true,
      pattern: ShattabPatternKind.lattice,
    ),
  );

  Widget _rail({
    required int itemCount,
    required Widget Function(BuildContext, int) builder,
  }) => ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: homeGutter),
    physics: const BouncingScrollPhysics(),
    itemCount: itemCount,
    separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.xs),
    itemBuilder: builder,
  );
}

class _ProjectPreviewCard extends StatelessWidget {
  const _ProjectPreviewCard({required this.project, required this.onTap});

  final PortfolioProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final where = project.location ?? project.category;
    return _ProjectPreviewTile(
      url: project.coverPhotoUrl,
      semanticLabel: where == null || where.isEmpty
          ? project.title
          : '${project.title} — $where',
      onTap: onTap,
    );
  }
}

class _ProjectPreviewTile extends StatelessWidget {
  const _ProjectPreviewTile({
    required this.url,
    required this.semanticLabel,
    required this.onTap,
  });

  final String? url;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: HomeProjectsRail.tileWidth,
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: ClipRRect(
          borderRadius: BatshRadius.brMd,
          child: MockupImage(url: url, memCacheWidth: 420),
        ),
      ),
    );
  }
}
