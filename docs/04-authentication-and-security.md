# Authentication & Security

## Authentication scheme

DHIS2 uses **HTTP Basic Authentication**: `Authorization: Basic base64(username:password)`.
This app builds that header in exactly one place —
`AuthInterceptor.buildBasicToken()` (`lib/core/network/interceptors/auth_interceptor.dart`):

```dart
static String buildBasicToken(String username, String password) {
  final credentials = '$username:$password';
  return base64Encode(utf8.encode(credentials));
}
```

Sent over HTTPS in release builds (see [Network Security](#network-security) below).

## Two login paths, one session

`SessionService.login()` (`lib/core/auth/session_service.dart`) is the single decision tree
for both paths. It returns a `LoginResult` enum with five values:

| Result | Meaning |
|---|---|
| `onlineFirstSync` | Online, first time on this device — authenticated; full metadata download continues in the background |
| `onlineReturning` | Online, returning user — authenticated; delta sync kicked off in the background |
| `offline` | Offline, verified against the stored hash — local data only |
| `offlineNoCache` | Offline and no local database/verifier exists — first login needs a connection |
| `invalidCredentials` | Rejected, by the server (online) or the verifier (offline) |

### Online path

1. `ApiClient.withBasicAuth(baseUrl, username, password)` — a throwaway, plugin-free Dio
   client built with the credentials as a fixed header.
2. `GET /api/me.json?fields=id` — the canonical "are these credentials valid" probe. A 200
   with a JSON body means yes; a 401 means `invalidCredentials`; any other `DioException`
   propagates (the caller falls back to the offline path — see
   `AuthRepositoryImpl.login()`).
3. The response's `Date` header is captured and used to anchor the app's tamper-resistant
   clock (`PeriodAccess.anchorToServer`) — but **only if no local data is currently
   pending**, to avoid re-anchoring underneath unsynced timestamps.
4. `AppDatabase.forUser(username)` opens (or creates) the per-user SQLite file.
5. `CredentialStore.store(...)` persists a **salted SHA-256 verifier** — see below — so this
   same login can succeed offline next time.
6. First time ever for this user → `MetadataSyncService.syncMetadata()` (full download,
   runs in the background so the user isn't held on the login screen). Returning user →
   `syncMetadataDelta()` (lighter, fire-and-forget).

### Offline path

1. `AppDatabase` must already exist for this user (`userDatabaseExists`) — otherwise
   `offlineNoCache`. There is no way to log in for the very first time without a connection.
2. `CredentialStore.verify(...)` recomputes the salted hash and compares it, **in constant
   time**, against the stored verifier.
3. On success, the per-user database opens exactly as in the online path, and a local
   backwards-clock-jump check runs (`PeriodAccess.checkAtSessionStart()`).

### The offline verifier, precisely

`lib/core/auth/credential_store.dart`:

```
verifier = SHA-256( salt : serverUrl : username : password )
```

- `salt` is 16 cryptographically random bytes (`Random.secure()`), unique per user, stored
  alongside the hash.
- `serverUrl` is normalized (trailing slashes stripped) and baked into the hash — **a
  verifier created against one DHIS2 instance cannot validate a login aimed at another**.
- Comparison is constant-time (`_constantTimeEquals`, XOR-accumulate over every byte,
  independent of where a mismatch occurs) to resist timing attacks.
- **The password itself is never stored, in any form, online or offline.** The verifier can
  check a login attempt; it cannot be reversed back into a password.
- Both salt and hash are stored via `flutter_secure_storage` (Android EncryptedSharedPreferences),
  so the verifier is itself encrypted at rest even though it's already a one-way hash.

## Credential & session storage

Two distinct storage classes, both backed by `flutter_secure_storage` — don't confuse them:

- **`CredentialStore`** (`lib/core/auth/credential_store.dart`) — the offline-login verifier
  only. Keys: `cred_salt_<userKey>`, `cred_hash_<userKey>`.
- **`SecureStorage`** (`lib/core/storage/secure_storage.dart`) — session/profile
  convenience data: `username`, `base_url`, `user_data` (cached `/me` JSON, used by
  `getCurrentUser()`), `org_units`. Also owns a legacy `auth_token` key that is deleted (not
  written) on every 401/logout — a cleanup shim for installs from before the app switched to
  the salted-hash design.

Platform backing:
```dart
final FlutterSecureStorage _storage = const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```
Android → EncryptedSharedPreferences (backed by the Android Keystore). iOS → Keychain.

**Nothing sensitive lives in the SQLite database.** The `UsersTable` caches only `uid`,
`username`, `displayName` from `/api/me` — no password, no token, no verifier.

## Logout, wipe, and 401 handling

- **Logout** (`SessionService.logout()`) closes the database connection and clears the
  in-memory session, but **keeps the database file and the offline verifier** — the same
  user can log back in later, offline, without re-downloading metadata.
  `AuthRepositoryImpl.logout()` additionally calls `SecureStorage.clearSession()` (drops
  `username`, `user_data`, `org_units`, the legacy token) and clears
  `AppSession.instance.api`.
- **Wipe** (`SessionService.wipe()`) is the destructive option: closes and **deletes** the
  database file (+ WAL/SHM sidecars) and clears the credential verifier. **Guarded**: it
  throws `StateError` unless `confirmedDataLoss: true` is passed, after checking
  `countUnsyncedWork()` — callers must show that count to the user and get explicit
  confirmation first. Re-login after a wipe is a fresh online-only first-sync.
- **401 anywhere** (`AuthInterceptor.onError`): deletes the legacy secure-storage token,
  calls `AppSession.instance.service.logout()` (session-clear semantics, not wipe), and
  redirects to `/login?reason=session-expired` if not already there. The local database and
  offline verifier survive a 401 — the user can still log in offline afterward.

## Network security

- **HTTPS-only in release.** The compiled default (`ApiConstants.baseUrl`) is
  `https://hmis-staging.moh.gov.et/api`. There is no `android:usesCleartextTraffic` flag in
  the main manifest (`android/app/src/main/AndroidManifest.xml`), so cleartext HTTP is
  blocked by default in release builds; the **debug** manifest
  (`android/app/src/debug/AndroidManifest.xml`) explicitly allows it for local dev servers.
- **No certificate pinning.** Dio uses the platform's default `HttpClient`, which trusts the
  system certificate store. No `badCertificateCallback`, no custom `SecurityContext`. See
  [Roadmap](15-roadmap-and-known-issues.md).
- **Timeouts:** 30 seconds each for connect/receive/send (`ApiConstants`).
- **Interceptor order** on the main `ApiClient` (`_init()`): `AuthInterceptor` then
  `LoggingInterceptor`. See [Networking](05-networking.md) for the full chain.

## Logging discipline

- `lib/core/utils/app_logger.dart`: release builds log **warning and error only** —
  request/response detail never reaches a field device's logcat.
- `LoggingInterceptor._sanitizeHeaders()` explicitly replaces the `Authorization` header
  with `***REDACTED***` before logging, in debug builds only (`if (kDebugMode)`).
- The internal `ApiClient._apiLogInterceptor()` used by `ApiClient.withBasicAuth` (test/CLI
  path) carries an explicit code comment: *"NEVER logs headers — the Authorization header is
  a credential and must not reach logcat."*
- Response bodies **are** logged at debug level, truncated to 600 characters — acceptable
  since debug logging is stripped from release builds entirely.

## Input validation and injection

- **SQL injection:** not applicable by construction. All queries go through Drift's
  type-safe query builder; the only `customStatement()` calls in the codebase are two
  `PRAGMA` statements in `AppDatabase.migration.beforeOpen` — no user data is ever
  interpolated into a raw SQL string.
- **Data value validation:** `validateDataValue()` (`lib/core/data/value_type_validator.dart`)
  mirrors DHIS2's own server-side valueType checks (NUMBER, INTEGER, PERCENTAGE,
  UNIT_INTERVAL, BOOLEAN, DATE, PHONE_NUMBER, EMAIL, option-set membership, etc.) and runs
  **client-side before a value is ever queued**, so garbage never leaves the device. Unknown
  or `TEXT`/`LONG_TEXT` types are accepted as-is — the server remains the final authority.
- **URL validation:** the server-URL settings dialog checks for an `http://`/`https://`
  prefix before accepting a custom server.

## Android build & manifest security

- **Permissions:** only `INTERNET` and `ACCESS_NETWORK_STATE` (`AndroidManifest.xml`). No
  storage, camera, location, or contacts permissions requested anywhere.
- **Release signing is enforced, not optional.** `android/app/build.gradle.kts` reads
  `android/key.properties` (gitignored) for the release keystore. If it's missing, the build
  **hard-fails** the moment a `*Release` task is scheduled, with an explanatory
  `GradleException` — this specifically prevents an app that gets accidentally
  debug-signed and then can never be updated in place once installed. Opt-in escape hatch
  for local testing only: `-PallowDebugSigning=true` or `ALLOW_DEBUG_SIGNING=true`, which
  logs a loud warning.
- **No ProGuard/R8 minification configured** (`minifyEnabled` not set; no
  `proguard-rules.pro` file present). See [Roadmap](15-roadmap-and-known-issues.md).
- **`android:allowBackup`** is not explicitly set (Android's default is permissive). Not yet
  hardened — see Roadmap.

## Honest summary

| Area | Status |
|---|---|
| Password storage | ✅ Never stored in any recoverable form, online or offline |
| Offline verification | ✅ Salted SHA-256, constant-time compare, server-URL-bound |
| Secure storage | ✅ OS-level (Android Keystore-backed EncryptedSharedPreferences / iOS Keychain) |
| Transport | ✅ HTTPS-only in release | ⚠️ No certificate pinning |
| Local database | ⚠️ Not encrypted at rest (holds cached metadata + pending field data, never credentials) |
| Android release build | ✅ Hard-fails without a real keystore | ⚠️ No R8/ProGuard minification | ⚠️ `allowBackup` not explicitly disabled |
| Logging | ✅ Authorization header redacted; release suppresses debug/info logs |
| SQL injection | ✅ Eliminated by construction (Drift only, no raw string interpolation) |
| Session on 401 | ✅ Ends session, redirects with a reason code, preserves local data |

None of the ⚠️ items expose credentials or allow remote data tampering. They're all
defense-in-depth items for the "device is lost or physically compromised" threat model, and
each has a concrete, scoped fix — see [Roadmap & Known Issues](15-roadmap-and-known-issues.md).
