import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import '../../../core/widgets/batsh_pattern_background.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class HomeownerShell extends StatelessWidget {
  const HomeownerShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _goToTab(int i) {
    navigationShell.goBranch(
      i,
      initialLocation: i == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: BatshPatternBackground(child: navigationShell),
      bottomNavigationBar: BatshBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _goToTab,
        items: [
          BatshBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: context.l10n.tabHome,
          ),
          BatshBottomNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: context.l10n.tabDiscover,
          ),
          BatshBottomNavItem(
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
            label: context.l10n.tabRequests,
          ),
          BatshBottomNavItem(
            icon: Icons.photo_library_outlined,
            selectedIcon: Icons.photo_library_rounded,
            label: context.l10n.tabCommunity,
          ),
          BatshBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: context.l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
