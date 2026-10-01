import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/core/widgets/batsh_button.dart';
import 'package:batsh/core/widgets/batsh_text_field.dart';
import 'package:batsh/features/assistant/presentation/assistant_screen.dart';
import 'package:batsh/l10n/app_localizations.dart';

void main() {
  Widget buildScreen() => ProviderScope(
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AssistantScreen(),
    ),
  );

  testWidgets('renders the Arabic RTL assistant empty state', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
    expect(find.text('مساعد شطّب الذكي'), findsAtLeastNWidgets(1));
    expect(
      find.text('محادثتك مؤقتة، ولا يتم حفظ نص المحادثة.'),
      findsOneWidget,
    );
    expect(find.byType(BatshTextField), findsOneWidget);
    expect(find.byType(BatshButton), findsOneWidget);
  });
}
