import 'dart:async';
import '../utils/http_date.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../data/data_value_store.dart';
import '../data/period_access.dart';
import '../metadata/metadata_sync_service.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import 'credential_store.dart';

/// Progress of the first full metadata download. It runs in the
/// background after a first online login so the user is not held on
/// the login page; the capture UI observes this to show progress and
/// refresh when the data lands.
enum InitialSyncState { idle, running, failed, done }

/// Outcome of a login attempt.
enum LoginResult {
  /// Online, first time on this device: authenticated; the full
  /// metadata download continues in the background (see
  /// [SessionService.initialSync]).
  onlineFirstSync,

  /// Online, returning user: authenticated, delta sync kicked off.
  onlineReturning,

  /// Offline, verified against the stored hash: local data only.
  offline,

  /// Offline and no local database/verifier — first login needs a
  /// connection.
  offlineNoCache,

  /// Credentials rejected (by server when online, by verifier offline).
  invalidCredentials,
}

/// Owns the login/logout/wipe lifecycle and the per-user database
/// handle for the active session. The ApiClient it holds is the app's
/// single network capability for metadata.
class SessionService {
  SessionService({CredentialStore? credentials})
      : _credentials = credentials ?? CredentialStore();

  final CredentialStore _credentials;

  AppDatabase? _db;
  String? _userKey;
  DateTime? _serverDate;

  /// Observable progress of the first full metadata download; stays
  /// [InitialSyncState.idle] on returning/offline logins.
  final ValueNotifier<InitialSyncState> initialSync =
      ValueNotifier(InitialSyncState.idle);
  MetadataSyncService? _initialSyncService;

  bool get initialSyncRunning =>
      initialSync.value == InitialSyncState.running;

  /// True when the last session-start check flagged a backwards clock
  /// jump. UI contract: show an error and refuse past-period entry
  /// while true. Cleared by any online login (server anchor).
  bool clockTampered = false;

  AppDatabase get db {
    final d = _db;
    if (d == null) throw StateError('No active session — call login first.');
    return d;
  }

  bool get isLoggedIn => _db != null;

