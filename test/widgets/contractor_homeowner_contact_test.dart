import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/widgets/contact_buttons.dart';
import 'package:batsh/features/auth/presentation/providers/homeowner_contact_provider.dart';
import 'package:batsh/features/briefs/presentation/contractor/widgets/contractor_homeowner_contact.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required HomeownerContact? contact}) => ProviderScope(
  overrides: [
    homeownerContactForBriefProvider.overrideWith(
      (ref, briefId) async => contact,
    ),
  ],
  child: MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: BatshTheme.light(),
    home: const Scaffold(body: ContractorHomeownerContact(briefId: 'brief-1')),
  ),
);

void main() {
  testWidgets('unauthorized RPC result hides phone and contact actions', (
    tester,
  ) async {
    await tester.pumpWidget(_app(contact: null));
    await tester.pumpAndSettle();

    expect(find.text('بيانات التواصل محمية'), findsOneWidget);
    expect(find.byType(WhatsAppButton), findsNothing);
    expect(find.byType(CallButton), findsNothing);
    expect(find.textContaining('01001234567'), findsNothing);
  });

  testWidgets('authorized RPC result reveals phone and contact actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(contact: (name: 'صاحب الطلب', phone: '+201001234567')),
    );
    await tester.pumpAndSettle();

    expect(find.text('صاحب الطلب'), findsOneWidget);
    expect(find.byType(WhatsAppButton), findsOneWidget);
    expect(find.byType(CallButton), findsOneWidget);
    expect(find.text('بيانات التواصل محمية'), findsNothing);
  });
}
