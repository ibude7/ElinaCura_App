import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits `true` when the device has a network path, `false` when fully offline.
/// Backed by connectivity_plus; seeds with the current state, then follows
/// live changes.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  try {
    yield online(await connectivity.checkConnectivity());
  } catch (_) {
    yield true; // assume online if the platform check fails
  }
  yield* connectivity.onConnectivityChanged.map(online);
});
