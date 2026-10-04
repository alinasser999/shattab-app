import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/debug/debug_flags.dart';
import '../../../core/debug/debug_role_switcher.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/professional_reference_navigation.dart';
import '../../../core/widgets/batsh_fab.dart';
import '../../../core/router/routes.dart';
import '../../discovery/domain/professional_reference_fixture.dart';

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
    final shellContext = context;
    return Scaffold(
      backgroundColor: shellContext.colorScheme.surface,
      body: Stack(
        children: [
          navigationShell,
          if (!isHome &&
              !professionalReferenceEnabled &&
              DebugFlags.roleSwitcher)
            const DebugRoleSwitcherHost(),
        ],
      ),
      floatingActionButton: isHome || _immersiveProfessionalsSurface
          ? null
          : Tooltip(
              message: shellContext.l10n.assistantTitle,
              child: BatshFab(
                onPressed: () => shellContext.push(Routes.homeownerAssistant),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: BatshIconSize.action,
                ),
              ),
            ),
      bottomNavigationBar: ProfessionalReferenceNavigation(
        onTap: _goToTab,
        index: navigationShell.currentIndex,
        readable: true,
        labels: [
          shellContext.l10n.tabHome,
          shellContext.l10n.tabDiscover,
          shellContext.l10n.tabRequests,
          shellContext.l10n.tabCommunity,
          shellContext.l10n.tabProfile,
        ],
      ),
    );
  }
}
