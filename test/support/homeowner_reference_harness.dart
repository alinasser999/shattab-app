import 'package:batsh/features/home/domain/homeowner_reference_fixture.dart';
import 'package:batsh/main_homeowner_reference.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local anonymous client only: no environment, persisted session or production
/// startup. Screen providers use the same in-memory runtime-review overrides.
Future<void> initializeHomeownerTestClient() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  for (final family in ['Tajawal', 'IBM Plex Sans Arabic']) {
    final loader = FontLoader(family);
    final prefix = family == 'Tajawal' ? 'Tajawal' : 'IBMPlexSansArabic';
    for (final weight
        in family == 'Tajawal'
            ? [400, 500, 700, 800, 900]
            : [400, 500, 600, 700]) {
      loader.addFont(rootBundle.load('assets/fonts/$prefix-$weight.ttf'));
    }
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  await Supabase.initialize(
    url: 'http://127.0.0.1:54321',
    anonKey: 'homeowner-test-local-placeholder',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: false,
      detectSessionInUri: false,
      localStorage: EmptyLocalStorage(),
    ),
  );
}

Future<ProviderContainer> pumpHomeownerReference(
  WidgetTester tester, {
  String query = 'scenario=noactive',
  Size size = const Size(390, 844),
  List<Override> extraOverrides = const [],
  bool settle = true,
  bool disposeInTearDown = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final scenario = HomeownerReferenceScenario.fromUri(
    Uri.parse('http://localhost/?$query'),
  );
  final replacements = extraOverrides.map((item) => item.origin).toSet();
  final container = ProviderContainer(
    overrides: [
      ...scenario
          .buildProviderOverrides(Supabase.instance.client)
          .where((item) => !replacements.contains(item.origin)),
      ...extraOverrides,
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: HomeownerReferenceApp(key: UniqueKey(), scenario: scenario),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    if (disposeInTearDown) container.dispose();
  });
  return container;
}
