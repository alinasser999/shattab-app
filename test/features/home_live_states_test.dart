import 'dart:async';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/utils/connectivity.dart';
import 'package:batsh/features/briefs/domain/brief.dart';
import 'package:batsh/features/briefs/presentation/providers/briefs_providers.dart';
import 'package:batsh/features/home/presentation/widgets/home_live_states.dart';
import 'package:batsh/features/notifications/domain/app_notification.dart';
import 'package:batsh/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('brief loading/error are distinct and retry reveals real child', (
    tester,
  ) async {
    final pending = Completer<List<Brief>>();
    var attempts = 0;
    await _pump(
      tester,
      briefs: (_) => ++attempts == 1 ? pending.future : Future.value([_brief]),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('project'), findsNothing);
    pending.completeError(StateError('local failure'));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeLiveStateSection)),
    )!;
    expect(find.text(l10n.homeLiveErrorTitle), findsOneWidget);
    expect(find.text(l10n.homeLiveEmptyTitle), findsNothing);
    expect(find.text(l10n.helpSupport), findsOneWidget);
    await tester.tap(find.text(l10n.tryAgain));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('project'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'notification retry remains beside project and does not reload briefs',
    (tester) async {
      final pending = StreamController<List<AppNotification>>();
      addTearDown(pending.close);
      var attempts = 0;
      var briefAttempts = 0;
      await _pump(
        tester,
        briefs: (_) async {
          briefAttempts++;
          return [_brief];
        },
        notifications: (_) =>
            ++attempts == 1 ? pending.stream : Stream.value([]),
      );
      await tester.pump();
      expect(find.text('project'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      pending.addError(StateError('local notification error'));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(HomeLiveStateSection)),
      )!;
      expect(find.text(l10n.homeLiveErrorTitle), findsOneWidget);
      expect(find.text('project'), findsOneWidget);
      await tester.tap(find.text(l10n.tryAgain));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(briefAttempts, 1);
      expect(find.text('project'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final notificationState in ['loading', 'error', 'empty', 'success']) {
    testWidgets(
      'no-current start action coexists with notifications: $notificationState',
      (tester) async {
        var starts = 0;
        final stream = switch (notificationState) {
          'loading' => StreamController<List<AppNotification>>().stream,
          'error' => Stream<List<AppNotification>>.error(
            StateError('local failure'),
          ),
          'success' => Stream.value([
            AppNotification(
              id: 'n',
              kind: 'new_quote',
              titleKey: 'notificationNewQuoteTitle',
              bodyKey: 'notificationNewQuoteBody',
              createdAt: DateTime.utc(2026),
            ),
          ]),
          _ => Stream.value(<AppNotification>[]),
        };
        await _pump(
          tester,
          briefs: (_) async => [],
          notifications: (_) => stream,
          child: false,
          onStart: () => starts++,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        final l10n = AppLocalizations.of(
          tester.element(find.byType(HomeLiveStateSection)),
        )!;
        expect(find.text(l10n.homeLiveStartAction), findsOneWidget);
        await tester.tap(find.text(l10n.homeLiveStartAction));
        await tester.pump();
        expect(starts, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('shared default child gutter is16 logical pixels', (
    tester,
  ) async {
    await _pump(tester, briefs: (_) async => [_brief]);
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.text('project'));
    expect(rect.left, 16);
    expect(rect.width, 358);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Future<List<Brief>> Function(Ref) briefs,
  Stream<List<AppNotification>> Function(Ref)? notifications,
  bool child = true,
  VoidCallback? onStart,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myBriefsProvider.overrideWith(briefs),
        notificationsProvider.overrideWith(
          notifications ?? (_) => Stream.value([]),
        ),
        connectivityProvider.overrideWith((_) => Stream.value(true)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: BatshTheme.light(),
        home: Scaffold(
          body: HomeLiveStateSection(
            onOpenRequests: () {},
            onOpenNotifications: () {},
            onStartRequest: onStart ?? () {},
            child: child ? const Text('project') : null,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

final _brief = Brief(
  id: 'b',
  homeownerId: 'h',
  apartmentType: ApartmentType.oneBedroom,
  city: 'Cairo',
  workDescription: 'Local project',
  photoUrls: [],
  targetSpecialties: [],
  status: BriefStatus.open,
  createdAt: DateTime.utc(2026),
);
