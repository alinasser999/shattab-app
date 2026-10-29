import 'package:flutter/services.dart';
import '../../../core/widgets/batsh_quick_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';

class ContractorShell extends StatelessWidget {
  const ContractorShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _goToTab(int i) {
    navigationShell.goBranch(i,
        initialLocation: i == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BatshColors.background,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              BatshQuickActionsSheet.show(context, isContractor: true),
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              BatshQuickActionsSheet.show(context, isContractor: true),
        },
        child: Focus(
          autofocus: true,
          child: navigationShell,
        ),
      ),
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
            icon: Icons.work_outline,
            selectedIcon: Icons.work,
            label: S.tabOpportunities,
          ),
          BatshBottomNavItem(
            icon: Icons.mail_outline,
            selectedIcon: Icons.mail,
            label: S.tabInbox,
          ),
          BatshBottomNavItem(
            icon: Icons.photo_library_outlined,
            selectedIcon: Icons.photo_library,
            label: S.tabPortfolio,
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
