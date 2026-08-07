import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/batsh_pressable.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../discovery/presentation/widgets/discover_hero.dart';
import '../../discovery/presentation/widgets/recent_work_rail.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';

/// A small homeowner landing surface for the shell's real home destination.
/// Discovery remains the focused professional catalogue; this page gives the
/// other primary destinations a clear starting point without duplicating it.
class HomeownerHomeScreen extends ConsumerWidget {
  const HomeownerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(homeownerProfileProvider).value?.city;

    return BatshScaffold(
      showAppBar: false,
      padding: EdgeInsets.zero,
      body: CustomScrollView(
        key: const PageStorageKey<String>('homeowner-home-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: DiscoverHero(
              collapsed: false,
              locationLabel: city,
              unreadCount: ref.watch(unreadNotificationsProvider),
              onNotificationTap: () => context.push(Routes.notifications),
              searchRow: _DiscoverLink(
                onTap: () => context.go(Routes.homeownerDiscover),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.marginMobile,
              BatshSpacing.lg,
              BatshSpacing.marginMobile,
              BatshSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                context.l10n.quickActionsTitle,
                textAlign: TextAlign.right,
                style: BatshTypography.titleLg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.marginMobile,
            ),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _HomeAction(
                  icon: Icons.explore_outlined,
                  label: context.l10n.discoverContractors,
                  onTap: () => context.go(Routes.homeownerDiscover),
                ),
                _HomeAction(
                  icon: Icons.assignment_outlined,
                  label: context.l10n.myRequests,
                  onTap: () => context.go(Routes.homeownerRequests),
                ),
                _HomeAction(
                  icon: Icons.bookmark_outline,
                  label: context.l10n.mySaved,
                  onTap: () => context.go(Routes.homeownerSaved),
                ),
                _HomeAction(
                  icon: Icons.photo_library_outlined,
                  label: context.l10n.exploreTitle,
                  onTap: () => context.go(Routes.homeownerExplore),
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: BatshSpacing.sm,
                mainAxisSpacing: BatshSpacing.sm,
                mainAxisExtent: 112,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: RecentWorkRail()),
          SliverToBoxAdapter(
            child: SizedBox(height: BatshBottomNav.contentBottomInset(context)),
          ),
        ],
      ),
    );
  }
}

class _DiscoverLink extends StatelessWidget {
  const _DiscoverLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: context.l10n.discoverContractors,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brFull,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          boxShadow: BatshShadows.floating,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, color: context.colorScheme.primary),
            const SizedBox(width: BatshSpacing.xs),
            Text(
              context.l10n.discoverContractors,
              style: BatshTypography.labelLg.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
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
        padding: const EdgeInsets.all(BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brCard,
          border: Border.all(color: context.colorScheme.outlineVariant),
          boxShadow: BatshShadows.soft,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: context.colorScheme.primary),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelLg.copyWith(
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
