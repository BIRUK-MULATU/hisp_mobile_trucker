# HISP Mobile Tracker

[![CI](https://github.com/BIRUK-MULATU/hisp_mobile_trucker/actions/workflows/ci.yml/badge.svg)](https://github.com/BIRUK-MULATU/hisp_mobile_trucker/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![DHIS2](https://img.shields.io/badge/DHIS2-2.40-4285F4)](https://dhis2.org)

**HISP Mobile Tracker** is an offline-first Flutter app for collecting aggregate
health data into [DHIS2](https://dhis2.org) (the national Health Management
Information System). It is built for health workers in the field: data can be
entered at any time — with or without a connection — and is synchronized with
the DHIS2 server whenever connectivity returns.

Developed by **HISP Ethiopia** in collaboration with the Ministry of Health.

---

## Features

- **Online & offline login** — first login verifies against the server; after
  that, the same credentials work offline (verified locally with a SHA-256
  hash, never stored in plain text).
- **Offline-first data entry** — every value is saved to a local SQLite
  database on the device first. Nothing is lost when the network drops.
- **Draft → Complete workflow** — entries are kept as device-only *drafts*
  until the user marks the form **Complete**; only then are they queued and
  pushed to the server. Completed forms can be reopened.
- **Automatic sync** — pending data is pushed when connectivity returns, on
  login, and on a periodic heartbeat; a manual sync button shows exact results
  (uploaded / failed / up to date).
- **Conflict resolution** — pull-then-push per form; newest value wins, with
  guards for tampered device clocks, and local drafts are never overwritten
  by server data.
- **Server rejection handling** — values the server refuses (e.g. wrong type,
  not in an option set) are marked red in the form with the server's reason;
  editing them re-queues the fix.
- **Capture workflow** — organisation unit tree (lazily loaded, ~38k units on
  the national instance) → dataset → section → period → entry form with
  collapsible data element sections.
- **Ethiopian calendar** — period pickers and DHIS2 period IDs follow the
  Ethiopian fiscal year (including the `...Nov` period types on the national
  server).
- **Value validation** — client-side checks per DHIS2 value type and option
  set before anything is sent.
- **Filters** — capture list filterable by date window, organisation unit
  (typed or picked from a full-page tree), and sync state.
- **Dashboards** — the Visualization tab renders DHIS2 dashboards natively
  with `fl_chart` (online only for now).
- **Report Period view** — every report the user has worked on, across all
  organisation units, complete or draft.

## Tech stack

| Concern | Package (version from `pubspec.yaml`) |
|---|---|
| Framework | Flutter (Dart SDK `>=3.0.0 <4.0.0`; CI pins Flutter **3.41.4**) |
| State management | `flutter_bloc` ^8.1.6 |
| Navigation | `go_router` ^14.2.7 (with a login guard) |
| HTTP | `dio` ^5.7.0 |
| Local database | `drift` ^2.20.0 + `sqlite3_flutter_libs` ^0.5.24 (SQLite) |
| Secure storage | `flutter_secure_storage` ^9.2.2 (session, credentials) |
| Offline credential check | `crypto` ^3.0.5 (SHA-256) |
| Connectivity | `connectivity_plus` ^7.2.0 |
| Charts | `fl_chart` ^1.2.0 |
| Dates / logging | `intl` ^0.19.0, `logger` ^2.4.0 |
| Dev tools | `build_runner` ^2.4.12, `drift_dev` ^2.20.0, `flutter_lints` ^4.0.0, `drift_db_viewer` (in-app DB browser) |

## Architecture

The codebase is **feature-first**: each feature folder owns its own
`data / domain / presentation` layers, while shared infrastructure lives in
`core/` and shared UI in `shared/`.

```
lib/
├── core/                  # Cross-cutting infrastructure
│   ├── auth/              #   AppSession singleton, SessionService (login tree)
│   ├── constants/         #   API constants (default server URL lives here)
│   ├── data/              #   Data value store/sync/push, completeness,
│   │                      #   Ethiopian calendar + period service, validators
│   ├── database/          #   Drift schema (app_database.dart) + per-platform
│   │                      #   connection (native SQLite / WASM on web)
│   ├── errors/            #   Exceptions & Failures
│   ├── metadata/          #   Resource-based DHIS2 metadata sync
│   ├── network/           #   Dio ApiClient, connectivity service
│   ├── router/            #   GoRouter setup + auth guard
│   ├── storage/           #   Secure storage wrapper
│   ├── sync/              #   DriftSyncManager, SyncCoordinator (auto-sync)
│   └── utils/             #   Logger, HTTP date parsing
├── debug/                 # Dev-only screens (sync debug, DB viewer)
├── features/
│   ├── auth/              # Login page + repository (online/offline)
│   ├── capture/           # Org unit tree → dataset → section → period
│   ├── data_entry/        # The entry form (bloc, collapsible table, cells)
│   ├── home/              # Home shell: Visualization/Capture toggle, filters
│   ├── settings/          # Settings incl. server URL dialog
│   └── visualization/     # DHIS2 dashboards rendered with fl_chart
├── shared/
│   ├── theme/             # Colors, text styles, dimensions, breakpoints
│   └── widgets/           # FilterPanel, dialogs, loaders, toggles...
└── main.dart
```

### How offline-first works here (the short version)

1. **Login** creates/opens a **per-user SQLite database** and, on first online
   login, downloads the user's DHIS2 metadata (datasets, data elements,
   organisation units — capped to the user's own org unit subtree).
2. **Data entry** writes to the local database only. Values start as
   **drafts**; completing the form promotes them to **pending**.
3. **Sync** pushes pending values as one bulk `dataValueSets` import and
   handles the server's per-value verdicts (DHIS2 2.40 answers conflicts with
   HTTP 409 + an import summary; rejected values are flagged in the form).
4. **Pulling** a form first fetches server values and resolves conflicts cell
   by cell (equal → settled; different → newest wins; drafts always survive).

A deeper write-up is in [`OFFLINE_INTEGRATION.md`](OFFLINE_INTEGRATION.md).

## Prerequisites

- **Flutter SDK** — any 3.x version works for development; CI (and therefore
  "official" builds) uses **3.41.4**, so prefer that to avoid surprises.
  Check with:

  ```bash
  flutter --version
  flutter doctor        # shows anything missing (Android SDK, licenses...)
  ```

- **Android Studio** (for the Android SDK + an emulator) or **VS Code** with
  the Flutter extension.
- A **DHIS2 server** to talk to — a local instance or the staging server
  (see *Configuration* below).

## Getting started

```bash
# 1. Clone the repository
git clone https://github.com/BIRUK-MULATU/hisp_mobile_trucker.git
cd hisp_mobile_trucker

# 2. Install dependencies (downloads every package in pubspec.yaml)
flutter pub get

# 3. Run the app on a connected device or emulator
flutter run
```

### Code generation (only when you change the database schema)

The Drift database (`lib/core/database/app_database.dart`) uses generated code
(`app_database.g.dart`). The generated file **is committed**, so you only need
to regenerate after editing tables:

```bash
dart run build_runner build --delete-conflicting-outputs
```

> Why: Drift turns the table definitions into type-safe Dart classes at build
> time. If you change a table and skip this step, the code no longer matches
> the schema and compilation fails.

### Configuration

There is no `.env` file. The default DHIS2 server URL is compiled in at
`lib/core/constants/api_constants.dart`, and users can change it at runtime
from the **server icon on the login screen** (or in Settings). The URL is
normalized automatically (`https://` + `/api`).

### Running on the web (staging CORS quirk)

The staging server only allows browser requests from `localhost:3000/3001`.
Use the provided script, which pins the port:

```bash
./run_web.sh
```

> Why: a plain `flutter run -d chrome` picks a random port, and the browser
> then blocks every API call (CORS). The script always uses port 3001.

## Testing

```bash
flutter analyze   # static checks — must be clean
flutter test      # unit + widget tests (test/ mirrors lib/)
```

Both commands run automatically in CI
([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) on every push to
`main` and on every pull request. A red CI means the change cannot be merged.

## Release build (Android)

Release APKs must be signed with the team's **release keystore**. The build is
configured in `android/app/build.gradle.kts` and **fails on purpose** if the
keystore is not set up:

1. Generate a keystore once (guard the file and password — an app can only be
   updated by APKs signed with the *same* key, forever):

   ```bash
   keytool -genkey -v -keystore ~/hisp-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias hisp
   ```

2. Create `android/key.properties` (gitignored — never commit it):

   ```properties
   storeFile=/absolute/path/to/hisp-release.jks
   storePassword=<password>
   keyPassword=<password>
   keyAlias=hisp
   ```

3. Build:

   ```bash
   flutter build apk --release
   ```

To knowingly build a **non-distributable** test APK without the keystore
(signed with debug keys), opt in explicitly:

```bash
ALLOW_DEBUG_SIGNING=true flutter build apk --release
```

> Why the hard failure: a debug-signed "release" APK installs fine but can
> never be updated in place — users would have to uninstall (losing their
> offline data). Failing the build is cheaper than discovering that in the
> field. Note: release builds are HTTPS-only; plain `http://` servers work in
> debug builds only.

## Contributing

- `main` is the default branch and must stay green (CI: analyze + test).
- The backend/offline database layer is developed on the `database-access`
  branch by the backend team; coordinate before editing files under
  `lib/core/database/` or the sync services.
- Work happens on short-lived feature branches named after the change
  (e.g. `integrationReportPeriod`, `reorderCategoryComboAndDataelement`),
  merged into `main` via pull request once CI passes.
- Before pushing: `flutter analyze` and `flutter test` locally — CI runs
  exactly those.

## License

Proprietary software of HISP Ethiopia. All rights reserved.

---

*Developed by HISP Ethiopia for the Ministry of Health.*
