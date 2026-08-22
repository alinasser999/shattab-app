import 'package:batsh/core/cache/provider_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the window that makes back-navigation instant.
///
/// The failure this protects against is silent in both directions: too short
/// and every return to a profile refetches, which is the behaviour the helper
/// exists to remove; never closing and a homeowner who browses fifty
/// professionals keeps fifty profiles, portfolios and review lists resident for
/// the life of the process.
void main() {
  const ttl = Duration(milliseconds: 200);

  late int fetches;
  late FutureProvider<int> subject;

  setUp(() {
    fetches = 0;
    // isAutoDispose: the real providers are codegen `@riverpod`, which is
    // autoDispose; a hand-built FutureProvider is not, and without this the
    // fixture would never dispose and would pass every assertion below for
    // the wrong reason.
    subject = FutureProvider<int>(isAutoDispose: true, (ref) async {
      fetches++;
      // Mirrors the real providers: the window opens only after a successful
      // await, never before it.
      cacheFor(ref, ttl);
      return fetches;
    });
  });

  test('a re-read inside the window does not refetch', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final first = container.listen(subject, (_, _) {});
    await container.read(subject.future);
    expect(fetches, 1);

    // The screen is popped: nothing is listening any more.
    first.close();

    // Reopened straight away — the compare-two-contractors motion.
    container.listen(subject, (_, _) {});
    await container.read(subject.future);

    expect(fetches, 1, reason: 'should still be warm inside the window');
  });

  test('the value is released once the window closes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final sub = container.listen(subject, (_, _) {});
    await container.read(subject.future);
    expect(fetches, 1);
    sub.close();

    await Future<void>.delayed(ttl * 2);

    container.listen(subject, (_, _) {});
    await container.read(subject.future);

    expect(fetches, 2, reason: 'window should have expired and let it go');
  });

  // Not tested here: that a *failed* read is never cached. It holds by
  // construction — `cacheFor` is called after the awaited fetch, so a throw
  // skips it and the provider stays free to dispose and retry. Provoking it
  // through a ProviderContainer means deliberately failing a build, and
  // Riverpod surfaces that as an unhandled async error outside `listen`'s
  // error handler, which fails the test for a reason unrelated to caching.
}
