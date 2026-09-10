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
  them through `DataSetElementsTable`. Routine and Disease Registration reports are merged
  into one list; each `ReportInstanceEntity` carries its `attributeOptionComboUid` (two
  reports can share dataset/period/org unit but differ by combo and must not be conflated),
  a `syncError` for a rejected completion push, and an `isDiseaseRegistration` flag. A
  report whose completion is done but still has drafts is `ReportStatus.incomplete` —
  reopening a completed form for corrections un-finishes it here, which is intentional.
- **`getExpectedReports()`** — the "To-do" band (Capture mode): every report the user still
  *owes* — datasets assigned to their facilities (capture roots + direct children), for
  every open period, not already completed locally or on the server. Best-effort pulls the
  server's completion state first when online. Sorted most-urgent first
  (`ReportUrgency.overdue` / `dueSoon` / `open`). See
  [Reminders & Onboarding](18-reminders-onboarding-background.md#expected-reports--the-to-do-band).
- **Disease Registration datasets** are surfaced in the same `getDataSetsForOrgUnit` list,
  flagged `isDiseaseRegistration`; opening one routes through a **category-combo picker**
  (e.g. Department × Outcome) before the form, and the form is themed accordingly.

Pages: `OrgUnitFilterPage`, `DatasetSelectionPage`, `PeriodSelectionPage`,
`SectionSelectionPage`, `NewReportPage` (the "+" / create-new-record entry point).
Views: `CaptureOrgUnitView` (the tree browser embedded in Home's Capture mode),
`ReportPeriodView` (the Report Period overview, which also embeds dashboards). Widgets:
`ExpectedReportsSection`, `DatasetCard`, `PeriodSelectorField`.

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

One detail worth knowing if you're debugging a "why didn't this get pushed" question:
**Routine** datasets store every value under the dataset instance's default
`attributeOptionCombo` (`DataEntryRepositoryImpl._defaultAttributeOptionCombo()`).
**Disease Registration** datasets do use a real combo, picked before the form opens and
threaded through `getDataValues`/`saveDataValues` as `attributeOptionComboUid`.

The repository also owns the data-quality checks — `validateDataSet` / `validateLiveValues`
(validation rules), `missingMandatoryFields` (compulsory fields, blocks completion), and
`loadOutlierHistory` (the outlier snapshot). See **[Data Quality](17-data-quality.md)** for
all of it, plus grey fields, controller elements, and the audit trail.

Widgets: `DataEntryTable` (data elements as rows, category option combos as columns, with
per-element summation rows and inline indicators), `DataEntryCell` (shows the red rejected
state with the server's reason when `syncError != null`), `DiseaseEntryList` (the
case/disease list layout), `OutlierWarningDialog`, `OutlierSettingsSheet`. Utils:
`data_entry_pdf.dart`, `data_entry_excel.dart` (form export).

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

DHIS2 analytics rendered natively with `fl_chart`. `VisualizationView` presents **three
flat tabs** (flat top-level tabs, not nested sub-toggles):

| Tab | What it is | Connectivity |
|---|---|---|
| **Server Dashboard** | DHIS2 server dashboards via the `/api/dashboards` → `/api/visualizations/{id}` → `/api/analytics` pipeline the web app uses. `ChartRepositoryImpl`. Each visualization on a dashboard is fetched/drawn **independently**, so one broken chart never blocks the rest. | Online to load; last successful result cached (per chart) for offline viewing — an `OfflineCacheBanner` shows when data is stale. |
| **Local Dashboard** | Charts the user built on this device. `LocalVisualizationRepositoryImpl` stores each `ChartConfig` as JSON under the `savedCharts` key in `SyncInfoTable` (**no schema change**), and every successful query result under `chartCache_<id>`. Full CRUD — create / view / edit / delete — **never pushed to the server**. | Online to (re)run a chart; cached result offline. |
| **Create New** | The chart builder (`ChartBuilderView`): pick indicators or data elements (by group when online, flat from local metadata when offline), an org unit, a period, a chart type. Saving lands the chart in Local Dashboard. A chart saved offline is finished later by `ChartDraftCoordinator` (see [Reminders & Onboarding](18-reminders-onboarding-background.md#chart-draft-coordinator)). | Dimension pickers prefer live, fall back to local metadata. |

Notable defensive logic (`ChartRepositoryImpl` / `LocalVisualizationRepositoryImpl`): a
visualization with **no period dimension** anywhere (columns/rows/filters) is refused before
the analytics call — DHIS2 would answer it with a permanent HTTP 409 — and a specific
`MisconfiguredVisualizationException` with a displayable message is thrown instead of a
generic network error. Relative-period flags (`last12Months` …) are translated to analytics
dimension IDs (`LAST_12_MONTHS`) mechanically. A dashboard tracks how many item types it
can't render yet (MAP/TEXT/EVENT_CHART …) so the UI can say "2 items not supported".

Pages: `DashboardDetailPage`, `ChartViewPage`, `ChartEditPage`, `RemoteChartViewPage`.
Domain: `ChartConfig`, `ChartLoadResult`, `DashboardRef`, `RemoteVisualization`,
`AnalyticsData`/`AnalyticsSeries`; use cases `save`/`load`/`delete`/`getSaved`.

## audit_log (`lib/features/audit_log/`)

Presentation-only. `CellHistorySheet` — the per-cell "history" bottom sheet — merges the
**local** edit trail (`AuditLogStore` / `AuditLogTable`, works offline) with **DHIS2's own
server audit trail** (`ServerAuditService` → `GET /api/audits/dataValue`) into one timeline.
See [Data Quality — Audit trail](17-data-quality.md#audit-trail).

## onboarding (`lib/features/onboarding/`)

Presentation-only. `OnboardingPage` — the first-run carousel, gated by
`OnboardingService` (plain `SharedPreferences`). Per-screen spotlight tours (`showcaseview`)
are wired separately, one `tourId` per screen. See
[Reminders & Onboarding](18-reminders-onboarding-background.md#onboarding--the-app-tour).

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
  `ManualSyncResult` as a `SnackBar`), `SearchField`, `OptionGrid` (option-set picker),
  `SquircleFab` (the "+" create-new-record button).
