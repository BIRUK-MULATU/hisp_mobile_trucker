# Features

A tour of every feature module under `lib/features/`, plus the dev-only tools under
`lib/debug/` and the shared UI kit under `lib/shared/`.

## auth (`lib/features/auth/`)

Full three-layer split. Domain: `AuthRepository` interface, `UserEntity`/`OrgUnitEntity`,
`LoginUseCase`, `LogoutUseCase`. Data: `AuthRepositoryImpl` (the online/offline branching
described in [Authentication & Security](04-authentication-and-security.md)),
`AuthRemoteDataSource`/`AuthRemoteDataSourceImpl` (legacy — see note below),
`UserModel`/`OrgUnitModel`. Presentation: `AuthBloc`, `LoginPage`, `LoginForm`.

**A transitional detail worth knowing:** `AuthRepositoryImpl`'s doc comment explains that
the legacy `AuthRemoteDataSource` is still called after *online* logins "as transitional
glue" — it persists the Basic token + full `/me` payload that the capture and data-entry
features' *not-yet-fully-migrated-to-Drift* remote data sources still read from
`SecureStorage`. In practice, capture and data_entry now read from the local database
directly (`CaptureRepositoryImpl`, `DataEntryRepositoryImpl` both go straight to
`SessionService.db`), so this glue is closer to legacy than load-bearing — but don't delete
`AuthRemoteDataSourceImpl`'s call without checking nothing still depends on the
`SecureStorage` copies of `user_data`/`org_units` it writes.

Login form validation (`login_form.dart`): username/password trimmed, non-empty required,
password minimum 4 characters, client-side only (the server is the real authority via the
online path, or the verifier via the offline path).

## capture (`lib/features/capture/`)

Org unit tree → dataset → section → period navigation. Fully offline — everything reads from
the local Drift database via `CaptureRepositoryImpl`, no network calls in this feature at
all (network happens later, inside data_entry, when a form actually opens).

- **`getOrgUnitChildren(parentId)`** — one tree level at a time (never the whole ~38,000-unit
  national hierarchy), plus a grouped child-count query so the tree UI can show expand arrows
  without a second round-trip per node.
- **`getDataSetsForOrgUnit(orgUnitId)`** — distinguishes "no metadata synced yet" (throws
  `CacheException` prompting an online login) from "genuinely nothing assigned here", and
  annotates every dataset with a `SyncStatus.synced`/`unsynced` chip sourced from
  `DataValueStore.unsyncedDataSetsAt()`.
- **`getUserReports()`** — the "Report Period" view: every report (completed or in-progress)
  the user has touched, across **all** organisation units, built by scanning
  `CompleteDataSetRegistrationsTable` and any non-synced `DataValuesTable` rows and joining
  them through `DataSetElementsTable`. A report whose completion is done but still has
  drafts is reported as `ReportStatus.incomplete` — reopening a completed form for
  corrections un-finishes it in this view, which is intentional.

