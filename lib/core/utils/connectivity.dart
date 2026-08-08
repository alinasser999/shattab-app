import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity.g.dart';

/// Whether the device currently has *a* network interface up.
///
/// This answers "is there any point retrying", not "is the server reachable" —
/// a phone on Egyptian mobile data can hold a connection the whole way through
/// a request that still fails. `ErrorMapper` stays the thing that classifies
/// what actually went wrong; this exists only so a failed screen can notice the
/// moment retrying became worthwhile again.
///
/// `keepAlive` because this is one platform-channel subscription for the whole
/// process and every error surface in the app watches it.
@Riverpod(keepAlive: true)
Stream<bool> connectivity(Ref ref) async* {
  final connectivity = Connectivity();

  bool online(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  // Emit the current state first. Without this the stream stays empty until the
  // radio next changes, so a screen opened while offline would never learn it
  // was offline, and one opened online would sit at `loading` forever.
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online);
}
