# HISP Mobile Tracker — Technical Appendix

Supporting detail for the Ministry of Health presentation. All facts below were verified
directly against the codebase at `/home/biruk/hisp_mobile_trucker` (branch:
`reorderCategoryComboAndDataelement`) and are cited with file paths for independent
verification.

## A. Technology Stack (from `pubspec.yaml`)

| Concern | Package | Version |
|---|---|---|
| Framework | Flutter (Dart SDK) | `>=3.0.0 <4.0.0` |
| State management | `flutter_bloc` | `^8.1.6` |
| Navigation | `go_router` | `^14.2.7` |
| HTTP | `dio` | `^5.7.0` |
| Local database | `drift` + `sqlite3_flutter_libs` | `^2.20.0` / `^0.5.24` |
| Secure storage | `flutter_secure_storage` | `^9.2.2` |
| Offline credential check | `crypto` (SHA-256) | `^3.0.5` |
| Connectivity | `connectivity_plus` | `^7.2.0` |
| Charts | `fl_chart` | `^1.2.0` |
| Logging | `logger` | `^2.4.0` |

## B. Folder Structure

```
lib/
├── core/            auth, constants, data, database, errors, metadata, network, router, storage, sync, utils
├── features/        auth, capture, data_entry, home, settings, visualization (each: data/domain/presentation)
├── shared/          theme, widgets
└── debug/           dev-only sync debug screen, in-app DB viewer, test login page
```

Each feature folder follows the same three-layer split. Verified via import inspection:
domain-layer files (e.g. `lib/features/auth/domain/repositories/auth_repository.dart`)
import only entities and `core/errors` — no Flutter, Dio, or Drift imports.

## C. Authentication

- **Online:** `GET /api/me` with HTTP Basic Auth (`base64(username:password)`), built in
  `lib/core/network/interceptors/auth_interceptor.dart` (`buildBasicToken`). Sent over
  HTTPS in release builds.
- **Offline:** `lib/core/auth/credential_store.dart` computes
  `SHA-256(salt : serverUrl : username : password)`, compared in constant time against a
  stored verifier. The server URL is bound into the hash so a verifier from one DHIS2
  instance cannot unlock another.
- Login outcomes are modeled explicitly in `lib/core/auth/session_service.dart`:
  `onlineFirstSync`, `onlineReturning`, `offline`, `offlineNoCache`, `invalidCredentials`.
- The password itself is never persisted in any form, online or offline.

## D. Credential & Session Storage

- `lib/core/storage/secure_storage.dart` wraps `flutter_secure_storage`
  (`encryptedSharedPreferences: true` on Android; `KeychainAccessibility.first_unlock` on
  iOS). Stores username, base URL, cached user JSON, org units.
- Logout (`AuthRepositoryImpl.clearSession`) deletes secure-storage keys and closes the
  per-user database connection but preserves the database file and offline verifier, so the
  same user can log back in offline.
- "Wipe" (`session_service.dart`) additionally deletes the database file (+ WAL sidecars)
  and the offline verifier, after checking for unsynced work.

## E. Network Layer

- `lib/core/network/api_client.dart`: singleton Dio instance, base URL
  `https://hmis-staging.moh.gov.et/api` (runtime-configurable), 30s connect/receive/send
  timeouts, `BackgroundTransformer` for off-thread JSON decoding.
- Interceptor order: `AuthInterceptor` (adds headers, handles 401 → session end + redirect)
  then `LoggingInterceptor` (debug-only, explicitly redacts the `Authorization` header,
  truncates large bodies).
- No certificate pinning implemented (uses the system trust store).
- Typed exceptions in `lib/core/errors/exceptions.dart`: `NetworkException`,
  `UnauthorizedException`, `ServerException`, `TimeoutException`, `CacheException`.

## F. Local Database (Drift/SQLite)

- `lib/core/database/app_database.dart` defines 25 tables across four groups: 11 metadata
  tables (org units, datasets, data elements, sections, categories, option sets, validation
  rules, etc.), 9 link/join tables, 2 control tables (Users, SyncInfo), and 2 write-queue
  tables (`DataValuesTable`, `CompleteDataSetRegistrationsTable`).
- One physical database file per user: `hisp_<sanitized-username>.sqlite` (native), an
  equivalent isolated store on Web via `sqlite3.wasm` + a Drift worker.