Pages: `OrgUnitFilterPage`, `DatasetSelectionPage` (also hosts the Report Period tab),
`PeriodSelectionPage`, `SectionSelectionPage`. View: `CaptureOrgUnitView` (the tree browser
embedded in Home's Capture mode — at 794 lines, the largest hand-written file in the app; a
natural candidate to split if you're touching it significantly).

## data_entry (`lib/features/data_entry/`)

The entry form itself. See [State Management](08-state-management.md#dataentrybloc-libfeaturesdata_entrypresentationblocdata_entry_blocdart)
for the Bloc and [Offline & Sync](07-offline-and-sync.md) for the save/complete/sync
mechanics in depth.

`DataEntryRepositoryImpl` is fully offline-first: `getDataElements` and `getDataValues` read
from local metadata/data tables (with a best-effort `DataValueSync.syncForm()` call first, if
online, that never blocks or fails the read); `saveDataValues` always writes locally as
`draft`; `completeDataSet` promotes drafts and attempts a best-effort push;
`uncompleteDataSet` reopens a completed form for further edits (drafts stay drafts — that's
exactly the state a reopened form should be in).

One detail worth knowing if you're debugging a "why didn't this get pushed" question: the
UI does **not** support non-default attribute category combos — every value is stored under
the dataset instance's default `attributeOptionCombo`
(`DataEntryRepositoryImpl._defaultAttributeOptionCombo()`), matching the old remote-only
flow's behavior of letting the server default it.

Widgets: `DataEntryTable` (renders data elements as rows, category option combos as
columns), `DataEntryCell` (individual cell — shows the red rejected state with the server's
reason when `syncError != null`).

## home (`lib/features/home/`)

Presentation-only — no `data`/`domain` folders, because Home doesn't own any persistence or
business logic of its own; it composes `capture` and `visualization`.

`HomePage` is a shell with a `SegmentedToggle` between two modes:
- **Visualization** (default) — embeds `VisualizationView`.
- **Capture** — embeds `CaptureOrgUnitView`, plus a `FilterPanel` (date range, org unit,
  sync state) that only applies in this mode.

The app bar's search field is **mode-aware**: it searches dashboards in Visualization mode
and organisation units in Capture mode (`HomeAppBar.searchHint` switches based on `_mode`).
The sync button (`_onSyncTapped`) force-switches to Capture mode first (sync results — the
synced/unsynced chips — are only visible there), calls `runManualSync()`, and bumps a
`_syncTick` counter that remounts `CaptureOrgUnitView` with a fresh `ValueKey` so the tree and
chips reflect the just-completed push.

The drawer (`_HomeDrawer`, a private widget in `home_page.dart`) provides Home / Settings /
Log Out / About — note it constructs its own `AuthRepositoryImpl` inline to call
`LogoutUseCase`, following the same manual-DI pattern as every other logout call site (see
[Architecture](02-architecture.md#dependency-injection)).

## settings (`lib/features/settings/`)

Presentation-only, single page (`SettingsPage`). Shows the logged-in username and primary
organisation unit (read from `SecureStorage`), the current DHIS2 server URL (editable via
`ServerUrlDialog`, a shared widget), the app version, and a logout action with a confirmation
dialog that explicitly tells the user "data not yet synced stays on this device" before they
confirm — an honest, reassuring statement backed by the actual logout behavior (see
[Authentication & Security](04-authentication-and-security.md#logout-wipe-and-401-handling)).

## visualization (`lib/features/visualization/`)

DHIS2 dashboards rendered natively with `fl_chart`, via the same `/api/dashboards` →
`/api/visualizations/{id}` → `/api/analytics` pipeline the DHIS2 web app itself uses.

**Online-only by design** — `VisualizationRepositoryImpl._api` throws `NetworkException`
immediately if `AppSession.instance.api` is null (not logged in / no session API client).
The doc comment is explicit about why there's no local cache yet: *"caching analytics
locally needs new tables, which is blocked on the migration strategy (schemaVersion is
still 1)"* — see [Database](06-database.md#migrations) and
[Roadmap](15-roadmap-and-known-issues.md).

Notable defensive logic: `getVisualizationData()` refuses to query analytics for a
visualization with no period dimension configured anywhere (columns/rows/filters) — DHIS2
would otherwise answer such a query with a permanent HTTP 409 no matter how many times it's
retried — and throws a specific `MisconfiguredVisualizationException` with a message the
dashboard card can display, rather than a generic network error. Relative period flags
(`last12Months` etc.) are translated to their analytics dimension IDs
(`LAST_12_MONTHS`) mechanically via camelCase→UPPER_SNAKE conversion. Each visualization on
a dashboard is fetched and rendered **independently**, so one slow or broken chart never
blocks the rest of the dashboard from rendering.

Domain entities: `DashboardEntity` (tracks `unsupportedItems` — a count of dashboard item
types this app can't render yet, like MAP/TEXT/EVENT_CHART, so the UI can say "2 items not
supported" rather than silently dropping them), `DashboardVisualizationRef`, `AnalyticsData`/
`AnalyticsSeries`.

## debug (`lib/debug/`) — dev-only, not for end users

- **`debug_sync_screen.dart`** — manual full-sync/delta-sync buttons plus a drill-down
  browser (datasets → sections → elements) for inspecting what's actually landed in the
  local database.
- **`drift_db_viewer.dart`** — wraps the `drift_db_viewer` dev-dependency package to browse
  every table's raw contents inside the running app.
- **`test_login_page.dart`** — a quick-login shortcut for local development; contains a
  sample local dev server URL as a placeholder, clearly not intended for production use.

## shared (`lib/shared/`)

- **`theme/`** — `AppColors`, `AppTextStyles`, `AppDimensions`, `AppBreakpoints`, `AppTheme`
  (assembles a Material 3 `ThemeData`). Every screen pulls visual constants from here rather
  than hardcoding colors/sizes — if you're adding UI, check here first before introducing a
  new magic number.
- **`widgets/`** — `AppButton`, `AppTextField`, `AppLoader`, `ConnectivityIndicator` (renders
  `ConnectivityService.instance.online` as a visible badge), `FilterPanel` (the date/org
  unit/sync-state filter UI shared by Home's Capture mode), `SegmentedToggle` (the
  Visualization/Capture pill switch), `ServerUrlDialog`, `SyncSnackbar` (renders a
  `ManualSyncResult` as a `SnackBar`).
