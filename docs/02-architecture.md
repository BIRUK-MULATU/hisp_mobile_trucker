# Architecture

## Overview

The codebase is **feature-first Clean Architecture**. Each feature under `lib/features/`
owns its own `data / domain / presentation` split; shared infrastructure lives in
`lib/core/`, shared UI in `lib/shared/`. There is no formal dependency-injection framework —
wiring is manual and explicit (see [Dependency Injection](#dependency-injection) below).

```
lib/
├── main.dart                # App entry point: wires singletons, starts sync, runs the app
├── core/                    # Cross-cutting infrastructure, shared by every feature
│   ├── auth/                #   AppSession, SessionService, CredentialStore
│   ├── constants/           #   ApiConstants, AppConstants
│   ├── data/                #   DataValueStore/Sync/Push, CompletenessStore/Sync,
│   │                        #   Ethiopian calendar + period service, PeriodAccess, validator
│   ├── database/            #   Drift schema (app_database.dart) + platform connections
│   ├── errors/               #   AppException hierarchy (data layer) + Failure hierarchy (domain layer)
│   ├── metadata/             #   MetadataResource base class + one file per DHIS2 metadata type
│   ├── network/               #   ApiClient (Dio), interceptors, connectivity detection
│   ├── router/                #   go_router config + auth guard
│   ├── storage/               #   SecureStorage wrapper
│   ├── sync/                  #   SyncManager contract, DriftSyncManager, SyncCoordinator, manual sync
│   └── utils/                  #   Shared logger, HTTP date parsing
├── debug/                    # Dev-only screens: sync debug, in-app DB viewer, quick test login
├── features/
│   ├── auth/                 # Login/logout — data/domain/presentation
│   ├── capture/               # Org unit tree → dataset → section → period navigation
│   ├── data_entry/            # The entry form itself (bloc, table, cells)
│   ├── home/                  # App shell: Capture/Visualization toggle, filters, drawer (presentation only)
│   ├── settings/               # Server URL, profile, logout (presentation only)
│   └── visualization/          # DHIS2 dashboards rendered natively with fl_chart
├── shared/
│   ├── theme/                  # AppColors, AppTextStyles, AppDimensions, AppBreakpoints, AppTheme
│   └── widgets/                 # AppButton, AppTextField, AppLoader, ConnectivityIndicator,
│                                 # FilterPanel, SegmentedToggle, ServerUrlDialog, SyncSnackbar
└── (generated) app_database.g.dart  — Drift-generated, ~15,400 lines, committed
```

Note that `home` and `settings` are presentation-only — they have no `data/` or `domain/`
subfolders because they don't own any business logic or persistence of their own; they
compose other features' repositories and read from `core/` directly. This is a deliberate,
minimal application of the pattern: **the three-layer split exists where there is a
non-trivial repository/use-case boundary to draw, not as ceremony for every folder.**

## The four layers, and why each exists

### 1. Presentation

Pages, widgets, and Bloc classes. Owns UI state and translates user intent into domain-layer
calls. Never talks to Dio or Drift directly — it goes through a repository (usually via a
use case). **Why it's separate:** the UI can be redesigned, or a whole screen rebuilt, without
touching business rules underneath it.

### 2. Domain

Entities, use cases, and repository *interfaces* (abstract classes with no implementation).
This is pure Dart — **verified by direct import inspection**: e.g.
`lib/features/auth/domain/repositories/auth_repository.dart` imports only
`../entities/user_entity.dart` and `../../../../core/errors/exceptions.dart`. No `package:flutter/*`,
no `package:dio/*`, no `package:drift/*` anywhere in a domain folder. **Why it's separate:**
business rules (what a login *means*, what fields a data value needs) are testable in total
isolation from Flutter, from the network, and from SQLite, and would survive a full rewrite
of either.

### 3. Data

Repository *implementations*, remote/local data sources, and Models (DTOs with
`fromJson`/`toJson`) that extend the domain Entities. This is where Dio calls happen, where
Drift queries run, and where raw DHIS2 JSON gets turned into typed Dart objects. **Why it's
separate:** a repository implementation is the single place a feature's persistence strategy
lives — change from a legacy remote-only design to an offline-first Drift-backed one (which
is exactly what happened to `AuthRepositoryImpl` and `DataEntryRepositoryImpl` — see their
doc comments) without touching a single Bloc or Page.

### 4. Core

Infrastructure every feature needs but that isn't specific to any one of them: the HTTP
client, the database connection, secure storage, the sync engine, session/auth plumbing,
shared exception types. **Why it's separate:** avoids each feature reinventing its own Dio
client or database connection, and gives the app exactly one source of truth for
cross-cutting concerns like "is the user logged in" (`AppSession`) or "are we online"
(`ConnectivityService`).

## Dependency direction

```
Presentation ──depends on──▶ Domain ◀──implements── Data
                                ▲
                                └── Core (network, database, storage, sync, auth, errors)
```

Presentation and Data both depend on Domain; Domain depends on nothing feature-specific.
Data and Presentation both use Core. This is the dependency-inversion piece of Clean
Architecture: `AuthRepository` (domain) declares *what* login does; `AuthRepositoryImpl`
(data) declares *how*. A Bloc holds a reference to the interface type, never the concrete
implementation, which is what makes it possible to inject a fake `AuthRepository` in a test.

## Dependency Injection

**There is no DI framework** — no `get_it`, `riverpod`, `injectable`, or `provider` package
in `pubspec.yaml`. Dependencies are wired by hand with constructor injection, at the point
where a feature is built.

Two categories:

**App-wide singletons**, constructed once and reused everywhere via a private constructor +
static instance (the classic Dart singleton pattern):
- `ApiClient()` — `lib/core/network/api_client.dart`
- `SecureStorage()` — `lib/core/storage/secure_storage.dart`
- `AppSession.instance` — `lib/core/auth/app_session.dart`
- `ConnectivityService.instance` — `lib/core/network/connectivity_service.dart`
- `DriftSyncManager.instance` — `lib/core/sync/drift_sync_manager.dart`

**Feature-level wiring**, done per-page at `build()` or `initState()` time. Example, from
`lib/features/auth/presentation/pages/login_page.dart`:

```dart
final secureStorage = SecureStorage();
final apiClient = ApiClient();
final remoteDataSource = AuthRemoteDataSourceImpl(
  apiClient: apiClient,
  secureStorage: secureStorage,
);
final repository = AuthRepositoryImpl(
  remoteDataSource: remoteDataSource,
  secureStorage: secureStorage,
);

BlocProvider(
  create: (_) => AuthBloc(
    loginUseCase: LoginUseCase(repository),
    logoutUseCase: LogoutUseCase(repository),
    authRepository: repository,
  )..add(const AuthCheckRequested()),
  ...
);
```

Most repository implementations (`AuthRepositoryImpl`, `CaptureRepositoryImpl`,
`DataEntryRepositoryImpl`) also accept an **optional** `SessionService`/`NetworkInfo`
parameter that defaults to `AppSession.instance.service` / `ConnectivityNetworkInfo()` when
omitted — this is what makes them constructible with fakes in tests without any DI
container.

**Trade-off, stated plainly:** this is simple and fully traceable (you can `cmd+click` from
a widget straight to every dependency it owns, no reflection or code generation involved),
but the same wiring snippet is duplicated across pages that need the same repository (e.g.
`AuthRepositoryImpl` is reconstructed identically in `login_page.dart`, `home_page.dart`'s
drawer, and `settings_page.dart`). If the feature count keeps growing, introducing a small
service locator (`get_it`) to register these singletons once in `main.dart` is the natural
next step — see [Roadmap](15-roadmap-and-known-issues.md).

## `main.dart` — what actually happens at startup

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([...]);        // lock portrait
  SystemChrome.setSystemUIOverlayStyle(...);                  // transparent status bar

  final storedBaseUrl = await SecureStorage().getBaseUrl();   // Settings override wins
  if (storedBaseUrl != null && storedBaseUrl.isNotEmpty) {
    ApiClient().updateBaseUrl(storedBaseUrl);
  }

  SyncCoordinator(                                            // auto-sync, see doc 07
    networkInfo: ConnectivityNetworkInfo(),
    syncManager: DriftSyncManager.instance,
  ).start();

  ConnectivityService.instance;                                // starts the online/offline probe

  runApp(const HispMobileTrackerApp());
}
```

`HispMobileTrackerApp` is a thin `MaterialApp.router` wrapper: app name/theme from
`AppConstants`/`AppTheme`, routing delegated entirely to `AppRouter.router` (see
[Routing](09-routing.md)). There is no splash screen or explicit auth check here — that's
handled by the router's `redirect` combined with `AuthBloc`'s `AuthCheckRequested` event
fired from `LoginPage`.

## Repository pattern and use cases

Every feature with real business logic defines a **repository interface** in `domain/` and
exactly one **implementation** in `data/`. Use cases are deliberately thin — one class, one
responsibility, usually just validation plus a straight call-through:

```dart
// lib/features/auth/domain/usecases/login_usecase.dart (shape, not verbatim)
class LoginUseCase {
  Future<UserEntity> call({required String username, required String password}) {
    // trims + validates non-empty, then:
    return repository.login(username: username.trim(), password: password);
  }
}
```

| Feature | Interface (domain) | Implementation (data) | Notable use cases |
|---|---|---|---|
| auth | `AuthRepository` (4 methods) | `AuthRepositoryImpl` | `LoginUseCase`, `LogoutUseCase` |
| capture | `CaptureRepository` (5 methods) | `CaptureRepositoryImpl` | `GetOrgUnitChildrenUseCase`, `GetOrgUnitDataSetsUseCase`, `GetDataSetSectionsUseCase` |
| data_entry | `DataEntryRepository` (6 methods) | `DataEntryRepositoryImpl` | `GetDataElementsUseCase`, `SaveDataValuesUseCase` |
| visualization | *(no interface — single impl)* | `VisualizationRepositoryImpl` | *(none — called directly from the view)* |

`visualization` skips the interface because it has exactly one implementation and is
online-only by design (see [Features](10-features.md#visualization-libfeaturesvisualization)) — there's no second
implementation to substitute, so the extra abstraction wasn't worth it. This is a useful
signal for when *not* to apply the pattern.

## Models, DTOs, and Entities

- **Domain Entities** are pure Dart with no JSON awareness: `UserEntity`, `OrgUnitEntity`,
  `DataElementEntity`, `DataValueEntity`, `DataSetEntity`, etc. They carry `==`/`hashCode`
  overrides keyed on `id` where identity matters.
- **Data Models** extend the entities and add the DHIS2 REST API boundary — `fromJson()` /
  `toJson()`. Example: `UserModel extends UserEntity` in
  `lib/features/auth/data/models/user_model.dart`.
- **Local persistence** uses Drift's **generated** row classes — one Dart class is derived
  automatically from each `Table` subclass (e.g. `DataElementsTable` → generated `DataElement`
  class). There is no hand-written SQL-to-Dart mapping to get wrong.

Domain code (use cases, Blocs) only ever sees Entities. A DHIS2 API shape change is absorbed
entirely inside a Model's `fromJson`, without touching a use case, Bloc, or screen.

## Code quality snapshot

- **118 Dart files, ~32,000 lines** of production code (excluding the generated
  `app_database.g.dart`, ~15,400 lines).
- Largest hand-written files: `capture_org_unit_view.dart` (794 lines),
  `data_entry_page.dart` (780 lines), `ethiopian_calendar.dart` (647 lines — legitimately
  dense domain logic), `filter_panel.dart` (606 lines). The first two are reasonable
  refactor targets if you're looking to split UI state from layout.
- Lint: `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`, no project-specific
  rule overrides currently enabled. `flutter analyze` must be clean — it's a CI gate.
- SOLID: repository interfaces are small and focused (4–6 methods); use cases are
  single-purpose. The main documented trade-off is manual DI (see above) — coupling to
  concrete implementations at construction sites, in exchange for zero magic.