  /// The full decision tree. [online] is whatever your connectivity
  /// check reports at the moment of login.
  Future<LoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
    required bool online,
  }) async {
    final userKey = AppDatabase.sanitizeUserKey(username);

    if (online) {
      // Verify against the server by making one authenticated call.
      final api = ApiClient.withBasicAuth(
          baseUrl: serverUrl, username: username, password: password);
      final ok = await _serverAccepts(api);
      if (!ok) return LoginResult.invalidCredentials;

      _db = AppDatabase.forUser(username);
      _userKey = userKey;

      // Clock: anchor to server truth (HTTP Date header of the auth
      // probe) — heals tampering and clears any tamper flag.
      final serverDate = _serverDate;
      final periodAccess = PeriodAccess(_db!);
      if (serverDate != null && !await hasUnsyncedLocalData(_db!)) {
        // ANCHOR GATE: only recalibrate when nothing local is pending —
        // otherwise sync those values first; a later settled contact
        // (DataValueSync) will anchor.
        await periodAccess.anchorToServer(serverDate);
      } else if (serverDate != null) {
        log.i('[clock] login anchor deferred — pending local data exists');
      }
      clockTampered = await periodAccess.checkAtSessionStart();

      // Persist/refresh the offline verifier every online login.
      await _credentials.store(
        userKey: userKey,
        serverUrl: serverUrl,
        username: username,
        password: password,
      );

      final sync = MetadataSyncService(_db!, api);
      // "First time" = a full sync has never COMPLETED — not "the db
      // file exists". The file is created the moment a first login
      // starts, so an interrupted first sync would otherwise leave the
      // user stuck on the delta path with half-empty metadata forever.
      final firstTime = await sync.lastSyncedAt() == null;
      if (firstTime) {
        // Don't hold the user on the login page for the whole
        // download — enter the app and pull in the background. An
        // interrupted download keeps lastSyncedAt null, so the next
        // online login retries the full sync (see comment above).
        log.i('first online login for $userKey — full sync in background');
        _initialSyncService = sync;
        _runInitialSync();
        return LoginResult.onlineFirstSync;
      } else {
        log.i('returning online login for $userKey — delta sync');
        // Fire-and-forget: the user shouldn't wait on a delta.
        // Caller may await if it wants a definite finish.
        unawaited(sync.syncMetadataDelta().catchError((Object e) {
          log.e('background delta sync failed: $e');
          return <String, ({int updated, int deleted})>{};
        }));
        return LoginResult.onlineReturning;
      }
    }

    // ── Offline ──
    if (!await _databaseExistsFor(userKey)) {
      return LoginResult.offlineNoCache;
    }
    final verified = await _credentials.verify(
      userKey: userKey,
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    if (!verified) return LoginResult.invalidCredentials;

    _db = AppDatabase.forUser(username);
    _userKey = userKey;

    // Offline session: no server truth available — run the local
    // backwards-jump check. If it flags, the login still succeeds but
    // clockTampered is true; UI must warn and refuse back-period entry.
    clockTampered = await PeriodAccess(_db!).checkAtSessionStart();

    log.i('offline login for $userKey — local data only'
        '${clockTampered ? ' (CLOCK TAMPER FLAGGED)' : ''}');
    return LoginResult.offline;
  }

  void _runInitialSync() {
    final sync = _initialSyncService;
    if (sync == null || initialSyncRunning) return;
    initialSync.value = InitialSyncState.running;
    unawaited(sync.syncMetadata().then((_) {
      _initialSyncService = null;
      initialSync.value = InitialSyncState.done;
    }).catchError((Object e) {
      log.e('initial metadata sync failed: $e');
      initialSync.value = InitialSyncState.failed;
    }));
  }

  /// Retry after [InitialSyncState.failed] (connection dropped
  /// mid-download). No-op unless a failed initial sync is waiting.
  void retryInitialSync() => _runInitialSync();

  /// Ends the session but KEEPS the database and verifier — the same
  /// user can log in again later, offline. NOT a data-clearing action.
  Future<void> logout() async {
    await _db?.close();
    _db = null;
    _userKey = null;
    _initialSyncService = null;
    initialSync.value = InitialSyncState.idle;
    log.i('logged out (data retained)');
  }

  /// Completely removes this user from the device: closes and deletes
  /// the database, clears the verifier. Re-login is a fresh online
  /// first-sync.
  ///
  /// [pendingDataCount] is passed by the caller (computed from the data
  /// value tables); a UI must confirm loss when it's > 0 BEFORE calling
  /// this. This method itself does not prompt — it just destroys.
  Future<void> wipe() async {
    final key = _userKey;
    await _db?.close();
    _db = null;
    _initialSyncService = null;
    initialSync.value = InitialSyncState.idle;
    if (key != null) {
      await _credentials.clear(key);
      await deleteUserDatabase(key);
    }
    _userKey = null;
    log.w('wiped user $key from device');
  }

  // ── internals ──

  Future<bool> _serverAccepts(ApiClient api) async {
    try {
      // /api/me is the canonical "are these credentials valid" probe.
      final res = await api.get('/api/me.json', queryParameters: {
        'fields': 'id',
      });
      final dateHeader = res.headers.value('date');
      if (dateHeader != null) {
        // HTTP-date is RFC 1123; parseHttpDate handles it web-safely.
        try {
          _serverDate = parseHttpDate(dateHeader);
        } catch (_) {}
      }
      return res.statusCode == 200 && res.data is Map;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return false; // bad credentials
      rethrow; // network error — caller decides (maybe retry offline)
    }
  }

  Future<bool> _databaseExistsFor(String userKey) =>
      userDatabaseExists(userKey);
}
