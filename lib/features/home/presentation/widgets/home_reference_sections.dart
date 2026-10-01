import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/catalog/specialty_catalog.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_initial_plate.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/batsh_section_header.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/shattab_experience_state.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../../discovery/domain/contractor_listing.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../../saved/presentation/providers/saved_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';

const double _referenceGutter = BatshSpacing.pageGutter;

class ReferenceHomeHeader extends StatelessWidget {
  const ReferenceHomeHeader({
    super.key,
    required this.locationLabel,
    required this.unreadCount,
    required this.onNotificationTap,
    required this.onMenuTap,
  });

  final String? locationLabel;
  final int unreadCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final location = locationLabel?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _referenceGutter,
        BatshSpacing.sm,
        _referenceGutter,
        BatshSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo_wordmark.png',
                  height: 34,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: BatshSpacing.sm),
                if (location != null && location.isNotEmpty) ...[
                  Icon(
                    Icons.location_on_outlined,
                    size: BatshIconSize.sm,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: BatshSpacing.xxs),
                  Flexible(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelMd.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _HeaderAction(
            icon: Icons.notifications_none_rounded,
            label: context.l10n.notificationsTitle,
            onTap: onNotificationTap,
            showDot: unreadCount > 0,
          ),
          const SizedBox(width: BatshSpacing.xs),
          _HeaderAction(
            icon: Icons.menu_rounded,
            label: context.l10n.accountSettingsTitle,
            onTap: onMenuTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Stack(
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
                color: context.colorScheme.primary,
              ),
            ),
          ),
          if (showDot)
            PositionedDirectional(
              top: BatshSpacing.xs,
              end: BatshSpacing.xs,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colorScheme.surface),
                  ),
                  child: const SizedBox(width: 8, height: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ReferenceHomeHero extends StatelessWidget {
  const ReferenceHomeHero({
    super.key,
    required this.onStartProject,
    required this.onExploreProfessionals,
    this.child,
  });

  final VoidCallback onStartProject;
  final VoidCallback onExploreProfessionals;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // Keep the public hero seam available to older host screens while the
    // newer reference composition owns the actual visual treatment.
    if (child != null) return child!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _referenceGutter),
      child: BatshCard(
        primary: true,
        padding: const EdgeInsets.all(BatshSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.homeStartTitle,
              style: BatshTypography.labelLg.copyWith(
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              context.l10n.homeHeroTitleLead,
              style: BatshTypography.headlineLg.copyWith(
                color: context.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              context.l10n.homeHeroTitleRest,
              style: BatshTypography.headlineSm.copyWith(
                color: context.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              context.l10n.homeHeroSubtitle,
              style: BatshTypography.bodyMd.copyWith(
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshButton(
              label: context.l10n.homeStartQuoteTitle,
              icon: Icons.add_home_work_outlined,
              onPressed: onStartProject,
              backgroundColor: context.colorScheme.primary,
              foregroundColor: context.colorScheme.onPrimary,
            ),
            const SizedBox(height: BatshSpacing.xs),
            BatshButton(
              label: context.l10n.homeStartDiscoverTitle,
              icon: Icons.search_rounded,
              onPressed: onExploreProfessionals,
              style: BatshButtonStyle.ghost,
              foregroundColor: context.colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class ReferenceDiscoverySection extends ConsumerWidget {
  const ReferenceDiscoverySection({
    super.key,
    required this.onOpenDiscover,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenDiscover;
  final ValueChanged<String> onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(homeownerProfileProvider).value;
    final city = profile?.city?.trim();
    final professionals = city == null || city.isEmpty
        ? ref.watch(discoverContractorsProvider)
        : ref.watch(nearbyProfessionalsProvider(city));
    final savedIds =
        ref.watch(savedContractorIdsProvider).value ?? const <String>{};

    return Padding(
      padding: const EdgeInsets.only(top: BatshSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _referenceGutter),
            child: BatshSectionHeader(
              title: city == null || city.isEmpty
                  ? context.l10n.homeQuickNearbyTitle
                  : context.l10n.nearYouIn(city),
              padding: EdgeInsets.zero,
              trailing: BatshButton(
                label: context.l10n.viewAll,
                onPressed: onOpenDiscover,
                style: BatshButtonStyle.ghost,
                fullWidth: false,
                animate: false,
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          professionals.when(
            loading: () => const _HomeProfessionalSkeleton(),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: _referenceGutter),
              child: ShattabExperienceState(
                icon: Icons.cloud_off_outlined,
                title: context.l10n.unknownErrorRetry,
                message: context.l10n.tryAgain,
                actionLabel: context.l10n.tryAgain,
                onAction: () => city == null || city.isEmpty
                    ? ref.invalidate(discoverContractorsProvider)
                    : ref.invalidate(nearbyProfessionalsProvider(city)),
                compact: true,
              ),
            ),
            data: (items) {
              final visible = items.take(3).toList(growable: false);
              if (visible.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _referenceGutter,
                  ),
                  child: ShattabExperienceState(
                    icon: Icons.people_outline_rounded,
                    title: context.l10n.noContractorsTitle,
                    message: context.l10n.noContractorsMessage,
                    actionLabel: context.l10n.homeStartDiscoverTitle,
                    onAction: onOpenDiscover,
                    compact: true,
                  ),
                );
              }
              return SizedBox(
                height: 176,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _referenceGutter,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: BatshSpacing.sm),
                  itemBuilder: (_, index) {
                    final listing = visible[index];
                    return _HomeProfessionalCard(
                      listing: listing,
                      isSaved: savedIds.contains(listing.id),
                      onToggleSave: () => runSignedIn(
                        context,
                        ref,
                        reason: context.l10n.signInToSave,
                        action: () => ref
                            .read(savedControllerProvider.notifier)
                            .toggle(listing.id),
                      ),
                      onTap: () => onOpenProfile(listing.id),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeProfessionalSkeleton extends StatelessWidget {
  const _HomeProfessionalSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: _referenceGutter),
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.sm),
        itemBuilder: (_, _) => const SizedBox(
          width: 260,
          child: BatshSkeletonRegion(
            child: BatshShimmerBox(
              height: 176,
              borderRadius: BatshRadius.brCard,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeProfessionalCard extends StatelessWidget {
  const _HomeProfessionalCard({
    required this.listing,
    required this.isSaved,
    required this.onToggleSave,
    required this.onTap,
  });

  final ContractorListing listing;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.trim().isNotEmpty
        ? listing.businessName.trim()
        : listing.fullName.trim();
    final trade = listing.specialties.isEmpty
        ? listing.providerKind.label(context)
        : localizedSpecialtyLabel(context, listing.specialties.first);
    final area = listing.serviceAreas.firstOrNull;

    return SizedBox(
      width: 260,
      child: BatshCard(
        padding: const EdgeInsets.all(BatshSpacing.md),
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AvatarWithInitials(
                      imageUrl: listing.logoUrl,
                      name: name,
                      radius: 25,
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.titleMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BatshSpacing.xs),
                Text(
                  trade,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.bodySm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (area != null && area.isNotEmpty)
                  Text(
                    area,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.bodySm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    if (listing.hasReviews) ...[
                      Icon(
                        Icons.star_rounded,
                        size: BatshIconSize.sm,
                        color: context.colorScheme.tertiary,
                      ),
                      const SizedBox(width: BatshSpacing.xxs),
                      Text(
                        listing.reviewAvg.toStringAsFixed(1),
                        textDirection: TextDirection.ltr,
                        style: BatshTypography.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else
                      Text(context.l10n.newBadge),
                    const Spacer(),
                    if (listing.projectsCompleted > 0)
                      Text(
                        '${listing.projectsCompleted} ${context.l10n.completedProjectsShort}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelSm.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            PositionedDirectional(
              top: -BatshSpacing.xs,
              end: -BatshSpacing.xs,
              child: Tooltip(
                message: isSaved
                    ? context.l10n.unsaveTooltip
                    : context.l10n.saveTooltip,
                child: BatshPressable(
                  onTap: onToggleSave,
                  semanticLabel: isSaved
                      ? context.l10n.unsaveTooltip
                      : context.l10n.saveTooltip,
                  child: SizedBox(
                    width: BatshSpacing.minHitArea,
                    height: BatshSpacing.minHitArea,
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
          ],
        ),
      ),
    );
  }
}

class ReferenceServiceCategories extends StatelessWidget {
  const ReferenceServiceCategories({
    super.key,
    required this.onSelect,
    required this.onViewAll,
  });

  final ValueChanged<String> onSelect;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final categories = SpecialtyCatalog.popularRootKeys;
    return Padding(
      padding: const EdgeInsets.only(top: BatshSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _referenceGutter),
            child: BatshSectionHeader(
              title: context.l10n.homeServicesTitle,
              padding: EdgeInsets.zero,
              trailing: BatshButton(
                label: context.l10n.viewAll,
                onPressed: onViewAll,
                style: BatshButtonStyle.ghost,
                fullWidth: false,
                animate: false,
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          SizedBox(
            height: 88,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: _referenceGutter),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: BatshSpacing.sm),
              itemBuilder: (_, index) {
                final category = categories[index];
                final label = localizedSpecialtyLabel(context, category);
                return SizedBox(
                  width: 82,
                  child: BatshPressable(
                    onTap: () => onSelect(category),
                    semanticLabel: label,
                    child: Column(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.colorScheme.surfaceContainerLowest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colorScheme.outlineVariant,
                            ),
                            boxShadow: BatshShadows.soft,
                          ),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(
                              specialtyIcon(category),
                              size: BatshIconSize.action,
                              color: context.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: BatshSpacing.xs),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: BatshTypography.labelSm,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Honest community invitation. It contains no synthetic professional or
/// project, and routes to the existing community surface.
class ReferenceExpertCard extends StatelessWidget {
  const ReferenceExpertCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _referenceGutter,
        BatshSpacing.xl,
        _referenceGutter,
        BatshSpacing.lg,
      ),
      child: BatshCard(
        onTap: onTap,
        primary: true,
        child: Row(
          children: [
            const SizedBox(width: 48, height: 48, child: BatshInitialPlate()),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.homeStartCommunityTitle,
                    style: BatshTypography.titleMd.copyWith(
                      color: context.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xxs),
                  Text(
                    context.l10n.homeStartCommunitySubtitle,
                    style: BatshTypography.bodySm.copyWith(
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_back_rounded,
              size: BatshIconSize.md,
              color: context.colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
