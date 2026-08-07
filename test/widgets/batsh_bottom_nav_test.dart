import 'package:batsh/core/widgets/batsh_bottom_nav.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selected destination is exposed to assistive technology', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BatshBottomNav(
            currentIndex: 1,
            onTap: (_) {},
            items: const [
              BatshBottomNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
              ),
              BatshBottomNavItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: 'Professionals',
              ),
            ],
          ),
        ),
      ),
    );

    final finder = find.bySemanticsLabel('Professionals');
    expect(finder, findsOneWidget);
    final node = tester.getSemantics(finder);
    expect(
      node.getSemanticsData().flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    expect(
      node.getSemanticsData().actions & SemanticsAction.tap.index,
      isNonZero,
    );
    semanticsHandle.dispose();
  });

  testWidgets('Arabic labels remain readable at 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BatshBottomNav(
            currentIndex: 1,
            onTap: (_) {},
            items: const [
              BatshBottomNavItem(
                icon: Icons.photo_library_outlined,
                selectedIcon: Icons.photo_library,
                label: 'أعمال',
              ),
              BatshBottomNavItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: 'المحترفين',
              ),
              BatshBottomNavItem(
                icon: Icons.assignment_outlined,
                selectedIcon: Icons.assignment,
                label: 'طلباتي',
              ),
              BatshBottomNavItem(
                icon: Icons.bookmark_outline,
                selectedIcon: Icons.bookmark,
                label: 'المحفوظات',
              ),
              BatshBottomNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );

    final savedLabel = tester.renderObject<RenderParagraph>(
      find.text('المحفوظات'),
    );
    expect(savedLabel.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
