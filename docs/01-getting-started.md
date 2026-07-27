# Getting Started

## Prerequisites

- **Flutter SDK**, any 3.x version for local development. CI pins **3.41.4**
  (`.github/workflows/ci.yml`) — use that version if you want your local `flutter analyze`
  and `flutter test` to match CI exactly.
  ```bash
  flutter --version
  flutter doctor        # confirms Android SDK / licenses / toolchain are set up
  ```
- **Android Studio** (Android SDK + emulator) or **VS Code** with the Flutter extension.
- A **DHIS2 server** to talk to. The compiled-in default is the Ministry's staging instance;
  see [Configuration](#configuration) below to point at something else.

## Clone and install

```bash
git clone https://github.com/BIRUK-MULATU/hisp_mobile_trucker.git
cd hisp_mobile_trucker
flutter pub get
```

## Run

```bash
flutter run
```

The app opens on the login screen. There is no seeded test account — DHIS2 credentials for
whichever server you're pointed at are required for the first (online) login. After that
first login, the same credentials work offline indefinitely (see
[Authentication & Security](04-authentication-and-security.md)).

## Running on the Web (staging CORS quirk)

The staging DHIS2 server only allows browser requests from `localhost:3000` or
`localhost:3001`. A plain `flutter run -d chrome` binds to a random port, and the browser
then blocks every API call as a CORS violation. Always use the provided script instead,
which pins the port to 3001:

```bash
./run_web.sh
```

Web uses a completely different database backend under the hood (`sqlite3.wasm` +
`drift_worker.js`, see [Database](06-database.md#one-database-file-per-user)) but the
app-level behavior is identical to native.

## Code generation

The Drift database (`lib/core/database/app_database.dart`) uses generated code
(`app_database.g.dart`, ~15,400 lines, committed to the repo). You do **not** need to
regenerate it to just build and run — only after you **edit a table definition**:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Why: Drift turns your `Table` subclasses into type-safe Dart row/companion classes at build
time. If you add or change a column and skip this step, the generated code no longer matches
the schema you wrote and the project won't compile. If you add a table, you must also add it
to the `@DriftDatabase(tables: [...])` list in `app_database.dart` — see
[Database](06-database.md) for the full checklist, because adding a table also has knock-on
effects in `MetadataSyncService._clearMetadata()`.

## Configuration

There is no `.env` file. The compiled-in default DHIS2 server URL lives at
`lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'https://hmis-staging.moh.gov.et/api';
```

Users (and developers) can override it at runtime — no rebuild needed — from:
- the server icon on the login screen, or
- **Settings → DHIS2 server URL**.

The override is persisted in secure storage (`SecureStorage().saveBaseUrl()`) and applied to
the app's `ApiClient` singleton on the next launch (see `lib/main.dart`). The URL is
normalized automatically to `https://` + `/api`.

To point at a **local** DHIS2 instance during development, edit (don't commit) the commented
alternatives already present in `api_constants.dart`, or just use the in-app server URL
dialog — that's the intended path and avoids a code change entirely.

## Static analysis and tests

```bash
flutter analyze   # must be clean — this is a hard CI gate
flutter test      # unit + widget tests, mirrors lib/ under test/
```

Both run automatically in CI (`.github/workflows/ci.yml`) on every push to `main`/`integration*`
branches and on every pull request. A red CI blocks merge. See [Testing](11-testing.md) for
what's actually covered.

## Branching model

- `main` is the default branch and must stay green (CI: `flutter analyze` + `flutter test`).
- Work happens on short-lived feature branches named after the change (e.g.
  `integrationReportPeriod`, `reorderCategoryComboAndDataelement`), merged via pull request
  once CI passes.
- The offline database layer (`lib/core/database/`, `lib/core/sync/`) is actively developed —
  coordinate before making structural changes there to avoid conflicting migrations.
