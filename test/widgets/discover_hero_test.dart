import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/discovery/presentation/widgets/discover_hero.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hero notification button invokes its callback', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: BatshTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: DiscoverHero(
            collapsed: false,
            searchRow: const SizedBox(height: 52),
            onNotificationTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));

    expect(tapped, isTrue);
  });
}
