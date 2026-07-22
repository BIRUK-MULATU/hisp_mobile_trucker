# Build & Release

## CI

`.github/workflows/ci.yml` — runs on every push to `main`/`integration*` and every pull
request:
```yaml
- flutter pub get
- flutter analyze
- flutter test
```
Pinned to Flutter **3.41.4** (`subosito/flutter-action@v2`). Match this version locally if
you want your results to match CI exactly. There is no separate build/deploy job in this
workflow — it's analyze + test only.

## Android release build

Configured in `android/app/build.gradle.kts`. **Release builds require a real signing
keystore and the build hard-fails without one** — this is deliberate, not a bug to route
around.

### One-time setup

```bash
keytool -genkey -v -keystore ~/hisp-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias hisp
```
Guard the resulting file and password carefully — **an Android app can only be updated by
APKs signed with the same key, forever**. Losing the keystore means every future release is
a new, separate app from the Play Store's perspective.

Create `android/key.properties` (gitignored — never commit it):
```properties
storeFile=/absolute/path/to/hisp-release.jks
storePassword=<password>
keyPassword=<password>
keyAlias=hisp
```

### Build

```bash
flutter build apk --release
```

### Why it fails without a keystore, on purpose

```kotlin
gradle.taskGraph.whenReady {
    if (allTasks.any { it.project == project && it.name.contains("Release") }) {
        throw GradleException(
            "Release build requires android/key.properties with the release keystore ..."
        )
    }
}
```
A debug-signed "release" APK installs fine but can **never be updated in place** — a user
would have to uninstall it first, losing all their offline data (pending, unsynced field
entries included). Failing the build loudly and immediately is cheaper than discovering this
in the field, on a health worker's phone, with unsynced data at stake.

To knowingly build a **non-distributable** test APK without the real keystore (debug-signed,
for local testing only — never hand this to a real user):
```bash
ALLOW_DEBUG_SIGNING=true flutter build apk --release
# or: flutter build apk --release -PallowDebugSigning=true
```
This logs a loud warning at build time and must be an explicit, conscious opt-in every time.

### Cleartext HTTP

Release builds are **HTTPS-only** — there is no `usesCleartextTraffic` override in the main
manifest. Plain `http://` servers only work in **debug** builds (see
`android/app/src/debug/AndroidManifest.xml`), for pointing at a local dev DHIS2 instance.

### Not yet configured

- **ProGuard/R8 minification** — `minifyEnabled` is not set, no `proguard-rules.pro` exists.
  See [Roadmap](15-roadmap-and-known-issues.md).
- **`android:allowBackup`** — not explicitly disabled (Android's default is permissive).

## Web build

```bash
flutter build web
```
Web uses Drift's WASM backend (`sqlite3.wasm` + `drift_worker.js`, served from `web/`) —
these two files are version-pinned to `pubspec.lock`'s `drift`/`sqlite3` versions and must be
re-downloaded together if you bump either package. See
[Database](06-database.md#one-database-file-per-user) for the web connection details.

For **local development** against the staging server, always use `./run_web.sh` rather than
`flutter run -d chrome` directly — it pins the dev server to port 3001, which is the only
port (besides 3000) the staging DHIS2 instance's CORS policy allows. A random port from a
plain `flutter run -d chrome` will have every API call silently blocked by the browser.

## iOS

No project-specific security overrides found in `ios/Runner/Info.plist` (no
`NSAppTransportSecurity` exceptions, no `NSAllowsArbitraryLoads`) — App Transport Security's
default HTTPS-only behavior applies unmodified.

## Regenerating Drift code

Required whenever a table definition in `lib/core/database/app_database.dart` (or any file
under `lib/core/metadata/`) changes:
```bash
dart run build_runner build --delete-conflicting-outputs
```
The generated file (`app_database.g.dart`, ~15,400 lines) **is committed to the repository**
— you don't need to run this just to build an unmodified checkout, only after you change a
schema. See [Database](06-database.md#migrations) for the full checklist, including the
`schemaVersion` bump this implies.
