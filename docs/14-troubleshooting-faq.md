# Troubleshooting & FAQ

### "flutter run -d chrome" fails with CORS errors against staging

The staging DHIS2 server only whitelists `localhost:3000` and `localhost:3001` for browser
requests. A plain `flutter run -d chrome` binds to a random port. **Use `./run_web.sh`**,
which pins port 3001. If port 3000 is already taken by something else on your machine, that's
fine — the script doesn't use it.

### "No metadata on this device yet" / "Form metadata is not on this device yet" errors

These come from `CacheException`s thrown by `CaptureRepositoryImpl` /
`DataEntryRepositoryImpl` when the relevant local tables are empty. This means either: (a)
you've never logged in online on this device/user, or (b) the first login's metadata
download was interrupted before it completed (`MetadataSyncService.syncMetadata()` only
writes `lastMetadataSync` after a full pass succeeds, so an interrupted download leaves the
device stuck needing a retry). **Fix:** log in online once, with a stable connection, and
let the sync finish. The `debug_sync_screen.dart` dev tool can trigger a manual full/delta
sync if you need to force a retry without logging out.

### I edited a Drift table and now the app won't compile / won't open the database

Two separate failure modes:
- **Compile error** → you forgot to regenerate:
  `dart run build_runner build --delete-conflicting-outputs`. See
  [Build & Release](12-build-and-release.md#regenerating-drift-code).
- **Runtime `UnsupportedError: No migration step for schema v...`** → you bumped
  `schemaVersion` without adding a matching step to the `steps` map in
  `AppDatabase.migration.onUpgrade`. This is intentional fail-loud behavior, not a bug — see
  [Database — Migrations](06-database.md#migrations) for the exact checklist.

### A data value never syncs, and there's no error shown

Check `DataValuesTable.syncState` for that row (via `debug_sync_screen.dart` or the in-app DB
viewer). If it's `draft`, that's expected — drafts are device-only until the form is marked
Complete (see [Offline & Sync](07-offline-and-sync.md#the-write-path-draft-pending-synced-error)).
If it's `pending` and staying that way, check connectivity
(`ConnectivityService.instance.online`) — a transport failure leaves rows `pending`
indefinitely for retry, by design, rather than surfacing an error. If it's `error`, the
`syncError` column holds the server's rejection reason; editing the cell clears it and
re-queues the value.

### Two users on the same device seem to have mixed-up data

They shouldn't — each user gets a fully separate SQLite file
(`hisp_<sanitized-username>.sqlite`). If you're seeing cross-contamination, check that
`AppDatabase.sanitizeUserKey()` is producing distinct keys for the two usernames involved
(e.g. usernames that differ only in characters stripped by the sanitizer, like
`nurse.alem` vs `nurse_alem`, would collide) — this is the one known edge case in the
per-user isolation scheme.

### The clock-tamper warning won't clear

`PeriodAccess`'s tamper flag only clears on a successful **online** contact that anchors the
clock to the server's time (`anchorToServer`). If the device has no connectivity, or if
`hasUnsyncedLocalData()` is keeping the anchor gated (there's pending data waiting to sync
first), the flag stays set. Get the device online and let a sync round fully settle — see
[Offline & Sync — The tamper-resistant clock](07-offline-and-sync.md#the-tamper-resistant-clock).

### Debug-signed APK can't be updated over an existing install

This is the exact scenario the release build's hard-fail exists to prevent — see
[Build & Release](12-build-and-release.md#android-release-build). If you're already stuck
with a debug-signed install in the field, the only fix is uninstall + reinstall the properly
signed build, which **loses any unsynced local data** on that device. Force a manual sync
and confirm everything is `synced` before uninstalling, if at all possible.

### Where do I change the default DHIS2 server?

`lib/core/constants/api_constants.dart` → `ApiConstants.baseUrl`, for the compiled-in
default. For a runtime change (no rebuild), use the server icon on the login screen or
Settings → DHIS2 server URL — that's the intended path for pointing at a different
environment. See [Getting Started — Configuration](01-getting-started.md#configuration).

### `OFFLINE_INTEGRATION.md` at the repo root describes stubs and interfaces I can't find

That file is an **older design note**, written before the offline layer was fully built —
it describes a planned integration surface (e.g. a `dataset_detail` feature) that has since
been superseded by the current implementation described in these docs. Treat it as
historical context for *why* certain interfaces exist, not as a description of current
behavior — the code and this `docs/` folder are authoritative.
