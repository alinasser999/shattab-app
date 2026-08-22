import 'package:batsh/core/widgets/batsh_shimmer.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget appWith(Widget child) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('notification loading uses shaped skeleton rows', (tester) async {
    await tester.pumpWidget(appWith(const BatshNotificationSkeleton(count: 2)));
    await tester.pump();

    expect(find.byType(BatshShimmerBox), findsNWidgets(8));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('pagination loading uses a content-shaped footer', (
    tester,
  ) async {
    await tester.pumpWidget(appWith(const BatshPaginationSkeleton()));
    await tester.pump();

    expect(find.byType(BatshShimmerBox), findsNWidgets(3));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
