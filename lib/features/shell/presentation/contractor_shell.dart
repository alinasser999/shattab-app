import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/debug/debug_flags.dart';
import '../../../core/debug/debug_role_switcher.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import '../../../core/widgets/batsh_fab.dart';
import '../../../core/widgets/batsh_pattern_background.dart';

import 'package:batsh/core/theme/theme_extension.dart';

List<BatshBottomNavItem> contractorBottomNavItems(BuildContext context) => [
  // Row children follow RTL start-to-end, so the first entry appears at the
  // right edge. This order reproduces the left-to-right screenshot sequence.
  BatshBottomNavItem(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: context.l10n.workTabAccount,
  ),
  BatshBottomNavItem(
    icon: Icons.notifications_none_outlined,
    selectedIcon: Icons.notifications_rounded,
    label: context.l10n.workTabNotifications,
  ),
  BatshBottomNavItem(
    icon: Icons.mail_outline,
    selectedIcon: Icons.mail,
    label: context.l10n.workTabMessages,
  ),
  BatshBottomNavItem(
    icon: Icons.work_outline,
    selectedIcon: Icons.work,
    label: context.l10n.workTabJobs,
  ),
  BatshBottomNavItem(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: context.l10n.workTabHome,
  ),
];

class ContractorShell extends StatelessWidget {
  const ContractorShell({
    super.key,
    required this.navigationShell,
    this.location = '',
  });

  final StatefulNavigationShell navigationShell;
  final String location;

  bool get _isOpportunityDetail =>
      location.startsWith('${Routes.contractorDashboard}/post/');

  void _goToTab(BuildContext context, int visibleIndex) {
    if (visibleIndex == 1) {
      context.push(Routes.notifications);
      return;
    }
    final branchIndex = switch (visibleIndex) {
      0 => 4,
      2 => 2,
      3 => 0,
      4 => 1,
      _ => navigationShell.currentIndex,
    };
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  int _visibleIndex() => switch (navigationShell.currentIndex) {
    0 => 3,
    1 => 4,
    2 => 2,
    // Portfolio remains reachable from Account and shares its selected state.
    3 || 4 => 0,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: BatshPatternBackground(
        child: Stack(
          children: [
            navigationShell,
            // Dev-only (compiled in with --dart-define=SHATTAB_DEBUG_TOOLS).
            if (DebugFlags.roleSwitcher) const DebugRoleSwitcherHost(),
          ],
        ),
      ),
      floatingActionButton:
          _isOpportunityDetail || navigationShell.currentIndex == 0
          ? null
          : Tooltip(
              message: context.l10n.assistantTitle,
              child: BatshFab(
                onPressed: () => context.push(Routes.contractorAssistant),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: BatshIconSize.action,
                ),
              ),
            ),
      bottomNavigationBar: _isOpportunityDetail
          ? null
          : BatshBottomNav(
              currentIndex: _visibleIndex(),
              onTap: (index) => _goToTab(context, index),
              items: contractorBottomNavItems(context),
              anchored: true,
            ),
    );
  }
}
