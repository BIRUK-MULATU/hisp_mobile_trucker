/// Contract for the offline sync engine (implemented by the backend
/// team on top of SQLite).
///
/// The UI already calls this through `HomeRepository.syncAll()` (the
/// sync button on the home app bar), so once a real implementation is
/// injected the button works with no UI changes.
abstract class SyncManager {
  /// Uploads every queued local write (data values, created records,
  /// dataset completions) to the DHIS2 server, oldest first. Must be
  /// safe to call repeatedly — already-synced items are skipped.
  Future<void> pushPending();

  /// Refreshes the local caches (datasets, data elements, records)
  /// from the server so the app has fresh data before going offline.
  Future<void> pullLatest();

  /// True while a push/pull is running; lets the UI show progress.
  Stream<bool> get isSyncing;
}

/// No-op engine used until the SQLite implementation is ready. Keeps
/// the app fully remote: syncing does nothing and reports idle.
class NoopSyncManager implements SyncManager {
  const NoopSyncManager();

  @override
  Future<void> pushPending() async {}

  @override
  Future<void> pullLatest() async {}

  @override
  Stream<bool> get isSyncing => const Stream.empty();
}
