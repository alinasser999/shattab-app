import 'package:batsh/core/router/routes.dart';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/quotes/presentation/my_quotes_screen.dart';
import 'package:batsh/features/quotes/presentation/providers/quotes_providers.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('empty My Quotes CTA returns to contractor opportunities', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: Routes.contractorMyQuotes,
      routes: [
        GoRoute(
          path: Routes.contractorMyQuotes,
          builder: (_, _) => const MyQuotesScreen(),
        ),
        GoRoute(
          path: Routes.contractorDashboard,
          builder: (_, _) => const Scaffold(body: Text('opportunities-home')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [myQuotesWithBriefsProvider.overrideWith((ref) async => [])],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: BatshTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No quotes yet'), findsOneWidget);
    expect(
      find.text('Quotes you send on jobs will show up here'),
      findsOneWidget,
    );
    expect(find.text('Job Opportunities'), findsOneWidget);

    await tester.tap(find.text('Job Opportunities'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, Routes.contractorDashboard);
    expect(find.text('opportunities-home'), findsOneWidget);
  });
}
