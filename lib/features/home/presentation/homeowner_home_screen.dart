import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/analytics/marketplace_events.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../../core/widgets/shattab_experience_state.dart';
import '../../../core/widgets/shattab_pattern.dart';
import '../../briefs/presentation/providers/briefs_providers.dart';
import '../../discovery/domain/contractor_listing.dart';
import '../../discovery/presentation/providers/discovery_providers.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_live_states.dart';
import 'widgets/home_shortcuts.dart';
import 'widgets/home_showcase.dart';
import 'widgets/home_start_journey.dart';
import 'widgets/home_trust_sections.dart';

/// The homeowner's landing surface.
///
/// This page owns activation and current progress. The Professionals tab owns
/// searching, filtering, ranking, and catalogue browsing, so the two tabs no
/// longer compete for the same job.
class HomeownerHomeScreen extends ConsumerStatefulWidget {
  const HomeownerHomeScreen({super.key});

  @override
  ConsumerState<HomeownerHomeScreen> createState() =>
      _HomeownerHomeScreenState();
}

class _HomeownerHomeScreenState extends ConsumerState<HomeownerHomeScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(AppAnalytics.track(MarketplaceEvents.homeViewed));
  }

  @override
  Widget build(BuildContext context) {
    final profileCity = ref.watch(homeownerProfileProvider).value?.city;

    return BatshScaffold(
      showAppBar: false,
      padding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myBriefsProvider);
          ref.invalidate(notificationsProvider);
          ref.invalidate(recentProjectsProvider);
          ref.invalidate(topRatedProfessionalsProvider);
          await ref.read(myBriefsProvider.future);
        },
        child: CustomScrollView(
          key: const PageStorageKey<String>('homeowner-home-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HomeHero(
                locationLabel: profileCity,
                unreadCount: ref.watch(unreadNotificationsProvider),
                showDiscoveryControls: false,
                onLocationTap: () => context.go(Routes.homeownerDiscover),
                onNotificationTap: () => context.push(Routes.notifications),
                onMenuTap: () => context.push(Routes.homeownerSettings),
              ),
            ),
            SliverToBoxAdapter(
              child: HomeStartJourney(
                onDiscover: () => context.go(Routes.homeownerDiscover),
                onRequestQuote: () => context.push(Routes.homeownerNewPost),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: BatshSpacing.xl),
                child: HomeLiveStateSection(
                  onOpenRequests: () => context.go(Routes.homeownerRequests),
                  onOpenNotifications: () => context.push(Routes.notifications),
                  onStartRequest: () => context.push(Routes.homeownerNewPost),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: BatshSpacing.xxl),
                child: HomeServiceCategories(
                  onSelect: (specialty) {
                    ref
                        .read(discoveryFiltersControllerProvider.notifier)
                        .setSpecialty(specialty);
                    context.go(Routes.homeownerDiscover);
                  },
                  onViewAll: () => context.go(Routes.homeownerDiscover),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: BatshSpacing.xxl),
                child: _HomeFeaturedSection(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: BatshSpacing.xxl),
                child: HomeProjectsRail(
                  onViewAll: () => context.push(Routes.homeownerCompletedWork),
                  onOpenProject: (contractorId, projectId) => context.push(
                    Routes.homeownerProjectDetailPath(contractorId, projectId),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: BatshSpacing.xxl),
                child: HomeProcessSection(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: BatshSpacing.xxl),
                child: HomeCommunityInvite(
                  onTap: () => context.go(Routes.homeownerExplore),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: BatshSpacing.xxl),
                child: HomeClosingCta(
                  onTap: () => context.push(Routes.homeownerNewPost),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    BatshBottomNav.contentBottomInset(context) +
                    BatshSpacing.ml,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One professional, argued for — wired to the live catalogue.
///
/// The first reviewed professional from the rating-ranked page carries the
/// card. The section stays out of the way until it has something honest to
/// show: hidden while loading, on error, and when the catalogue is still
/// empty; a quiet "soon" state appears only when contractors exist but none
/// carry reviews yet, because that difference is exactly what a new
/// marketplace's homeowner is wondering about.
class _HomeFeaturedSection extends ConsumerStatefulWidget {
  const _HomeFeaturedSection();

  @override
  ConsumerState<_HomeFeaturedSection> createState() =>
      _HomeFeaturedSectionState();
}

class _HomeFeaturedSectionState extends ConsumerState<_HomeFeaturedSection> {
  /// Ids with an in-flight toggle. Mirrors the discover tab's optimistic
  /// pattern: the heart flips immediately, a failure rolls it back with a
  /// snack, and a double-tap while the write is in flight is a no-op.
  final Set<String> _optimisticToggled = {};

  ContractorListing? _pick(List<ContractorListing> listings) {
    for (final listing in listings) {
      if (listing.reviewCount > 0) return listing;
    }
    return null;
  }

  Future<void> _toggleSaved(ContractorListing listing) async {
    if (_optimisticToggled.contains(listing.id)) return;
    setState(() => _optimisticToggled.add(listing.id));
    try {
      await ref.read(savedControllerProvider.notifier).toggle(listing.id);
      if (mounted) setState(() => _optimisticToggled.remove(listing.id));
    } catch (error) {
      if (!mounted) return;
      setState(() => _optimisticToggled.remove(listing.id));
      BatshSnack.error(context, ErrorMapper.map(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topAsync = ref.watch(topRatedProfessionalsProvider);
    final listings = topAsync.value;
    final listing = listings == null ? null : _pick(listings);

    // Loading, failed fetch, or a catalogue with nobody in it yet: the home
    // page simply continues to its next section rather than advertising a
    // shelf that has nothing on it.
    Widget content = const SizedBox.shrink();
    if (!topAsync.isLoading && !topAsync.hasError && listings != null) {
      if (listings.isNotEmpty && listing == null) {
        // Contractors exist, none reviewed yet. This is the one empty case
        // worth a sentence: it explains why the shelf is bare and what will
        // fill it.
        content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: homeGutter),
          child: ShattabExperienceState(
            icon: Icons.auto_awesome,
            title: context.l10n.homeFeaturedEmptyTitle,
            message: context.l10n.homeFeaturedEmptyMessage,
            compact: true,
            pattern: ShattabPatternKind.terrazzo,
          ),
        );
      } else if (listing != null) {
        content = HomeFeaturedProfessionalCard(
          listing: listing,
          isSaved: _isSaved(listing),
          onToggleSave: () => _toggleSaved(listing),
          onOpenProfile: () =>
              context.push(Routes.homeownerContractorProfilePath(listing.id)),
        );
      }
    }

    // One authored motion moment: the section crossfades when its data
    // lands, instead of popping. Reduced-motion collapses the duration.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: homeGutter),
          child: Semantics(
            header: true,
            child: Text(
              context.l10n.featuredProfessional,
              style: BatshTypography.headlineSm.copyWith(
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: BatshSpacing.xs),
        AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : BatshMotion.normal,
          switchInCurve: BatshMotion.easeOut,
          child: KeyedSubtree(
            key: ValueKey(listing != null ? 'card:${listing.id}' : '$content'),
            child: content,
          ),
        ),
      ],
    );
  }

  bool _isSaved(ContractorListing listing) {
    final base = (ref.watch(savedContractorIdsProvider).value ?? {}).contains(
      listing.id,
    );
    final optimistic = _optimisticToggled.contains(listing.id);
    return optimistic ? !base : base;
  }
}
