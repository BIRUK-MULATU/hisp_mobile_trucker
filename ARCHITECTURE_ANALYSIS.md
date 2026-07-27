# HISP Mobile Tracker — Complete Architecture Analysis

> **Prepared for:** New developer onboarding
> **Project:** HISP Mobile Tracker (offline-first Flutter app for DHIS2 health data collection)
> **Developed by:** HISP Ethiopia for the Federal Ministry of Health

---

## Table of Contents

1. [High-Level Overview](#1-high-level-overview)
2. [Overall Architecture](#2-overall-architecture)
3. [Backend Analysis](#3-backend-analysis)
4. [Frontend Analysis](#4-frontend-analysis)
5. [Complete Folder Walkthrough](#5-complete-folder-walkthrough)
6. [Dependency Analysis](#6-dependency-analysis)
7. [Design Patterns](#7-design-patterns)
8. [Security Review](#8-security-review)
9. [Performance Review](#9-performance-review)
10. [Code Quality Review](#10-code-quality-review)
11. [Complete Request Lifecycle](#11-complete-request-lifecycle)
12. [Beginner Learning Guide](#12-beginner-learning-guide)
13. [Final Summary](#13-final-summary)

---

## 1. High-Level Overview

### Purpose

HISP Mobile Tracker is an **offline-first Flutter mobile application** for collecting aggregate health data into [DHIS2](https://dhis2.org) (District Health Information Software), Ethiopia's national Health Management Information System. It was built by **HISP Ethiopia** in collaboration with the **Federal Ministry of Health**.

### Problem Solved

Health workers in rural Ethiopia need to enter health data (immunization counts, disease surveillance, facility reports) into DHIS2. Many operate in areas with unreliable or no internet connectivity. The solution must:

- Work **completely offline** — data is never lost when the network drops
- Sync automatically when connectivity returns
- Handle the **Ethiopian calendar** (Ge'ez calendar) for period selection
- Support **~38,000 organisation units** (health facilities) on the national instance
- Prevent data conflicts when multiple users edit the same form

### Users

- **Field health workers** — entering data at health posts/clinics
- **Supervisors** — reviewing data completeness
- **HIS officers** — at woreda (district) and zonal offices

### Major Features

1. Online + offline login (SHA-256 offline credential verification)
2. Offline-first data entry with Draft → Complete → Pending → Synced lifecycle
3. Automatic sync on connectivity return, login, and 5-minute heartbeat
4. Pull-then-push conflict resolution (newest wins, drafts always survive)
5. Server rejection handling with inline error display
6. Organisation unit tree browser (lazy-loaded, 38k units)
7. Ethiopian calendar period picker with fiscal year support
8. Client-side value validation per DHIS2 value types
9. Dashboard visualization with `fl_chart` (online only)
10. Multi-user isolation (one SQLite file per user)

---

## 2. Overall Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FLUTTER MOBILE APP                          │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────────┐ │
│  │  Presentation │  │  Domain      │  │         Data               │ │
│  │  (BLoC/Page)  │──│  (UseCase)   │──│  (Repository + DataSource) │ │
│  └──────┬───────┘  └──────────────┘  └────────────┬───────────────┘ │
│         │                                          │                 │
│  ┌──────▼──────────────────────────────────────────▼───────────────┐ │
│  │                    CORE INFRASTRUCTURE                          │ │
│  │  ┌────────────┐ ┌──────────────┐ ┌────────────┐ ┌────────────┐ │ │
│  │  │ AppSession │ │ MetadataSync │ │  Drift     │ │ Connectivity│ │ │
│  │  │ (Singleton)│ │ Service      │ │  Database  │ │  Service    │ │ │
│  │  └──────┬─────┘ └──────┬───────┘ └─────┬──────┘ └─────┬──────┘ │ │
│  │         │               │               │               │        │ │
│  │  ┌──────▼─────┐ ┌──────▼───────┐ ┌─────▼──────┐       │        │ │
│  │  │ Session    │ │ Metadata     │ │  SQLite    │       │        │ │
│  │  │ Service    │ │ Resources    │ │  (per-user) │       │        │ │
│  │  └────────────┘ └──────────────┘ └────────────┘       │        │ │
│  │                                                        │        │ │
│  │  ┌──────────────────┐  ┌──────────────┐  ┌────────────▼──────┐ │ │
│  │  │ SyncCoordinator  │  │ DataValueSync │  │ ConnectivityService│ │ │
│  │  │ (3-door auto)    │  │ (V2 conflict) │  │ (server ping)     │ │ │
│  │  └──────────────────┘  └──────────────┘  └───────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                              │                                       │
│                    ┌─────────▼─────────┐                             │
│                    │    ApiClient       │                             │
│                    │   (Dio + Auth)     │                             │
│                    └─────────┬─────────┘                             │
└──────────────────────────────┼──────────────────────────────────────┘
                               │ HTTPS (Basic Auth)
                    ┌──────────▼──────────┐
                    │    DHIS2 Server     │
                    │  (hmis-staging.moh  │
                    │   .gov.et/api)      │
                    └─────────────────────┘
```

### Data Flow: User Enters Data → Server Receives It

```
1. User types value in DataEntryCell
2. DataEntryBloc emits DataEntryValueChanged
3. User taps Save → DataEntrySave → DataEntryRepository saves as DRAFT to SQLite
4. User taps Complete → drafts promoted to PENDING
5. AutoSync (SyncCoordinator) detects pending values
6. DriftSyncManager.pushPending() → DataValueStore.pendingValues()
7. pushDataValueBatch() POSTs to /api/dataValueSets (max 500/batch)
8. Server responds with per-value verdicts
9. Accepted → SyncState.synced, Rejected → SyncState.error
10. Error cells turn red in the form with server's reason
```

---

## 3. Backend Analysis

### Technology Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | Flutter 3.x (CI pins 3.41.4) |
| **Language** | Dart (SDK >=3.0.0 <4.0.0) |
| **Build Tool** | Flutter build system + `build_runner` for code gen |
| **Local Database** | Drift 2.20.0 (ORM) over SQLite (`sqlite3_flutter_libs`) |
| **Secure Storage** | `flutter_secure_storage` (Android Keystore / iOS Keychain) |
| **HTTP Client** | Dio 5.7.0 |
| **State Management** | `flutter_bloc` 8.1.6 |
| **Navigation** | `go_router` 14.2.7 |
| **Charts** | `fl_chart` 1.2.0 |
| **Connectivity** | `connectivity_plus` 7.2.0 |
| **Offline Auth** | `crypto` 3.0.5 (SHA-256) |

### Folder Structure

```
lib/
├── main.dart                     # Composition root: singleton wiring + app launch
├── core/                         # Cross-cutting infrastructure (feature-agnostic)
│   ├── auth/                     #   Login lifecycle, credential storage, session singleton
│   │   ├── app_session.dart      #     Singleton session holder + router refresh trigger
│   │   ├── credential_store.dart #     SHA-256 offline verifier (never stores plaintext)
│   │   └── session_service.dart  #     Full login decision tree (online/offline/first/returning)
│   ├── constants/                #   API URLs, app metadata, storage keys
│   ├── data/                     #   Data value CRUD, push, sync, completeness, validation
│   │   ├── data_value_store.dart #     Local read/write for data values (draft/pending/synced/error)
│   │   ├── data_value_push.dart  #     Batch upload to DHIS2 (500/chunk, partial-success handling)
│   │   ├── data_value_sync.dart  #     Per-form pull + conflict resolution (V2 engine)
│   │   ├── completeness.dart     #     Dataset completion tracking + sync
│   │   ├── ethiopian_calendar.dart #   Full Ge'ez calendar with DHIS2 period ID generation
│   │   ├── ethiopian_period_service.dart # Bridge: calendar → selectable UI periods
│   │   ├── period_access.dart    #     Monotonic clock (tamper-resistant high-water mark)
│   │   ├── validation_service.dart #   Offline validation rule expression evaluator
│   │   └── value_type_validator.dart # Client-side per-DHIS2-type validation
│   ├── database/                 #   Drift schema (28 tables) + platform connections
│   │   ├── app_database.dart     #     Table definitions, per-user DB factory, retention
│   │   ├── app_database.g.dart   #     Generated (~15K lines)
│   │   └── connection/           #     native.dart (SQLite file) / web.dart (WASM)
│   ├── errors/                   #   Two-layer hierarchy: AppException + Failure
│   ├── metadata/                 #   DHIS2 metadata sync (13 entities + 9 link tables)
│   │   ├── metadata_resource.dart #    Abstract base: generic CRUD + full/delta sync
│   │   ├── metadata_sync_service.dart # Orchestrator: dependency-ordered sync
│   │   ├── organisation_unit.dart #   Scoped by captureRootUids (path:like filter)
│   │   ├── data_set.dart         #    Complex nested save (elements + org unit links)
│   │   └── ... (11 more entity files)
│   ├── network/                  #   HTTP client, connectivity probing, interceptors
│   │   ├── api_client.dart       #     Dio singleton + withBasicAuth factory
│   │   ├── connectivity_service.dart # Server-reachability pinger (not OS-level)
│   │   └── interceptors/         #     Auth (401→logout) + Logging (sanitized)
│   ├── router/                   #   go_router with auth guard
│   ├── storage/                  #   SecureStorage wrapper (Android/iOS keystore)
│   ├── sync/                     #   Auto-sync coordinator, manual sync, drift sync manager
│   │   ├── sync_coordinator.dart #     Three-door trigger: connectivity, login, heartbeat
│   │   ├── drift_sync_manager.dart #   Real SyncManager (push + pull)
│   │   └── manual_sync.dart      #    User-triggered with typed result
│   └── utils/                    #   Logger, HTTP date parser (web-safe)
├── features/                     # Feature modules (each owns its own data/domain/presentation)
│   ├── auth/                     #   Login page + full Clean Architecture
│   ├── capture/                  #   OU tree → dataset → section → period wizard
│   ├── data_entry/               #   The entry form (BLoC, collapsible table)
│   ├── home/                     #   App shell (Visualization/Capture toggle, filters)
│   ├── settings/                 #   Settings page (server URL, logout)
│   └── visualization/            #   DHIS2 dashboards with fl_chart (online only)
├── shared/                       # Shared UI components and theme
│   ├── theme/                    #   Colors, typography, dimensions, breakpoints, ThemeData
│   └── widgets/                  #   AppButton, AppTextField, FilterPanel, etc.
└── debug/                        # Developer-only screens (DB viewer, test login)
```

### Architecture Pattern: Feature-First Clean Architecture

The project follows **feature-first Clean Architecture** with three layers per feature:

```
features/
  <feature>/
    data/           ← Data sources, repository implementations
    domain/         ← Entities, abstract repositories, use cases
    presentation/   ← BLoC/Cubit, pages, widgets
```

**Why this pattern?**

- Each feature is self-contained — can be understood, tested, and modified independently
- The domain layer has zero Flutter/framework dependencies — pure Dart
- Repository interfaces in domain enable swapping implementations (online/offline/test)
- Feature-first (not layer-first) avoids deep cross-feature import chains

**Key deviation:** The `capture` and `visualization` features do NOT use BLoC — they use stateful widgets with direct repository calls. This is a deliberate pragmatic choice for linear workflows where BLoC adds unnecessary ceremony.

### Request Flow (Login Example)

```
User enters credentials in LoginForm widget
  → AuthBloc receives LoginSubmitted event
    → LoginUseCase.execute() called
      → AuthRepositoryImpl.login() called
        → SessionService.login(serverUrl, username, password, online: true)
          → ApiClient.withBasicAuth() created
          → GET /api/me.json → server confirms credentials
          → HTTP Date header parsed → server time captured
          → AppDatabase.forUser(username) opened
          → CredentialStore.store() → SHA-256 hash persisted
          → MetadataSyncService.syncMetadata() or syncMetadataDelta()
            → Full sync: 13 resources in dependency order
            → Delta sync: id+lastUpdated diff per resource
          → Returns LoginResult.onlineFirstSync or onlineReturning
        → AuthRepositoryImpl creates ApiClient for sync layer
        → AppSession.instance.sessionChanged() → triggers router redirect
      → AuthBloc emits AuthAuthenticated(user)
    → Router redirect: /login → /home
```

### Authentication

**Scheme:** HTTP Basic Auth (base64-encoded `username:password`)

**Login Decision Tree** (in `SessionService.login()`):

```
                    Login Attempt
                         │
                    ┌────▼────┐
                    │ Online? │
                    └────┬────┘
                   Yes   │   No
              ┌──────────┘    └──────────┐
              ▼                          ▼
     GET /api/me.json            Database exists?
     (verify credentials)              │
         │                        Yes   │   No
    ┌────▼────┐              ┌──────────┘    └──────┐
    │  200 OK │              ▼                     ▼
    │  401    │        Verify SHA-256         offlineNoCache
    └────┬────┘        hash locally         (needs connection)
         │              │
    ┌────▼────┐    ┌────▼────┐
    │ Open DB │    │Match?   │
    │ Store   │    └────┬────┘
    │ verifier│    Yes   │   No
    └────┬────┘    ┌─────┘    └───┐
         │         ▼              ▼
    ┌────▼────┐  offline      invalidCredentials
    │First    │  (open DB)
    │time?    │
    └────┬────┘
   Yes   │   No
  ┌──────┘    └──────┐
  ▼                  ▼
Background         Fire-and-forget
full sync          delta sync
```

**Offline Credential Verification** (`CredentialStore`):

```dart
// Formula: SHA-256(salt : serverUrl : username : password)
// salt is random, stored alongside the hash
// serverUrl binding prevents cross-instance spoofing
String _hash(String salt, String url, String user, String pass) {
  final u = url.replaceAll(RegExp(r'/+$'), '');
  final bytes = utf8.encode('$salt:$u:$user:$pass');
  return sha256.convert(bytes).toString();
}
```

**Clock Tamper Detection:** On every login (online or offline), `PeriodAccess.checkAtSessionStart()` compares `DateTime.now()` against the high-water mark in `SyncInfoTable`. A backwards jump >2 minutes sets a persistent `clockTampered` flag that blocks past-period entry until a server anchor clears it.

**Wipe Protection:** `SessionService.wipe()` throws `StateError` unless `confirmedDataLoss: true` is passed. The caller must show `unsyncedWorkCount()` and get explicit user confirmation first.

### Database

**28 Drift/SQLite tables** organized in four groups:

| Group | Tables | Purpose |
|-------|--------|---------|
| **Metadata Entities** (13) | OrgUnitsTable, DataSetsTable, DataElementsTable, SectionsTable, IndicatorsTable, CategoriesTable, CategoryOptionsTable, CategoryCombosTable, CategoryOptionCombosTable, OptionSetsTable, OptionsTable, DataElementGroupsTable, ValidationRulesTable | Mirror DHIS2 metadata locally |
| **Link/Join Tables** (9) | DataSetElementsTable, DataSetOrgUnitsTable, SectionDataElementsTable, SectionIndicatorsTable, SectionGreyFieldsTable, DataElementGroupMembersTable, CategoryCategoryOptionsTable, CategoryComboCategoriesTable, CategoryOptionComboOptionsTable | Many-to-many relationships |
| **Global** (4) | UsersTable, AttributesTable, AttributeValuesTable, SyncInfoTable | User profile, generic attributes, sync metadata |
| **Data** (2) | DataValuesTable, CompleteDataSetRegistrationsTable | Collected field data |

**Per-user isolation:** Each user gets their own SQLite file (`hisp_{userKey}.sqlite`). The key is derived from `sanitizeUserKey(username)`:

```dart
static String sanitizeUserKey(String raw) =>
    raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
// 'Nurse.Alem@HC' -> 'nurse_alem_hc'
```

**Data Values — 5-column composite primary key:**

```dart
Set<Column> get primaryKey => {
  dataElementUid, period, orgUnitUid,
  categoryOptionComboUid, attributeOptionComboUid,
};
```

**SyncState lifecycle:**

```
draft → (on Complete) → pending → (on successful push) → synced
                                         │
                                         └→ (on server rejection) → error
```

**Migrations:** Schema version is currently 1 (frozen baseline). The `onUpgrade` callback is deliberately fail-loud — a missing migration step throws `UnsupportedError` rather than corrupting field data.

**Performance:** WAL journal mode, foreign keys enabled, batched upserts, background JSON decoding.

### API Endpoints (DHIS2)

| Endpoint | Method | Purpose | Used By |
|----------|--------|---------|---------|
| `/api/me.json` | GET | Auth probe + user profile + capture root UIDs | `SessionService`, `MetadataSyncService` |
| `/api/system/ping` | GET | Server reachability check (no auth) | `ConnectivityService` |
| `/api/dataElements.json` | GET | Fetch data element metadata | `DataElementResource` |
| `/api/dataSets.json` | GET | Fetch dataset metadata | `DataSetResource` |
| `/api/organisationUnits.json` | GET | Fetch org units (scoped by path) | `OrgUnitResource` |
| `/api/sections.json` | GET | Fetch dataset sections | `SectionResource` |
| `/api/categories.json` | GET | Fetch categories | `CategoryResource` |
| `/api/categoryCombos.json` | GET | Fetch category combos | `CategoryComboResource` |
| `/api/categoryOptionCombos.json` | GET | Fetch category option combos | `CategoryOptionCombosResource` |
| `/api/optionSets.json` | GET | Fetch option sets | `OptionSetResource` |
| `/api/options.json` | GET | Fetch options | `OptionResource` |
| `/api/indicators.json` | GET | Fetch indicators | `IndicatorResource` |
| `/api/dataElementGroups.json` | GET | Fetch data element groups | `DataElementGroupResource` |
| `/api/validationRules.json` | GET | Fetch validation rules | `ValidationRulesResource` |
| `/api/categoryOptions.json` | GET | Fetch category options | `CategoryOptionResource` |
| `/api/attributes.json` | GET | Fetch attributes | `AttributeResource` |
| `/api/dataValueSets` | POST | Bulk push data values (max 500/batch) | `DataValueSync` |
| `/api/dataValueSets` | GET | Pull server values for a form | `DataValueSync` |
| `/api/completeDataSetRegistrations` | POST | Mark dataset complete on server | `CompletenessSync` |
| `/api/completeDataSetRegistrations` | DELETE | Uncomplete on server | `CompletenessSync` |
| `/api/analytics.json` | GET | Run chart analytics queries | `ChartRepositoryImpl` |

**Sync strategy:** Metadata is fetched via `fields=` field selection (not all fields, reducing payload). Delta sync uses `filter=id:gte:{lastId}` + `filter=lastUpdated:gte:{lastSyncedAt}` to fetch only changed records.

### Business Logic

Key business rules and where they live:

| Rule | Location |
|------|----------|
| Data values start as drafts, never pushed until form completed | `DataValueStore.setValue(draft: true)` → `DataValueStore.promoteDrafts()` |
| Conflict resolution: newest wins, drafts always survive, 2-min tolerance | `DataValueSync.syncForm()` in `core/data/data_value_sync.dart` |
| Clock tamper: backwards jump >2min blocks past-period entry | `PeriodAccess.checkAtSessionStart()` in `core/data/period_access.dart` |
| Period never goes backwards (monotonic HWM) | `PeriodAccess.effectiveNow()` returns `max(now, highWaterMark)` |
| Offline login requires prior database existence | `SessionService.login()` checks `_databaseExistsFor(userKey)` |
| Wipe requires explicit user confirmation of data loss | `SessionService.wipe(confirmedDataLoss: true)` |
| Max 500 values per push batch | `pushDataValueBatch()` in `core/data/data_value_push.dart` |
| Server 409 responses are NOT transport failures — body has per-value verdicts | `pushDataValueBatch()` parses `conflicts[].indexes` |
| Duplicate default COC repair | `DataEntryRepositoryImpl` remaps values to canonical COC |
| Retention: only synced rows outside allowed periods are purged | `AppDatabase.purgeOutsideRetention()` |
| Validation rules: violations WARN but never block completion | `ValidationService` in `core/data/validation_service.dart` |

### Error Handling

**Two-layer hierarchy:**

- **Exceptions** (data layer): `NetworkException`, `UnauthorizedException`, `ServerException`, `TimeoutException`, `CacheException`
- **Failures** (domain layer): `NetworkFailure`, `AuthFailure`, `ServerFailure`, `TimeoutFailure`, `CacheFailure`, `UnknownFailure`

Each carries a default user-facing message. Repositories catch exceptions and return typed failures. BLoCs catch failures and emit error states with display messages.

### Security

| Aspect | Implementation | Status |
|--------|---------------|--------|
| **Auth** | HTTP Basic Auth over HTTPS | Functional, not ideal (no tokens) |
| **Offline credentials** | SHA-256 salted hash, never stores plaintext | Good |
| **Secure storage** | `flutter_secure_storage` (Android Keystore / iOS Keychain) | Good |
| **HTTPS** | Enforced in release builds | Good |
| **401 handling** | `AuthInterceptor` purges session → redirects to login | Good |
| **Authorization logging** | Headers redacted (`***REDACTED***`) in logs | Good |
| **Input validation** | Per-DHIS2 value type client-side validation | Good |
| **Wipe protection** | Requires explicit data-loss confirmation | Good |
| **Certificate pinning** | Not implemented | Gap |
| **DB encryption** | Not implemented | Gap |
| **R8/ProGuard** | Not configured | Gap |
| **CSRF/XSS** | N/A (mobile app, not web) | N/A |

### Performance

**Strengths:**

- **Background JSON decoding** — `BackgroundTransformer` on Dio prevents UI freezes on large metadata payloads
- **Delta metadata sync** — only fetches changed records (id + lastUpdated diff)
- **Lazy org unit tree** — children loaded one level at a time, critical for 38k units
- **Chunked push** — 500 values per batch prevents mid-transfer waste from killing the whole upload
- **WAL journal mode** — concurrent reads during writes
- **Batched upserts** — Drift transactions for metadata saveAll

**Potential Bottlenecks:**

1. **15,410-line generated file** — `app_database.g.dart` slows IDE analysis but not runtime
2. **No metadata caching for visualization** — indicator/data element group pickers hit the server every time
3. **`DataEntryCell` rebuilds** — every keystroke triggers a BLoC event → full table rebuild
4. **Single-threaded auto-sync** — `SyncCoordinator` only pushes; a stuck push blocks metadata pulls
5. **No pagination for analytics queries** — large datasets could return massive payloads

---

## 4. Frontend Analysis

### Technology Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | Flutter (Material 3) |
| **Language** | Dart 3.x |
| **State Management** | flutter_bloc 8.1.6 (AuthBloc, DataEntryBloc) |
| **Navigation** | go_router 14.2.7 (3 named routes + Navigator.push for details) |
| **Theme** | Custom design token system (colors, typography, dimensions) |
| **Charts** | fl_chart 1.2.0 |
| **Icons** | Material Icons + flutter_svg |

### State Management

**flutter_bloc** is the primary pattern, but used surgically — not everywhere:

| Feature | State Approach | Why |
|---------|---------------|-----|
| **auth** | `AuthBloc` (events/states) | Complex multi-step login with error handling |
| **data_entry** | `DataEntryBloc` (events/states) | In-memory form state with validation + save |
| **capture** | `StatefulWidget` with local state | Linear wizard flow, widget-local state suffices |
| **visualization** | `StatefulWidget` with local state | Builder pattern, widget-local state suffices |
| **home** | `StatefulWidget` with local state | Shell/container, filter state is presentation-only |
| **settings** | `StatefulWidget` with local state | Simple read-only display + one dialog |

**Global state:** `AppSession` singleton (extends `ChangeNotifier`) holds the login state, API client, and session service. It is the `refreshListenable` for `go_router`, triggering reactive redirects on login/logout.

### Routing

```
GoRouter (refreshListenable: AppSession.instance)
  │
  ├── /login          → LoginPage (supports ?reason=session-expired)
  ├── /home           → HomePage (authenticated shell)
  ├── /settings       → SettingsPage
  └── /debug/db       → DebugSyncScreen (kDebugMode only, not linked from UI)

Navigator.push (MaterialPageRoute — intentional, not in GoRouter):
  ├── OU tree → DatasetSelectionPage
  ├── DatasetSelectionPage → SectionSelectionPage
  ├── SectionSelectionPage → PeriodSelectionPage
  ├── PeriodSelectionPage → DataEntryPage
  └── ChartsListView → ChartViewPage
```

The auth guard in `GoRouter.redirect`:

```dart
redirect: (context, state) {
  final loggedIn = AppSession.instance.isLoggedIn;
  final goingToLogin = state.matchedLocation == login;
  if (!loggedIn && !goingToLogin) return login;
  if (loggedIn && goingToLogin) return home;
  return null;
},
```

### Components

**Reusable widgets** (`shared/widgets/`):

| Widget | Purpose | Used In |
|--------|---------|---------|
| `AppButton` | 4-variant button (primary/secondary/outline/ghost) with loading state | Login, Settings, DataEntry |
| `AppTextField` | Styled form field with focus-state border | Login, Settings |
| `AppLoader` | Centered spinner + optional message | Login, Data loading states |
| `AppLoadingOverlay` | Semi-transparent overlay with spinner | DataEntry saving |
| `ConnectivityIndicator` | Online/offline pill badge with animated expand | HomeAppBar |
| `FilterPanel` | 3-section filter (date/org unit/sync state) | Home Capture mode |
| `SegmentedToggle` | Animated pill toggle with sliding thumb | Home (Viz/Capture) |
| `ServerUrlDialog` | Server URL editor dialog | Login, Settings |
| `SyncSnackbar` | Colored snackbar for sync results | Home manual sync |

### Forms

**DataEntryCell** (`data_entry/presentation/widgets/data_entry_cell.dart`) — the most complex form widget:

- `BOOLEAN` → tap to cycle Yes/No/Empty
- `TRUE_ONLY` → checkbox
- Option-set → bottom sheet picker (validates only option CODES)
- `NUMBER`/`INTEGER`/etc → filtered text field with live validity border
- Server-rejected cells show red background + long-press tooltip

**Validation:** `invalidEditedValues()` function checks only user-modified values against their element's `valueType` before allowing save.

### Styling

**Design Token System** (`shared/theme/`):

| File | Content |
|------|---------|
| `app_colors.dart` | DHIS2 brand colors (#2C6EBA primary), status colors, gradients |
| `app_text_styles.dart` | Roboto font family, 13 style categories |
| `app_dimensions.dart` | 11 spacing levels, 7 border radii, 7 icon sizes, button/input heights |
| `app_breakpoints.dart` | Mobile (<600px), tablet/desktop, `ResponsiveContent` wrapper |
| `app_theme.dart` | Material 3 `ThemeData` assembly from all above tokens |

No dark theme yet (listed on roadmap).

---

## 5. Complete Folder Walkthrough

### `lib/core/` — The backbone

Every feature depends on `core/`. It has zero Flutter widget imports (except via `AppSession` extending `ChangeNotifier`). This is the **infrastructure layer** — networking, database, sync, auth, and shared business logic.

**Communication:** Features import core types directly. Core never imports features. This enforces unidirectional dependency flow.

### `lib/features/auth/` — The gateway

Full Clean Architecture: Entity → Repository (abstract) → UseCase → BLoC → Page. The most architecturally complete feature. `AuthRepositoryImpl` is the bridge between the Clean Architecture pattern and the `SessionService` offline layer.

### `lib/features/capture/` — The data collection wizard

The deepest navigation chain: OU tree → dataset → section → period → entry form. Uses stateful widgets (no BLoC) because the flow is linear. `CaptureRepositoryImpl` is 100% offline — all data comes from the local SQLite database (which contains synced metadata from the server).

### `lib/features/data_entry/` — The heart of data collection

The most complex feature. `DataEntryRepositoryImpl` handles: opening a form (online pull + conflict resolution), saving as draft, completing (promote drafts + push), server rejection handling, duplicate COC repair, and validation rules. The `DataEntryBloc` manages in-memory form state.

### `lib/features/home/` — The shell

Presentation-only. Composes VisualizationView and CaptureOrgUnitView. Owns the filter panel, search, manual sync, and the app bar. No business logic — delegates everything to embedded features.

### `lib/features/visualization/` — Online analytics

Online-only. Builds DHIS2 charts by hitting the analytics API. No BLoC. `ChartRepositoryImpl` handles metadata pickers and analytics queries. Charts are persisted as JSON in the `syncInfo` key-value table (avoids schema migration).

### `lib/shared/` — The design system

Theme tokens + reusable widgets. Imported by all features. Zero business logic. Purely presentation concerns.

### `lib/debug/` — Developer tools

Three screens for inspecting the offline database and testing sync. Not shipped to production (not linked from UI, but not tree-shaken either).

---

## 6. Dependency Analysis

### Critical Packages

| Package | Purpose | Verdict |
|---------|---------|---------|
| `flutter_bloc` | State management | **Essential.** Clean event/state pattern |
| `dio` | HTTP client | **Essential.** Background transformer, interceptor chain |
| `drift` | SQLite ORM | **Essential.** Type-safe queries, per-user DB isolation |
| `flutter_secure_storage` | Keystore/Keychain | **Essential.** Secure credential storage |
| `go_router` | Declarative routing | **Good choice.** Auth guard via refreshListenable |
| `connectivity_plus` | OS-level connectivity | **Necessary.** Enhanced with server pings |
| `fl_chart` | Charts | **Essential** for visualization |
| `crypto` | SHA-256 | **Essential** for offline auth |
| `intl` | Date formatting | **Used** for Ethiopian calendar and HTTP dates |
| `logger` | Structured logging | **Good.** Level-gated, sanitized |
| `flutter_svg` | SVG rendering | **Minimal use.** Could potentially be removed |
| `drift_db_viewer` | Debug DB browser | **Dev-only.** Should be in dev_dependencies |

### Possible Improvements

- `get_it` or `riverpod` for dependency injection (currently manual wiring in pages)
- Move `drift_db_viewer` to `dev_dependencies`
- Consider `cached_network_image` if image loading is added

---

## 7. Design Patterns

| Pattern | Where Used | Description |
|---------|-----------|-------------|
| **Repository** | All features | Abstract interface in `domain/`, concrete impl in `data/` |
| **Use Case** | `LoginUseCase`, `LogoutUseCase`, `GetDataElementsUseCase`, etc. | Single-responsibility business actions |
| **BLoC** | `AuthBloc`, `DataEntryBloc` | Event-driven state machine for complex flows |
| **Singleton** | `AppSession.instance`, `DriftSyncManager.instance`, `ConnectivityService.instance` | Global infrastructure |
| **Template Method** | `MetadataResource` (abstract base) | Subclasses provide table/fields; base provides sync logic |
| **Observer** | `AppSession extends ChangeNotifier`, `ConnectivityService` | Reactive state propagation |
| **Strategy** | `SyncManager` interface (`DriftSyncManager` vs `NoopSyncManager`) | Swappable implementations |
| **Adapter** | `NetworkInfo` abstract (`ConnectivityNetworkInfo` vs `AlwaysOnlineNetworkInfo`) | Testability |
| **Composite Key** | DataValuesTable (5-column PK) | Correctly models DHIS2 identity |
| **State Machine** | SyncState enum (draft → pending → synced/error) | Explicit data lifecycle |
| **Decorator** | `AuthInterceptor`, `LoggingInterceptor` on Dio | Layered request processing |
| **Composition Root** | `main.dart` | All singleton wiring in one place |

---

## 8. Security Review

### Good Practices

1. **Never stores plaintext passwords** — SHA-256 salted hash for offline verification
2. **Per-user database isolation** — multi-user on one device doesn't leak data
3. **HTTPS-only in release** — plain HTTP blocked at build level
4. **401 auto-logout** — `AuthInterceptor` immediately ends session on 401
5. **Log sanitization** — Authorization headers redacted in all logging
6. **Wipe protection** — explicit user confirmation required before data destruction
7. **Clock tamper detection** — prevents backdating entries
8. **Input validation** — per-DHIS2 value type before queuing
9. **Release signing enforcement** — build fails without keystore

### Potential Vulnerabilities

1. **No certificate pinning** — MITM attacks possible on compromised networks
2. **Basic Auth** — credentials sent with every request (no token rotation)
3. **No DB encryption** — SQLite files readable on rooted devices
4. **No R8/ProGuard** — code not obfuscated in release builds
5. **`allowBackup`** — potentially enabled by default in Android manifest
6. **Offline verifier uses SHA-256** — acceptable but not a password hash function

### Suggested Improvements

1. Add certificate pinning for the DHIS2 server
2. Migrate to OAuth2 when DHIS2 supports it
3. Enable SQLCipher or `drift` encryption for database
4. Configure R8 code obfuscation
5. Set `android:allowBackup="false"` in manifest
6. Consider Argon2/bcrypt for the offline verifier

---

## 9. Performance Review

### Strengths

- **Background JSON decoding** — `BackgroundTransformer` prevents UI freezes
- **Delta metadata sync** — only fetches changed records
- **Lazy org unit tree** — critical for 38k units
- **Chunked push** — 500 values per batch
- **WAL journal mode** — concurrent reads during writes
- **Batched upserts** — Drift transactions

### Optimization Recommendations

1. Use `RepaintBoundary` around `DataEntryTable` cells
2. Add `buildWhen`/`listenWhen` to BLoC listeners for selective rebuilds
3. Cache visualization metadata in SQLite
4. Consider `Isolate.spawn` for large metadata sync processing
5. Add metadata caching for chart builder pickers

---

## 10. Code Quality Review

| Category | Score | Notes |
|----------|-------|-------|
| **Code Organization** | 9/10 | Feature-first Clean Architecture is consistent |
| **Naming Conventions** | 9/10 | Clear, consistent, self-documenting |
| **SOLID Principles** | 8/10 | Strong DI, good SRP, excellent template method pattern |
| **DRY** | 7/10 | `MetadataResource` eliminates duplication; but `AuthRepositoryImpl` manually constructed in 3 places |
| **KISS** | 8/10 | Resisted over-engineering; BLoC only where needed |
| **Separation of Concerns** | 9/10 | Network-blind resources, per-user isolation, clean boundaries |
| **Maintainability** | 8/10 | 17-file documentation suite, sync-critical test coverage |
| **Scalability** | 7/10 | Feature-first scales well; 28-table AppDatabase could be a bottleneck |

**Overall: 8.1/10**

---

## 11. Complete Request Lifecycle

### User Opens the App

```
1. main.dart
   → WidgetsFlutterBinding.ensureInitialized()
   → Lock portrait orientation
   → Apply stored server URL override (if any)
   → Start SyncCoordinator (3-door auto-sync)
   → Start ConnectivityService (server ping every 30s)
   → runApp(HispMobileTrackerApp)

2. GoRouter evaluates initial route
   → AppSession.instance.isLoggedIn == false
   → Redirects to /login

3. LoginPage renders
   → AuthBloc created with LoginUseCase → AuthRepositoryImpl
   → User enters credentials
```

### User Logs In (Online, First Time)

```
4. User taps Login
   → AuthBloc receives LoginSubmitted
   → AuthBloc emits AuthLoginInProgress
   → LoginUseCase.execute() → AuthRepositoryImpl.login()

5. AuthRepositoryImpl
   → Reads server URL from SecureStorage (or default)
   → Checks connectivity via NetworkInfo
   → Calls SessionService.login(serverUrl, username, password, online: true)

6. SessionService.login()
   → Creates ApiClient.withBasicAuth
   → GET /api/me.json (verify credentials)
   → Parses HTTP Date header → server time
   → Opens AppDatabase.forUser(username) → creates hisp_{key}.sqlite
   → Stores SHA-256 offline verifier
   → Checks if first sync (lastSyncedAt == null)
   → Creates MetadataSyncService
   → Launches _runInitialSync() in background
   → Returns LoginResult.onlineFirstSync

7. AuthRepositoryImpl
   → Creates ApiClient for sync layer
   → Calls AppSession.instance.sessionChanged()

8. SessionService (background)
   → syncMetadata() runs in dependency order:
     categoryOptions → categories → categoryCombos →
     categoryOptionCombos → optionSets → options → attributes →
     dataElements → indicators → dataElementGroups →
     organisationUnits (scoped!) → dataSets → sections → validationRules
   → Each resource: GET /api/{resource}.json → parse → saveAll(batch)
   → On completion: InitialSyncState.done

9. AppSession.sessionChanged() triggers GoRouter refresh
   → isLoggedIn == true
   → Redirects to /home
```

### User Navigates to Data Entry

```
10. HomePage renders
    → SegmentedToggle defaults to Capture mode
    → CaptureOrgUnitView embedded (lazy OU tree)

11. User taps an org unit → pushes DatasetSelectionPage
    → CaptureRepository.getDataSetsForOrgUnit() → reads from SQLite
    → Shows dataset cards with sync status badges

12. User taps a dataset → pushes SectionSelectionPage
    → CaptureRepository.getSections() → reads from SQLite
    → If no sections → auto-skips to PeriodSelectionPage

13. User selects a period → pushes PeriodSelectionPage
    → EthiopianPeriodService generates selectable periods
    → PeriodAccess.statusOf() determines open/expired/notYetOpen
    → Creates DataEntryBloc

14. User taps "Enter Data" → pushes DataEntryPage
    → DataEntryBloc receives DataEntryLoad
    → DataEntryRepository.getDataElements() → reads from SQLite
    → DataEntryRepository.getDataValues() → reads from SQLite
    → If online: DataValueSync.syncForm() → pull server values + resolve conflicts
    → DataEntryBloc emits DataEntryLoaded
```

### User Enters and Saves Data

```
15. User types a value in DataEntryCell
    → DataEntryBloc receives DataEntryValueChanged
    → Updates in-memory dataValues map
    → DataEntryBloc emits DataEntryLoaded(hasChanges: true)

16. User taps Save
    → DataEntryBloc receives DataEntrySave
    → DataEntryRepository.saveDataValues() → DataValueStore.setValue(draft: true)
    → Values written to SQLite with SyncState.draft
    → DataEntryBloc emits DataEntrySaved

17. User taps Complete
    → DataEntryRepository.completeDataSet()
    → DataValueStore.promoteDrafts() → draft → pending
    → CompletenessStore.setComplete() → writes completion record
    → If online: best-effort push after complete
    → Server response: accepted → SyncState.synced, rejected → SyncState.error
```

### Auto-Sync Pushes Data

```
18. SyncCoordinator detects connectivity change (or heartbeat fires)
    → DriftSyncManager.pushPending()
    → DataValueStore.pendingValues() → all pending rows
    → pushDataValueBatch() → POST /api/dataValueSets (500/chunk)
    → Server responds with ImportSummary
    → Per-value: accepted → synced, rejected → error (with server message)
    → CompletenessSync.pushPending() → POST/DELETE completion registrations
```

---

## 12. Beginner Learning Guide

### Reading Order

**Phase 1: Understand the Big Picture (Day 1)**

1. `README.md` — project overview, features, tech stack
2. `docs/01-getting-started.md` — setup
3. `docs/02-architecture.md` — Clean Architecture explanation
4. `docs/03-application-workflow.md` — end-to-end data flow with diagrams
5. `lib/main.dart` — 64 lines, the composition root

**Phase 2: Understand Auth & Session (Day 2)**

6. `lib/core/auth/session_service.dart` — the login decision tree (261 lines)
7. `lib/core/auth/credential_store.dart` — offline credential verification
8. `lib/core/auth/app_session.dart` — singleton session holder
9. `lib/features/auth/` — full Clean Architecture example (all 10 files)

**Phase 3: Understand the Database (Day 3)**

10. `lib/core/database/app_database.dart` — 28 tables, per-user isolation
11. `docs/06-database.md` — table groups, sync state, retention
12. `lib/core/metadata/metadata_resource.dart` — the template method pattern
13. `lib/core/metadata/metadata_sync_service.dart` — dependency-ordered sync

**Phase 4: Understand Offline & Sync (Day 4)**

14. `OFFLINE_INTEGRATION.md` or `docs/07-offline-and-sync.md`
15. `lib/core/data/data_value_store.dart` — draft/pending/synced lifecycle
16. `lib/core/data/data_value_sync.dart` — V2 conflict resolution
17. `lib/core/data/data_value_push.dart` — batch upload
18. `lib/core/sync/sync_coordinator.dart` — three-door auto-sync

**Phase 5: Understand Data Entry (Day 5)**

19. `lib/features/data_entry/` — BLoC + repository + widgets
20. `lib/core/data/ethiopian_calendar.dart` — period system
21. `lib/core/data/period_access.dart` — clock tamper resistance

**Phase 6: Understand the UI Layer (Day 6)**

22. `lib/shared/theme/` — design token system
23. `lib/shared/widgets/` — reusable components
24. `lib/features/home/` — the app shell
25. `lib/features/capture/` — the wizard flow
26. `lib/features/visualization/` — online analytics

**Phase 7: Understand Testing & CI (Day 7)**

27. `test/` — in-memory databases, canned adapters
28. `.github/workflows/ci.yml` — analyze + test pipeline
29. `docs/13-code-conventions.md` — team conventions

### Core Files (Read These First)

- `lib/core/auth/session_service.dart` — the brain of the app
- `lib/core/database/app_database.dart` — the heart of the app
- `lib/core/data/data_value_sync.dart` — the most sophisticated business logic
- `lib/core/metadata/metadata_resource.dart` — the pattern that eliminates duplication

### Files to Ignore Initially

- `lib/debug/` — dev-only tools
- `lib/core/database/app_database.g.dart` — generated code (15K lines)
- `ministry_presentation/` — separate presentation materials
- `docs/` — reference after understanding the code

---

## 13. Final Summary

### Backend Architecture

The "backend" is a **local-first data layer** built on Drift/SQLite with a sync engine that bridges to DHIS2. The key insight is that the server is treated as a **sync target**, not a live dependency. `MetadataResource` provides a template-method pattern for 13 DHIS2 entities, while `DataValueStore` + `DataValueSync` + `DataValuePush` handle the collected data lifecycle. The V2 conflict resolution engine (draft-always-wins, newest-wins with 2-minute tolerance) is the most sophisticated piece of business logic.

### Frontend Architecture

Material 3 Flutter app with a clean design token system and surgical use of BLoC (only for auth and data entry). The capture workflow is a 5-step wizard driven by `Navigator.push`. The home shell composes visualization and capture views behind a segmented toggle. The theme system is well-structured with proper separation of colors, typography, dimensions, and breakpoints.

### Strengths

1. **Offline-first is genuinely implemented**, not bolted on — the local DB is the UI's source of truth
2. **Per-user database isolation** — multi-user on shared devices works correctly
3. **Exceptional documentation** — 17-file docs suite, inline comments explain "why not what"
4. **Clock tamper resistance** — monotonic HWM prevents backdating entries
5. **Test infrastructure** — in-memory databases + canned adapters = fast, isolated tests
6. **Ethiopian calendar integration** — deeply embedded, not an afterthought
7. **Clean dependency direction** — core never imports features; features import core

### Weaknesses

1. **No dependency injection framework** — manual wiring in pages leads to duplication
2. **No DB encryption** — data at rest vulnerable on rooted devices
3. **Basic Auth without tokens** — credentials in every request
4. **Debug screens in production build** — not tree-shaken
5. **Visualization is online-only** — no offline chart cache
6. **`drift_db_viewer` in production dependencies** — should be dev-only
7. **Three places manually construct `AuthRepositoryImpl`** — DRY violation

### Improvement Suggestions

1. Add `get_it` or `riverpod` for DI (eliminate manual construction in pages)
2. Enable DB encryption (SQLCipher or drift encryption)
3. Move `drift_db_viewer` to `dev_dependencies`
4. Add certificate pinning for the DHIS2 server
5. Cache visualization metadata locally for offline chart viewing
6. Extract `AuthRepositoryImpl` construction into a single factory/provider
7. Add R8 code obfuscation for release builds
8. Consider splitting `SessionService` (auth logic + DB lifecycle + sync orchestration)

### Overall Architecture Rating: **8.5 / 10**

This is a well-engineered mobile application that correctly solves the hard problem of offline-first health data collection. The architecture is clean, the codebase is well-documented, and the team made smart pragmatic decisions (BLoC only where needed, feature-first structure, no over-engineering). The main gaps are in security hardening (encryption, pinning, token auth) and developer experience (DI framework, generated boilerplate reduction). For a health data collection app targeting mid-range Android devices in rural Ethiopia, this is a solid foundation.

---

*Document generated from codebase analysis of `hisp_mobile_trucker` repository.*
*Developed by HISP Ethiopia for the Ministry of Health.*
