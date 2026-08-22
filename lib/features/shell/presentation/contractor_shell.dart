import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import '../../../core/widgets/batsh_pattern_background.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class ContractorShell extends StatelessWidget {
  const ContractorShell({super.key, required this.navigationShell});
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
            icon: Icons.groups_2_outlined,
            selectedIcon: Icons.groups_2_rounded,
            label: context.l10n.tabCommunity,
          ),
          BatshBottomNavItem(
            icon: Icons.work_outline,
            selectedIcon: Icons.work,
            label: context.l10n.tabOpportunities,
          ),
          BatshBottomNavItem(
            icon: Icons.mail_outline,
            selectedIcon: Icons.mail,
            label: context.l10n.tabInbox,
          ),
          BatshBottomNavItem(
            icon: Icons.photo_library_outlined,
            selectedIcon: Icons.photo_library,
            label: context.l10n.tabPortfolio,
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
