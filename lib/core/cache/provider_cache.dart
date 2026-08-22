import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps an autoDispose provider's value in memory for [ttl] after its last
/// listener goes away.
///
/// The problem this solves is navigation, not bandwidth. A homeowner comparing
/// professionals opens one, reads, goes back, opens the next, returns to the
/// first — and every one of those returns tore the provider down on pop and
/// refetched the profile, the portfolio and the reviews from scratch, showing
/// three skeletons for a screen that was on-device a second earlier.
///
/// Both alternatives are worse. A plain `@Riverpod(keepAlive: true)` on a
/// *family* provider never releases: browse fifty contractors and fifty
/// profiles, portfolios and review lists stay resident for the life of the
/// process. Doing nothing keeps the refetch. A window buys back-navigation its
/// instant return and still lets the memory go.
///
/// Call this **after** the awaited fetch, never before. A provider that threw
/// must not have its failure pinned, or every retry inside the window would
/// hand back the same cached error instead of trying again.
///
/// ```dart
/// @riverpod
/// Future<Foo> foo(Ref ref, String id) async {
///   final foo = await ref.watch(repoProvider).fetch(id);
///   cacheFor(ref, cacheWindow);
///   return foo;
/// }
/// ```
void cacheFor(Ref ref, Duration ttl) {
  final link = ref.keepAlive();
  final timer = Timer(ttl, link.close);
  // Invalidation — a pull-to-refresh, a submitted review — disposes the
  // provider while the timer is still pending. Without this the timer outlives
  // it and fires against a closed link.
  ref.onDispose(timer.cancel);
}

/// How long a read stays warm once nothing is watching it.
///
/// Long enough to cover the back-and-forth of comparing professionals, short
/// enough that someone returning minutes later still sees a current rating and
/// a current portfolio. Reads that must always be fresh — the discover rail,
/// notifications — deliberately do not use this.
const Duration cacheWindow = Duration(minutes: 5);
