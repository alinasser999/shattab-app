import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:batsh/core/l10n/catalog_labels.dart';
import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_initial_plate.dart';
import '../../../../core/widgets/shattab_pattern.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../../portfolio/domain/portfolio_project.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../../reviews/domain/review.dart';
import '../../../reviews/presentation/providers/reviews_providers.dart';
import '../../../reviews/presentation/reviews_sheet.dart';
import '../../../saved/presentation/providers/saved_providers.dart';
import '../../domain/contractor_listing.dart';

/// The homeowner-facing professional profile surface from the approved
/// Crafted Rhythm references.
///
/// This is intentionally separate from the older trust-first profile widget.
/// The route now uses this surface while the older widget remains available to
/// the existing component tests and the contractor-side preview seam.
class ReferenceProfessionalProfile extends ConsumerStatefulWidget {
  const ReferenceProfessionalProfile({super.key, required this.listing});

  final ContractorListing listing;

  @override
  ConsumerState<ReferenceProfessionalProfile> createState() =>
      _ReferenceProfessionalProfileState();
}

class _ReferenceProfessionalProfileState
    extends ConsumerState<ReferenceProfessionalProfile> {
  final _worksKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _reviewsKey = GlobalKey();
  int _activeTab = 0;
  bool _showCompactHeader = false;
  bool? _saveOverride;
  bool _saving = false;

  ContractorListing get listing => widget.listing;

  String get _name {
    final business = listing.businessName.trim();
    return business.isNotEmpty ? business : listing.fullName.trim();
  }

  String get _specialty => listing.specialties.isEmpty
      ? listing.providerKind.label(context)
      : localizedSpecialtyDisplayLabel(context, listing.specialties.first);

  String get _location => listing.serviceAreas.isEmpty
      ? 'المناطق المتاحة غير محددة'
      : listing.serviceAreas.first.trim();

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(portfolioForContractorProvider(listing.id));
    final reviewsAsync = ref.watch(reviewsForContractorProvider(listing.id));
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? const {};
    final isSaved = _saveOverride ?? savedIds.contains(listing.id);
    final projects = projectsAsync.value ?? const <PortfolioProject>[];
    final cover = _coverPhoto(projects);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final shouldShow = notification.metrics.pixels > 40;
          if (shouldShow != _showCompactHeader && mounted) {
            setState(() => _showCompactHeader = shouldShow);
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _ReferenceProfileHero(
                listing: listing,
                name: _name,
                coverUrl: cover,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            SliverToBoxAdapter(
              child: _ReferenceIdentity(
                listing: listing,
                name: _name,
                specialty: _specialty,
                location: _location,
                isSaved: isSaved,
                onSave: () => _runSave(context, isSaved),
                onShare: () => _share(context),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ReferenceTabsDelegate(
                minExtentValue: _showCompactHeader ? 116 : 54,
                maxExtentValue: _showCompactHeader ? 116 : 54,
                child: _ReferenceStickyHeader(
                  listing: listing,
                  name: _name,
                  specialty: _specialty,
                  location: _location,
                  isSaved: isSaved,
                  activeTab: _activeTab,
                  showCompact: _showCompactHeader,
                  onTab: _goToSection,
                  onBack: () => Navigator.of(context).maybePop(),
                  onSave: () => _runSave(context, isSaved),
                  onShare: () => _share(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _worksKey,
                child: _WorksSection(
                  listing: listing,
                  name: _name,
                  projectsAsync: projectsAsync,
                  onRetry: () => ref.invalidate(
                    portfolioForContractorProvider(listing.id),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _aboutKey,
                child: _AboutSection(
                  listing: listing,
                  name: _name,
                  onExploreWorks: () => _goToSection(0),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _reviewsKey,
                child: _ReviewsSection(
                  listing: listing,
                  reviewsAsync: reviewsAsync,
                  onViewAll: () => showReviewsSheet(context, listing.id),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 44)),
          ],
        ),
      ),
    );
  }

  String? _coverPhoto(List<PortfolioProject> projects) {
    if (isDisplayableImageUrl(listing.coverPhotoUrl)) {
      return listing.coverPhotoUrl;
    }
    for (final project in projects) {
      if (isDisplayableImageUrl(project.coverPhotoUrl)) {
        return project.coverPhotoUrl;
      }
    }
    return null;
  }

  void _goToSection(int index) {
    setState(() => _activeTab = index);
    final key = switch (index) {
      0 => _worksKey,
      1 => _aboutKey,
      _ => _reviewsKey,
    };
    final target = key.currentContext;
    if (target == null) return;
    unawaited(
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      ),
    );
  }

  void _share(BuildContext context) {
    unawaited(Share.share('$_name — ${context.l10n.profileTabWork}'));
  }

  void _runSave(BuildContext context, bool currentlySaved) {
    if (_saving) return;
    unawaited(
      runSignedIn(
        context,
        ref,
        reason: context.l10n.signInToSave,
        action: () =>
            unawaited(_toggleSave(context, currentlySaved: currentlySaved)),
      ),
    );
  }

  Future<void> _toggleSave(
    BuildContext context, {
    required bool currentlySaved,
  }) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveOverride = !currentlySaved;
    });
    try {
      await ref.read(savedControllerProvider.notifier).toggle(listing.id);
      if (!context.mounted) return;
      BatshSnack.success(
        context,
        currentlySaved ? 'تمت إزالة المحترف من المحفوظات' : 'تم حفظ المحترف',
      );
    } catch (error) {
      if (!context.mounted) return;
      setState(() => _saveOverride = currentlySaved);
      BatshSnack.error(context, ErrorMapper.map(error));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          if (_saveOverride == currentlySaved) _saveOverride = null;
        });
      }
    }
  }
}

