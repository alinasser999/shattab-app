import 'package:batsh/l10n/app_localizations.dart';
import 'package:batsh/core/widgets/batsh_photo_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The viewer's whole job is that the counter agrees with the visible page and
/// that a bad initialIndex can't crash it. Both are cheap to pin down.
///
/// These use explicit `pump(duration)` rather than `pumpAndSettle()`: the image
/// placeholder is a CircularProgressIndicator that spins forever while the
/// (unreachable) test URLs never resolve, so nothing ever "settles".
void main() {
  const urls = ['https://x/1.jpg', 'https://x/2.jpg', 'https://x/3.jpg'];

  Widget host(Widget child) => MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,

    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );

  group('BatshPhotoViewer', () {
    testWidgets('counter starts at the initial index', (tester) async {
      await tester.pumpWidget(
        host(const BatshPhotoViewer(urls: urls, initialIndex: 1)),
      );

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('counter follows the page as it changes', (tester) async {
      await tester.pumpWidget(host(const BatshPhotoViewer(urls: urls)));
      expect(find.text('1 / 3'), findsOneWidget);

      // Drive the pager directly: dragging depends on RTL axis direction,
      // which is not what this test is about.
      final controller = tester
          .widget<PageView>(find.byType(PageView).first)
          .controller!;
      controller.jumpToPage(2);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('3 / 3'), findsOneWidget);
      expect(find.text('1 / 3'), findsNothing);
    });

    testWidgets('hides the counter for a single photo', (tester) async {
      await tester.pumpWidget(
        host(const BatshPhotoViewer(urls: ['https://x/only.jpg'])),
      );

      expect(find.textContaining('/'), findsNothing);
    });

    testWidgets('show() clamps an out-of-range initialIndex', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  BatshPhotoViewer.show(context, urls: urls, initialIndex: 99),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // route transition

      // Clamped to the last photo instead of throwing on an invalid page.
      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('show() is a no-op for an empty list', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BatshPhotoViewer.show(context, urls: const []),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // route transition

      expect(find.byType(BatshPhotoViewer), findsNothing);
    });
  });
}