- `PRAGMA foreign_keys = ON` and `PRAGMA journal_mode = WAL` enabled in `beforeOpen`.
- `schemaVersion` is frozen at `1`; `onUpgrade` is intentionally empty and the code throws
  `UnsupportedError` if a schema bump ships without a migration step — a deliberate
  fail-loud guard against silently corrupting field data.
- `purgeOutsideRetention()` deletes only already-`synced` rows outside the retention window;
  `draft`, `pending`, and `error` rows are never automatically deleted.
- No raw SQL string concatenation found anywhere — all queries go through Drift's
  type-safe builder (the only `customStatement()` calls are `PRAGMA` statements).
- Not encrypted at rest (plain `sqlite3_flutter_libs`, not an SQLCipher-backed variant).

## G. Synchronization & Conflict Resolution

- `lib/core/sync/sync_coordinator.dart`: three auto-sync triggers (connectivity restored,
  login event, 5-minute heartbeat).
- `lib/core/sync/drift_sync_manager.dart`: `pushPending()` (bulk `POST /dataValueSets`,
  `CREATE_AND_UPDATE`, `atomicMode=NONE`, 500-value batches, plus
  `completeDataSetRegistrations`) and `pullLatest()` (metadata delta sync).
- `lib/core/sync/manual_sync.dart`: user-triggered sync with an explicit outcome
  (`offline` / `nothingToSync` / `uploaded` / `partial` / `failed`).
- `lib/core/data/data_value_sync.dart` (`DataValueSync.syncForm`): per-cell conflict rules —
  draft always wins; equal values are marked synced and skipped; among pending/error values,
  local wins if newer than the server timestamp by more than a 2-minute tolerance and the
  clock is not flagged as tampered, otherwise the server wins.
- DHIS2 2.40 returns HTTP 409 + an `ImportSummary` on rejection; the exact per-value verdict
  is parsed and surfaced to the user in the form (red cell + server reason text).

## H. Android Build & Manifest Security

- `android/app/src/main/AndroidManifest.xml`: only `INTERNET` and `ACCESS_NETWORK_STATE`
  permissions requested; no `usesCleartextTraffic` flag in the release manifest (defaults to
  HTTPS-only); debug manifest explicitly allows cleartext for local dev servers only.
- `android/app/build.gradle.kts`: release build requires `android/key.properties`
  (gitignored) pointing at a real release keystore; the build throws a `GradleException` and
  hard-fails if the keystore is missing, unless `ALLOW_DEBUG_SIGNING=true` is explicitly
  passed.
- No ProGuard/R8 minification currently configured (`minifyEnabled` not set; no
  `proguard-rules.pro` file found).

## I. Testing

- 11 test files, ~1,450 lines, under `test/` (mirrors `lib/`).
- Strong coverage of offline-critical logic: `data_value_store_test.dart`,
  `data_value_sync_test.dart`, `data_value_push_test.dart`, `completeness_test.dart`,
  `ethiopian_calendar_test.dart`, `ethiopian_period_service_test.dart`,
  `value_type_validator_test.dart`, `data_element_roundtrip_test.dart`,
  `capture_repository_impl_test.dart` — most run against an in-memory Drift database
  (`AppDatabase.forTesting(NativeDatabase.memory())`), no live server required.
- Lighter coverage on Bloc and widget/UI layers (`widget_test.dart` covers smoke-level
  rendering only) — flagged as a gap in the Roadmap.
- `flutter analyze` and `flutter test` run in CI (`.github/workflows/ci.yml`) on every push
  and pull request to `main`; a red CI blocks merging.

## J. Known Limitations (stated transparently)

1. Local SQLite database is not encrypted at rest.
2. No TLS certificate pinning.
3. No ProGuard/R8 minification on Android release builds.
4. No token refresh/expiry — Basic Auth credentials are re-sent on every request for the
   life of the session (standard DHIS2 behavior, not unique to this app).
5. `android:allowBackup` is not explicitly set to `false`.
6. Dashboards/analytics (Visualization tab) are online-only; no local caching yet.
7. Bloc and widget-level automated test coverage is thin relative to the core sync engine.

None of these limitations expose credentials or allow remote data tampering; all are
addressed with specific, scoped recommendations in the Future Roadmap section of the
presentation.
