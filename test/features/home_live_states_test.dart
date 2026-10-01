import 'dart:async';

import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/utils/connectivity.dart';
import 'package:batsh/core/widgets/shattab_experience_state.dart';
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
  testWidgets('brief loading and error stay visible before injected content', (
    tester,
  ) async {
    _setViewport(tester);
    final briefsCompleter = Completer<List<Brief>>();
    var briefAttempts = 0;

    await tester.pumpWidget(
      _homeHarness(
        briefBuilder: (ref) {
          briefAttempts++;
          if (briefAttempts == 1) return briefsCompleter.future;
          return Future.value([_brief]);
        },
        notificationsBuilder: (ref) => Stream.value(const <AppNotification>[]),
        childHorizontalInset: 14,
      ),
    );
    await tester.pump();

    expect(find.byType(ShattabExperienceSkeleton), findsOneWidget);
    expect(find.text('injected project content'), findsNothing);
    _expectHorizontalBounds(
      tester,
      find.byType(ShattabExperienceSkeleton),
      left: 24,
      width: 342,
    );

    // Fail the first attempt explicitly, then ensure the visible retry action
    // reloads briefs and only reveals the injected project after success.
    briefsCompleter.completeError(StateError('brief fixture failure'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final context = tester.element(find.byType(HomeLiveStateSection));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.homeLiveErrorTitle), findsOneWidget);
    expect(find.text(l10n.homeLiveEmptyTitle), findsNothing);
    expect(find.text('injected project content'), findsNothing);
    _expectHorizontalBounds(
      tester,
      find.byType(ShattabExperienceState),
      left: 24,
      width: 342,
    );

    await tester.tap(find.text(l10n.tryAgain));
    await tester.pumpAndSettle();

    expect(briefAttempts, 2);
    expect(find.text('injected project content'), findsOneWidget);
    expect(find.text(l10n.homeLiveErrorTitle), findsNothing);
    _expectHorizontalBounds(
      tester,
      find.byKey(const ValueKey('injected-project-content')),
      left: 14,
      width: 362,
    );
  });

  testWidgets(
    'notification loading and retry remain beside a successful injected project',
    (tester) async {
      _setViewport(tester);
      final notificationsController = StreamController<List<AppNotification>>();
      addTearDown(notificationsController.close);
      var briefAttempts = 0;
      var notificationAttempts = 0;

      await tester.pumpWidget(
        _homeHarness(
          briefBuilder: (ref) {
            briefAttempts++;
            return Future.value([_brief]);
          },
          notificationsBuilder: (ref) {
            notificationAttempts++;
            if (notificationAttempts == 1) {
              return notificationsController.stream;
            }
            return Stream.value(const <AppNotification>[]);
          },
          childHorizontalInset: 14,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('injected project content'), findsOneWidget);
      _expectHorizontalBounds(
        tester,
        find.byKey(const ValueKey('injected-project-content')),
        left: 14,
        width: 362,
      );
      final notificationSkeleton = find.byWidgetPredicate(
        (widget) => widget is ShattabExperienceSkeleton && widget.compact,
      );
      expect(notificationSkeleton, findsOneWidget);
      _expectHorizontalBounds(
        tester,
        notificationSkeleton,
        left: 24,
        width: 342,
      );

      notificationsController.addError(
        StateError('notification fixture failure'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final context = tester.element(find.byType(HomeLiveStateSection));
      final l10n = AppLocalizations.of(context)!;
      expect(find.text('injected project content'), findsOneWidget);
      expect(find.text(l10n.homeLiveErrorTitle), findsOneWidget);
      _expectHorizontalBounds(
        tester,
        find.byWidgetPredicate(
          (widget) => widget is ShattabExperienceState && widget.compact,
        ),
        left: 24,
        width: 342,
      );

      await tester.tap(find.text(l10n.tryAgain));
      await tester.pumpAndSettle();

      expect(notificationAttempts, 2);
      expect(
        briefAttempts,
        1,
        reason: 'notification retry must not reload briefs',
      );
      expect(find.text('injected project content'), findsOneWidget);
      expect(find.text(l10n.homeLiveErrorTitle), findsNothing);
      _expectHorizontalBounds(
        tester,
        find.byKey(const ValueKey('injected-project-content')),
        left: 14,
        width: 362,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ShattabExperienceSkeleton && widget.compact,
        ),
        findsNothing,
      );
    },
  );

  testWidgets('a null child inset retains the standard 24dp gutter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _homeHarness(
        briefBuilder: (ref) => Future.value([_brief]),
        notificationsBuilder: (ref) => Stream.value(const <AppNotification>[]),
      ),
    );
    await tester.pumpAndSettle();

    _expectHorizontalBounds(
      tester,
      find.byKey(const ValueKey('injected-project-content')),
      left: 24,
      width: 342,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _homeHarness({
  required Future<List<Brief>> Function(Ref) briefBuilder,
  required Stream<List<AppNotification>> Function(Ref) notificationsBuilder,
  double? childHorizontalInset,
}) {
  return ProviderScope(
    overrides: [
      myBriefsProvider.overrideWith(briefBuilder),
      notificationsProvider.overrideWith(notificationsBuilder),
      connectivityProvider.overrideWith((ref) => Stream.value(true)),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: BatshTheme.light(),
      home: Scaffold(
        body: HomeLiveStateSection(
          onOpenRequests: _noop,
          onOpenNotifications: _noop,
          onStartRequest: _noop,
          childHorizontalInset: childHorizontalInset,
          child: const SizedBox(
            key: ValueKey('injected-project-content'),
            width: double.infinity,
            height: 48,
            child: Text('injected project content'),
          ),
        ),
      ),
    ),
  );
}

final _brief = Brief(
  id: 'brief-1',
  homeownerId: 'homeowner-1',
  apartmentType: ApartmentType.oneBedroom,
  city: 'Cairo',
  workDescription: 'Paint the living room',
  photoUrls: [],
  targetSpecialties: [],
  status: BriefStatus.open,
  createdAt: DateTime.utc(2026, 9, 27),
);

void _noop() {}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void _expectHorizontalBounds(
  WidgetTester tester,
  Finder target, {
  required double left,
  required double width,
}) {
  expect(target, findsOneWidget);
  final rect = tester.getRect(target);
  expect(rect.left, closeTo(left, 0.01), reason: '$target has rect $rect');
  expect(rect.width, closeTo(width, 0.01), reason: '$target has rect $rect');
}
