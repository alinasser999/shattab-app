import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/debug/debug_flags.dart';
import '../../../core/debug/debug_role_switcher.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import '../../../core/widgets/batsh_fab.dart';
import '../../../core/widgets/batsh_pattern_background.dart';
import '../../../core/router/routes.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class HomeownerShell extends StatelessWidget {
  const HomeownerShell({
    super.key,
    required this.navigationShell,
    required this.location,
  });

  final StatefulNavigationShell navigationShell;
  final String location;

  bool get _immersiveProfessionalsSurface =>
      location == Routes.homeownerDiscover ||
      location.startsWith('/h/discover/');

  bool get _homeSurface => location == Routes.homeownerHome;

  void _goToTab(int i) {
    navigationShell.goBranch(
      i,
      initialLocation: i == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _homeSurface;
    return Theme(
      data: _homeTheme(Theme.of(context), enabled: isHome),
      child: Builder(
        builder: (shellContext) => Scaffold(
          backgroundColor: shellContext.colorScheme.surface,
          body: isHome
              ? navigationShell
              : BatshPatternBackground(
                  child: Stack(
                    children: [
                      navigationShell,
                      // Keep the dev-only role switcher available off home.
                      if (DebugFlags.roleSwitcher)
                        const DebugRoleSwitcherHost(),
                    ],
                  ),
                ),
          floatingActionButton: isHome
              ? null
              : Tooltip(
                  message: shellContext.l10n.assistantTitle,
                  child: BatshFab(
                    onPressed: () =>
                        shellContext.push(Routes.homeownerAssistant),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: BatshIconSize.action,
                    ),
                  ),
                ),
          bottomNavigationBar: _immersiveProfessionalsSurface
              ? null
              : BatshBottomNav(
                  currentIndex: navigationShell.currentIndex,
                  onTap: _goToTab,
                  anchored: isHome,
                  fontFamily: isHome ? 'Tajawal' : null,
                  backgroundColor:
                      shellContext.colorScheme.surfaceContainerLowest,
                  items: [
                    BatshBottomNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: shellContext.l10n.tabHome,
                    ),
                    BatshBottomNavItem(
                      icon: Icons.explore_outlined,
                      selectedIcon: Icons.explore,
                      label: shellContext.l10n.tabDiscover,
                    ),
                    BatshBottomNavItem(
                      icon: Icons.assignment_outlined,
                      selectedIcon: Icons.assignment,
                      label: shellContext.l10n.tabRequests,
                    ),
                    BatshBottomNavItem(
                      icon: Icons.photo_library_outlined,
                      selectedIcon: Icons.photo_library_rounded,
                      label: shellContext.l10n.tabCommunity,
                    ),
                    BatshBottomNavItem(
                      icon: Icons.person_outline,
                      selectedIcon: Icons.person,
                      label: shellContext.l10n.tabProfile,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

ThemeData _homeTheme(ThemeData theme, {required bool enabled}) {
  if (!enabled) return theme;
  final colors = theme.brightness == Brightness.light
      ? theme.colorScheme.copyWith(
          surface: BatshColors.homeCanvas,
          onSurface: BatshColors.homeInk,
          onSurfaceVariant: BatshColors.homeMuted,
          primary: BatshColors.homeAction,
          onPrimary: BatshColors.homeOnAction,
          primaryContainer: BatshColors.homeSelectedSurface,
          onPrimaryContainer: BatshColors.homeAction,
          secondaryContainer: BatshColors.homeSuccessSurface,
          onSecondaryContainer: BatshColors.homeSuccess,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: BatshColors.homeSoftSurface,
          surfaceContainer: BatshColors.homeSoftSurface,
          surfaceContainerHigh: BatshColors.homeSoftSurface,
          surfaceContainerHighest: BatshColors.homeSoftSurface,
          outline: BatshColors.homeMuted,
          outlineVariant: BatshColors.homeBorder,
        )
      : theme.colorScheme;
  return theme.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    textTheme: theme.textTheme.apply(fontFamily: 'Tajawal'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Tajawal'),
  );
}
