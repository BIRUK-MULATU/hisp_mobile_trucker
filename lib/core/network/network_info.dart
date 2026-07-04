import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity contract used by the offline layer (e.g. the sync
/// engine) to decide when to push queued writes or refresh caches.
///
/// Repositories themselves don't need this — they rely on the API
/// client throwing [NetworkException] and then fall back to the
/// local store.
abstract class NetworkInfo {
  Future<bool> get isConnected;

  /// Emits whenever connectivity changes; used to trigger auto-sync.
  Stream<bool> get onConnectivityChanged;
}

/// Real connectivity detection backed by connectivity_plus.
class ConnectivityNetworkInfo implements NetworkInfo {
  final Connectivity _connectivity;

  ConnectivityNetworkInfo({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> get isConnected async =>
      _hasConnection(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection);
}

/// Test/fallback implementation: assumes the device is always online
/// and never emits changes.
class AlwaysOnlineNetworkInfo implements NetworkInfo {
  const AlwaysOnlineNetworkInfo();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}