class _ReferenceProfileHero extends StatelessWidget {
  const _ReferenceProfileHero({
    required this.listing,
    required this.name,
    required this.coverUrl,
    required this.onBack,
  });

  final ContractorListing listing;
  final String name;
  final String? coverUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 274,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          _ProfileImage(
            url: coverUrl,
            name: name,
            width: 1000,
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x2B000000),
                  Color(0x00000000),
                  Color(0x42000000),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: top + 10,
            end: BatshSpacing.gutter,
            child: _SquareAction(
              icon: Icons.arrow_forward_rounded,
              tooltip: 'رجوع',
              onPressed: onBack,
            ),
          ),
          PositionedDirectional(
            bottom: -39,
            end: BatshSpacing.gutter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colorScheme.surface,
                  width: 4,
                ),
                boxShadow: BatshShadows.soft,
              ),
              child: AvatarWithInitials(
                imageUrl: listing.logoUrl,
                name: name,
                radius: 39,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceIdentity extends StatelessWidget {
  const _ReferenceIdentity({
    required this.listing,
    required this.name,
    required this.specialty,
    required this.location,
    required this.isSaved,
    required this.onSave,
    required this.onShare,
  });

  final ContractorListing listing;
  final String name;
  final String specialty;
  final String location;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sectionH,
        48,
        BatshSpacing.sectionH,
        BatshSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _SquareAction(
                icon: Icons.share_outlined,
                tooltip: context.l10n.share,
                onPressed: onShare,
              ),
              const SizedBox(width: BatshSpacing.sm),
              _SquareAction(
                icon: isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                tooltip: isSaved
                    ? context.l10n.unsaveTooltip
                    : context.l10n.saveTooltip,
                selected: isSaved,
                onPressed: onSave,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.headlineMd.copyWith(
                        fontSize: 24,
                        height: 32 / 24,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.bodyLg.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: BatshIconSize.sm,
                          color: context.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            location,
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
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              _IdentityStat(
                value: listing.rating == null
                    ? '—'
                    : listing.rating!.toStringAsFixed(1),
                label: listing.reviewCount == 0
                    ? 'لا توجد تقييمات'
                    : '(${listing.reviewCount} تقييم)',
                icon: Icons.star_rounded,
                iconColor: BatshColors.starGold,
              ),
              _VerticalDivider(),
              _IdentityStat(
                value: '${listing.projectsCompleted}',
                label: 'مشروعًا مكتملًا',
                icon: Icons.business_center_outlined,
                iconColor: context.colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferenceStickyHeader extends StatelessWidget {
  const _ReferenceStickyHeader({
    required this.listing,
    required this.name,
    required this.specialty,
    required this.location,
    required this.isSaved,
    required this.activeTab,
    required this.showCompact,
    required this.onTab,
    required this.onBack,
    required this.onSave,
    required this.onShare,
  });

  final ContractorListing listing;
  final String name;
  final String specialty;
  final String location;
  final bool isSaved;
  final int activeTab;
  final bool showCompact;
  final ValueChanged<int> onTab;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: .98),
        boxShadow: BatshShadows.soft,
      ),
      child: Column(
        children: [
          if (showCompact)
            SizedBox(
              height: 62,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.sectionH,
                ),
                child: Row(
                  children: [
                    _SquareAction(
                      icon: Icons.arrow_forward_rounded,
                      tooltip: 'رجوع',
                      onPressed: onBack,
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    AvatarWithInitials(
                      imageUrl: listing.logoUrl,
                      name: name,
                      radius: 21,
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
                            style: BatshTypography.labelLg.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$specialty  |  $location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.labelSm.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SmallAction(
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      tooltip: isSaved
                          ? context.l10n.unsaveTooltip
                          : context.l10n.saveTooltip,
                      selected: isSaved,
                      onPressed: onSave,
                    ),
                    _SmallAction(
                      icon: Icons.share_outlined,
                      tooltip: context.l10n.share,
                      onPressed: onShare,
                    ),
                  ],
                ),
              ),
            ),
          _ReferenceTabs(activeIndex: activeTab, onSelect: onTab),
        ],
      ),
    );
  }
}

class _ReferenceTabsDelegate extends SliverPersistentHeaderDelegate {
  _ReferenceTabsDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.child,
  });

  final double minExtentValue;
  final double maxExtentValue;
  final Widget child;

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant _ReferenceTabsDelegate oldDelegate) => true;
}

