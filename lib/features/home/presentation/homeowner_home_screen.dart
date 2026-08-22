import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/analytics/marketplace_events.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../briefs/presentation/providers/briefs_providers.dart';
import '../../discovery/presentation/providers/discovery_providers.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../portfolio/data/portfolio_repository.dart';
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: BatshSpacing.xxl),
                child: HomeCommunityInvite(
                  onTap: () => context.go(Routes.homeownerExplore),
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
