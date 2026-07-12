import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';

class HomeownerShell extends StatelessWidget {
  const HomeownerShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _goToTab(int i) {
    navigationShell.goBranch(i,
        initialLocation: i == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BatshColors.background,
      body: navigationShell,
      bottomNavigationBar: BatshBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _goToTab,
        items: [
          BatshBottomNavItem(
            icon: Icons.rocket_launch_outlined,
            selectedIcon: Icons.rocket_launch,
            label: S.tabExplore,
          ),
          BatshBottomNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: S.tabDiscover,
          ),
          BatshBottomNavItem(
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
            label: S.tabRequests,
          ),
          BatshBottomNavItem(
            icon: Icons.bookmark_outline,
            selectedIcon: Icons.bookmark,
            label: S.tabSaved,
          ),
          BatshBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: S.tabProfile,
          ),
        ],
      ),
    );
  }
}
