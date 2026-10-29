import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:batsh/core/theme/batsh_radius.dart';
import 'package:batsh/core/theme/batsh_typography.dart';
import 'package:batsh/core/widgets/batsh_shimmer.dart';
import 'package:batsh/core/widgets/batsh_undo_toast.dart';
import 'package:batsh/core/widgets/batsh_quick_actions_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  group('Pattern 16: Tabular Figures', () {
    test('tabular extension applies FontFeature.tabularFigures()', () {
      const baseStyle = TextStyle(fontSize: 14);
      final style = baseStyle.tabular;
      expect(style.fontFeatures, isNotNull);
      expect(
        style.fontFeatures!.any(
          (f) => f.feature == const FontFeature.tabularFigures().feature,
        ),
        isTrue,
      );
    });

    test('BatshTypography.tabular helper wraps style properly', () {
      const baseStyle = TextStyle(fontSize: 20);
      final style = BatshTypography.tabular(baseStyle);
      expect(
        style.fontFeatures!.any(
          (f) => f.feature == const FontFeature.tabularFigures().feature,
        ),
        isTrue,
      );
    });
  });

  group('Pattern 18: Continuous Corners', () {
    test('BatshRadius provides ContinuousRectangleBorder shapes', () {
      final shape = BatshRadius.shapeLg;
      expect(shape, isA<ContinuousRectangleBorder>());
      final border = shape as ContinuousRectangleBorder;
      expect(border.borderRadius.resolve(TextDirection.rtl).topLeft.x, greaterThan(0));
    });
  });

  group('Pattern 1 & 11: Skeleton Loaders & Reduced Motion', () {
    testWidgets('BatshShimmerBox renders without infinite loop when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: BatshShimmerBox(width: 100, height: 20),
          ),
        ),
      );

      expect(find.byType(BatshShimmerBox), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      // Does not throw animation or ticker assertion errors
    });
  });

  group('Pattern 5: Undo Toast', () {
    testWidgets('BatshUndoToast triggers onUndo callback when action pressed',
        (tester) async {
      var undoFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BatshUndoToast.show(
                    context,
                    message: 'تم الحذف',
                    undoLabel: 'تراجع',
                    onUndo: () => undoFired = true,
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump(); // Start SnackBar entrance
      await tester.pump(const Duration(milliseconds: 300)); // Finish entrance

      expect(find.text('تم الحذف'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);

      await tester.tap(find.text('تراجع'));
      await tester.pump();

      expect(undoFired, isTrue);
    });
  });

  group('Pattern 3 & 4: Quick Actions Sheet', () {
    testWidgets('BatshQuickActionsSheet renders Homeowner actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatshQuickActionsSheet(isContractor: false),
          ),
        ),
      );

      expect(find.text('إجراءات سريعة'), findsOneWidget);
      expect(find.text('نشر طلب تشطيب جديد'), findsOneWidget);
      expect(find.text('البحث عن محترفين'), findsOneWidget);
      expect(find.text('طلباتي والعروض'), findsOneWidget);
      expect(find.text('المحترفون المحفوظون'), findsOneWidget);
    });

    testWidgets('BatshQuickActionsSheet renders Contractor actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatshQuickActionsSheet(isContractor: true),
          ),
        ),
      );

      expect(find.text('إجراءات سريعة'), findsOneWidget);
      expect(find.text('إضافة مشروع جديد'), findsOneWidget);
      expect(find.text('تصفح فرص العمل'), findsOneWidget);
      expect(find.text('العروض المرسلة'), findsOneWidget);
      expect(find.text('معرض أعمالي'), findsOneWidget);
    });
  });
}
