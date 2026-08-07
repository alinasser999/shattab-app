import 'package:batsh/core/widgets/batsh_section_header.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exposes and invokes a view-all action', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BatshSectionHeader(
            title: 'الأعلى تقييمًا',
            trailing: TextButton(
              onPressed: () => tapped = true,
              child: const Text('عرض الكل'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('عرض الكل'), findsOneWidget);
    await tester.tap(find.text('عرض الكل'));
    expect(tapped, isTrue);
  });
}
