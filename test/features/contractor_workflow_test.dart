import 'package:batsh/core/router/routes.dart';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/shell/presentation/contractor_shell.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('contractor workflow opens on opportunities before community', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late GoRouter router;
    router = GoRouter(
      initialLocation: Routes.contractorDashboard,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              ContractorShell(navigationShell: navigationShell),
          branches: [
            _branch(Routes.contractorDashboard, 'opportunities'),
            _branch(Routes.contractorExplore, 'community'),
            _branch(Routes.contractorInbox, 'inbox'),
            _branch(Routes.contractorPortfolio, 'portfolio'),
            _branch(Routes.contractorProfile, 'profile'),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: BatshTheme.light(),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('opportunities')), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);

    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, Routes.contractorExplore);
    expect(find.byKey(const ValueKey('community')), findsOneWidget);
  });

  test('contractor deep links keep the intended workflow paths', () {
    expect(
      Routes.contractorPostDetailPath('post-1'),
      '/c/dashboard/post/post-1',
    );
    expect(
      Routes.contractorRequestDetailPath('request-1'),
      '/c/inbox/request-1',
    );
    expect(
      Routes.contractorPortfolioEditPath('project-1'),
      '/c/portfolio/project-1/edit',
    );
  });
}

StatefulShellBranch _branch(String path, String key) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (_, _) => ColoredBox(
        color: Colors.transparent,
        child: Center(child: Text(key, key: ValueKey(key))),
      ),
    ),
  ],
);