class _ReferenceTabs extends StatelessWidget {
  const _ReferenceTabs({required this.activeIndex, required this.onSelect});

  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final labels = [
      'الأعمال',
      context.l10n.profileTabAbout,
      context.l10n.profileTabReviews,
    ];
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sectionH),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < labels.length; index++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: activeIndex == index,
                  label: labels[index],
                  child: InkWell(
                    onTap: () => onSelect(index),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Center(
                          child: Text(
                            labels[index],
                            style: BatshTypography.titleMd.copyWith(
                              color: activeIndex == index
                                  ? context.colorScheme.primary
                                  : context.colorScheme.onSurfaceVariant,
                              fontWeight: activeIndex == index
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 3,
                          width: activeIndex == index ? double.infinity : 0,
                          decoration: BoxDecoration(
                            color: context.colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
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

class _WorksSection extends StatelessWidget {
  const _WorksSection({
    required this.listing,
    required this.name,
    required this.projectsAsync,
    required this.onRetry,
  });

  final ContractorListing listing;
  final String name;
  final AsyncValue<List<PortfolioProject>> projectsAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sectionH,
        BatshSpacing.lg,
        BatshSpacing.sectionH,
        BatshSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: 'أعمال $name'),
          const SizedBox(height: BatshSpacing.md),
          projectsAsync.when(
            loading: () => const Column(
              children: [
                BatshShimmerBox(height: 144, borderRadius: BatshRadius.brLg),
                SizedBox(height: BatshSpacing.sm),
                BatshShimmerBox(height: 144, borderRadius: BatshRadius.brLg),
              ],
            ),
            error: (_, _) => _InlineState(
              icon: Icons.cloud_off_outlined,
              title: 'تعذر تحميل الأعمال',
              action: 'إعادة المحاولة',
              onAction: onRetry,
            ),
            data: (projects) {
              if (projects.isEmpty) {
                return const _InlineState(
                  icon: Icons.photo_library_outlined,
                  title: 'لا توجد أعمال منشورة بعد',
                );
              }
              final visible = projects.take(4).toList();
              return Column(
                children: [
                  for (var index = 0; index < visible.length; index++) ...[
                    _ReferenceProjectCard(
                      project: visible[index],
                      onTap: () => context.push(
                        Routes.homeownerProjectDetailPath(
                          listing.id,
                          visible[index].id,
                        ),
                      ),
                    ),
                    if (index != visible.length - 1)
                      const SizedBox(height: BatshSpacing.sm),
                  ],
                  if (projects.length > visible.length) ...[
                    const SizedBox(height: BatshSpacing.sm),
                    _TextAction(
                      label: 'عرض المزيد من الأعمال',
                      onPressed: () => context.push(
                        Routes.homeownerContractorPortfolioPath(listing.id),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReferenceProjectCard extends StatelessWidget {
  const _ReferenceProjectCard({required this.project, required this.onTap});

  final PortfolioProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photoCount = <String>{
      if (isDisplayableImageUrl(project.coverPhotoUrl)) project.coverPhotoUrl,
      ...project.photoUrls.where(isDisplayableImageUrl),
    }.length;
    return Semantics(
      button: true,
      label: project.title,
      child: Material(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shadowColor: BatshColors.onSurface.withValues(alpha: .12),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 146,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.md,
                      BatshSpacing.sm,
                      BatshSpacing.sm,
                      BatshSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          project.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.titleMd.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (project.category?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            project.category!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.bodyMd.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (project.location?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: BatshIconSize.sm,
                                color: context.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  project.location!.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: BatshTypography.bodySm.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: BatshSpacing.xs),
                        const Icon(
                          Icons.chevron_left_rounded,
                          size: BatshIconSize.md,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  height: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ProfileImage(
                        url: project.coverPhotoUrl,
                        name: project.title,
                        width: 440,
                        fit: BoxFit.cover,
                      ),
                      if (photoCount > 0)
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: _PhotoCountBadge(count: photoCount),
                        ),
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

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.listing,
    required this.name,
    required this.onExploreWorks,
  });

  final ContractorListing listing;
  final String name;
  final VoidCallback onExploreWorks;

  @override
  Widget build(BuildContext context) {
    final bio = listing.bio?.trim();
    final services = listing.specialties
        .map((value) => localizedSpecialtyDisplayLabel(context, value))
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
    final areas = listing.serviceAreas
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sectionH,
        0,
        BatshSpacing.sectionH,
        BatshSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: 'نبذة عن $name'),
          const SizedBox(height: BatshSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerLow,
              borderRadius: BatshRadius.brXl,
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BatshRadius.brXl,
              child: Stack(
                children: [
                  PositionedDirectional(
                    top: -28,
                    start: -34,
                    width: 150,
                    height: 150,
                    child: Opacity(
                      opacity: .22,
                      child: ShattabPattern(
                        kind: ShattabPatternKind.arches,
                        color: context.colorScheme.primary,
                        strokeWidth: .75,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(BatshSpacing.lg),
                    child: Text(
                      bio?.isNotEmpty == true
                          ? bio!
                          : 'لم تتم إضافة نبذة عن هذا المحترف بعد.',
                      style: BatshTypography.bodyLg.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.xl),
          _SectionTitle(title: 'خدماتي'),
          const SizedBox(height: BatshSpacing.sm),
          if (services.isEmpty)
            const _InlineState(
              icon: Icons.home_repair_service_outlined,
              title: 'لا توجد خدمات مضافة بعد',
            )
          else
            for (final service in services.take(4)) ...[
              _AboutRow(
                icon: specialtyIcon(
                  listing.specialties[services.indexOf(service)],
                ),
                label: service,
              ),
              const SizedBox(height: BatshSpacing.sm),
            ],
          if (services.isNotEmpty) ...[
            const SizedBox(height: BatshSpacing.lg),
            _SectionTitle(title: 'التخصصات'),
            const SizedBox(height: BatshSpacing.sm),
            Wrap(
              spacing: BatshSpacing.xs,
              runSpacing: BatshSpacing.xs,
              children: [
                for (final service in services) _SoftChip(label: service),
              ],
            ),
          ],
          const SizedBox(height: BatshSpacing.lg),
          _SectionTitle(title: 'منطقة العمل'),
          const SizedBox(height: BatshSpacing.sm),
          _AboutRow(
            icon: Icons.location_on_outlined,
            label: areas.isEmpty ? 'لم تحدد بعد' : areas.join('، '),
          ),
          const SizedBox(height: BatshSpacing.lg),
          _SectionTitle(title: 'عن الأعمال'),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            '${listing.projectsCompleted} مشروعًا مكتملًا${listing.memberSince == null ? '' : ' · عضو منذ ${listing.memberSince!.year}'}',
            style: BatshTypography.bodyLg.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BatshButton(
              label: context.l10n.exploreWork,
              style: BatshButtonStyle.ghost,
              fullWidth: false,
              icon: Icons.arrow_back_rounded,
              onPressed: onExploreWorks,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({
    required this.listing,
    required this.reviewsAsync,
    required this.onViewAll,
  });

  final ContractorListing listing;
  final AsyncValue<List<Review>> reviewsAsync;
  final VoidCallback onViewAll;

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
    final reviewCount = reviewsAsync.hasValue
        ? reviews.length
        : listing.reviewCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sectionH,
        0,
        BatshSpacing.sectionH,
        BatshSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: 'التقييمات'),
          const SizedBox(height: BatshSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerLowest,
              borderRadius: BatshRadius.brLg,
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(BatshSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          listing.rating == null
                              ? '—'
                              : listing.rating!.toStringAsFixed(1),
                          style: BatshTypography.displayMd.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        _Stars(value: listing.rating?.round() ?? 0),
                        const SizedBox(height: BatshSpacing.xs),
                        Text(
                          '($reviewCount تقييم)',
                          style: BatshTypography.bodySm.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        for (var star = 5; star >= 1; star--)
                          _RatingBar(
                            star: star,
                            count: counts[star]!,
                            maxCount: maxCount,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          Text(
            'آراء العملاء',
            style: BatshTypography.titleLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          reviewsAsync.when(
            loading: () => const BatshShimmerBox(
              height: 120,
              borderRadius: BatshRadius.brLg,
            ),
            error: (_, _) => const _InlineState(
              icon: Icons.cloud_off_outlined,
              title: 'تعذر تحميل التقييمات',
            ),
            data: (items) {
              if (items.isEmpty) {
                return const _InlineState(
                  icon: Icons.rate_review_outlined,
                  title: 'لا توجد تقييمات بعد',
                );
              }
              final visible = items.take(4).toList();
              return Column(
                children: [
                  for (var index = 0; index < visible.length; index++) ...[
                    _ReviewCard(review: visible[index]),
                    if (index != visible.length - 1)
                      const SizedBox(height: BatshSpacing.sm),
                  ],
                  if (items.length > visible.length) ...[
                    const SizedBox(height: BatshSpacing.sm),
                    _TextAction(
                      label: 'عرض كل التقييمات',
                      onPressed: onViewAll,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.star,
    required this.count,
    required this.maxCount,
  });

  final int star;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                value: maxCount == 0 ? 0 : count / maxCount,
                backgroundColor: context.colorScheme.surfaceContainerHigh,
                color: BatshColors.starGold,
              ),
            ),
          ),
          const SizedBox(width: BatshSpacing.xs),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: BatshTypography.labelSm,
            ),
          ),
        ],
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

class _IdentityStat extends StatelessWidget {
  const _IdentityStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: BatshTypography.titleLg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              Icon(icon, size: BatshIconSize.sm, color: iconColor),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
    color: context.colorScheme.outlineVariant,
  );
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surfaceContainerLowest,
      borderRadius: BatshRadius.brLg,
      elevation: 1,
      shadowColor: BatshColors.onSurface.withValues(alpha: .1),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.md,
          vertical: BatshSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: context.colorScheme.tertiary,
              size: BatshIconSize.lg,
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(child: Text(label, style: BatshTypography.bodyLg)),
            Icon(
              Icons.chevron_left_rounded,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: BatshTypography.headlineSm.copyWith(fontSize: 22),
          ),
        ),
        Container(width: 40, height: 2, color: context.colorScheme.primary),
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: BatshPressable(
        semanticLabel: label,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BatshSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: BatshTypography.labelLg.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              Icon(
                Icons.arrow_back_rounded,
                size: BatshIconSize.sm,
                color: context.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BatshRadius.brFull,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.md,
          vertical: BatshSpacing.sm,
        ),
        child: Text(label, style: BatshTypography.labelMd),
      ),
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({
    required this.icon,
    required this.title,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.lg),
        child: Column(
          children: [
            Icon(icon, color: context.colorScheme.onSurfaceVariant, size: 30),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd,
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: BatshSpacing.sm),
              BatshButton(
                label: action!,
                style: BatshButtonStyle.ghost,
                fullWidth: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        toggled: selected,
        child: Material(
          color: context.colorScheme.surfaceContainerLowest.withValues(
            alpha: .95,
          ),
          borderRadius: BatshRadius.brMd,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: .16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BatshRadius.brMd,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                icon,
                color: selected
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurface,
                size: BatshIconSize.md,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: selected
            ? context.colorScheme.primary
            : context.colorScheme.onSurface,
      ),
      constraints: const BoxConstraints(
        minWidth: BatshSpacing.minHitArea,
        minHeight: BatshSpacing.minHitArea,
      ),
      padding: EdgeInsets.zero,
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

class _PhotoCountBadge extends StatelessWidget {
  const _PhotoCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .75),
        borderRadius: BatshRadius.brSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              color: Colors.white,
              size: 15,
            ),
            const SizedBox(width: 4),
            Text(
              '$count صور',
              style: BatshTypography.labelSm.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({
    required this.url,
    required this.name,
    required this.width,
    required this.fit,
  });

  final String? url;
  final String name;
  final int width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (!isDisplayableImageUrl(url)) return BatshInitialPlate(name: name);
    return CachedNetworkImage(
      imageUrl: sizedImageUrl(url!, width: width),
      fit: fit,
      memCacheWidth: width,
      errorWidget: (_, _, _) => BatshInitialPlate(name: name),
    );
  }
}
