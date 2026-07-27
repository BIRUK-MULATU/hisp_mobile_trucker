# Database

## Technology

[Drift](https://drift.simonbinder.eu/) over SQLite (`sqlite3_flutter_libs` on native,
`sqlite3.wasm` via a Drift worker on web). Drift gives type-safe, compile-time-checked
queries and code-generates row/companion classes from `Table` subclasses — there is no
hand-written SQL-to-Dart mapping anywhere in the app.

## One database file per user

`AppDatabase.forUser(String userKey)` (`lib/core/database/app_database.dart`) opens a
connection scoped to a **sanitized username**:

```dart
static String sanitizeUserKey(String raw) =>
    raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
// 'Nurse.Alem@HC' -> 'nurse_alem_hc'
```

**Native** (`lib/core/database/connection/native.dart`): one file per user at
`<app documents dir>/hisp_<userKey>.sqlite`, created lazily via
`NativeDatabase.createInBackground`.

**Web** (`lib/core/database/connection/web.dart`): Drift's `WasmDatabase.open()`, named
`hisp_<userKey>`, backed by `sqlite3.wasm` + `drift_worker.js` (both served from `web/` —
re-download them together when upgrading the `drift`/`sqlite3` package versions, since
they're pinned to `pubspec.lock`). Persistence falls back from OPFS to IndexedDB on browsers
missing OPFS support; a warning is logged when that happens.

Both are selected via a single conditional export
(`lib/core/database/connection/connection.dart`):
```dart
export 'native.dart' if (dart.library.js_interop) 'web.dart';
```

**Why per-user files matter:** a device with multiple users who've each logged in has fully
isolated metadata caches *and* fully isolated pending/unsynced field data. There is no
cross-user query surface at all — you can't accidentally leak user A's draft data entry into
user B's session, because they're not in the same database.

## Schema — every table

Defined via `@DriftDatabase(tables: [...])` in `app_database.dart`. 25 tables in four groups:

### Metadata tables (11) — mirror DHIS2 configuration, refreshed by sync

| Table | Key columns | Notes |
|---|---|---|
| `OrgUnitsTable` | `uid`, `parentUid`, `path`, `isUserCaptureRoot` | `path` is used to derive tree depth (`'/'.allMatches(path).length`) rather than storing a level column |
| `DataSetsTable` | `uid`, `periodType`, `expiryDays`, `openFuturePeriods`, `categoryComboUid` | drives `PeriodAccess` gating |
| `DataElementsTable` | `uid`, `valueType`, `categoryComboUid`, `optionSetUid` | `formName` preferred over `displayName` for form labels |
| `SectionsTable` | `uid`, `sortOrder` | |
| `IndicatorsTable` | `uid` | |
| `CategoriesTable`, `CategoryOptionsTable`, `CategoryCombosTable`, `CategoryOptionCombosTable` | | the "category tower" — synced bottom-up: options → categories → combos → option combos |
| `OptionSetsTable`, `OptionsTable` | `code` | option-set membership for select-style data elements |
| `DataElementGroupsTable` | | |
| `ValidationRulesTable` | | server-side validation rule definitions, synced last (they reference elements via expressions) |

### Link / join tables (9) — n:n relationships

`DataSetElementsTable` (dataset↔element, carries `sortOrder` and an effective
`categoryCombo` override), `DataSetOrgUnitsTable`, `SectionDataElementsTable`,
`SectionIndicatorsTable`, `SectionGreyFieldsTable` (disabled cells per section),
`DataElementGroupMembersTable`, `CategoryCategoryOptionsTable`,
`CategoryComboCategoriesTable`, `CategoryOptionComboOptionsTable`.

### Global / control tables (4)

- `UsersTable` — the cached `/api/me` response (`uid`, `username`, `displayName`) — this is
  what makes offline `getCurrentUser()` and the offline-login user reconstruction possible.
- `AttributesTable` / `AttributeValuesTable` — a **generic** custom-attribute mechanism:
  `AttributeValuesTable`'s primary key is `(objectType, objectUid, attributeUid)`, so it can
  hold attribute values for any metadata object type without a table-per-type explosion.
- `SyncInfoTable` — a plain key-value store (`key`, `value`) used for sync bookkeeping:
  `lastMetadataSync` timestamp, `clockHighWaterMark`, `clockTamperedAt` (see
  [Offline & Sync](07-offline-and-sync.md#the-tamper-resistant-clock)).

### Data / write-queue tables (2) — the only tables NOT cleared by a metadata sync

- **`DataValuesTable`** — composite primary key
  `(dataElementUid, period, orgUnitUid, categoryOptionComboUid, attributeOptionComboUid)`;
  columns `value`, `comment`, `storedBy` (all nullable), `syncState` (enum, see below),
  `syncError`, `lastModified`.
- **`CompleteDataSetRegistrationsTable`** — composite primary key
  `(dataSetUid, period, orgUnitUid, attributeOptionComboUid)`; `completed` (bool),
  `syncState`, `syncError`, `date`, `lastModified`.

### The `SyncState` enum

```dart
enum SyncState { synced, pending, error, draft }
```
Stored by index (`intEnum<SyncState>()`) — **only append new states**, never reorder or
remove existing ones, or every stored row's meaning silently changes.

- `draft` — device-only. No sync path (auto or manual) ever touches a draft row. Set by
  `DataValueStore.setValue(..., draft: true)` on every ordinary save.
- `pending` — sync-eligible. Set by `promoteDrafts()` when a form is completed, or directly
  by conflict resolution when the local side wins.
- `synced` — confirmed accepted by the server.
- `error` — rejected by the server, with the reason in `syncError`. Surfaced to the user in
  the form; editing the cell clears the error and re-queues it as `pending`.

## Migrations

```dart
@override
int get schemaVersion => 1;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => m.createAll(),
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');
    await customStatement('PRAGMA journal_mode = WAL');
  },
  onUpgrade: (m, from, to) async {
    const steps = <int, Future<void> Function(Migrator)>{};   // EMPTY today
    for (var target = from + 1; target <= to; target++) {
      final step = steps[target];
      if (step == null) {
        throw UnsupportedError('No migration step for schema v$target ...');
      }
      await step(m);
    }
  },
);
```

`schemaVersion` is frozen at **1**. `onUpgrade` is **intentionally empty** and will throw
`UnsupportedError` the moment `schemaVersion` is bumped without a matching entry added to
`steps`. This is a deliberate fail-loud guard, not an oversight: silently opening a field
device's database against a schema it doesn't match would corrupt real, possibly
irreplaceable, field data. **If you change a table definition, you must:**
1. Bump `schemaVersion`.
2. Add a `target: (m) => m.addColumn(...)` (or equivalent) entry to `steps`.
3. Regenerate (`dart run build_runner build --delete-conflicting-outputs`).

Skipping step 2 means the app will refuse to open any existing installed database — this is
correct behavior, not a bug to work around.

## Retention

`AppDatabase.purgeOutsideRetention(Set<String> allowedPeriods)` deletes rows from
`DataValuesTable` and `CompleteDataSetRegistrationsTable` that are **both** `synced` **and**
outside the given period set. Rows in `pending`, `draft`, or `error` state are **never**
auto-deleted by this method, regardless of period — a device is never allowed to silently
destroy field work that hasn't confirmed as synced.

## Full metadata wipe vs. targeted clear

`MetadataSyncService._clearMetadata()` deletes **all 20 metadata + link tables** (an
explicit list, not derived from `allTables`, specifically so adding a new metadata table
requires a conscious decision to add it here too) before every **full** sync — a full sync
mirrors the server exactly, including deletions. It explicitly excludes `DataValuesTable`,
`CompleteDataSetRegistrationsTable`, `UsersTable`, and `SyncInfoTable` — field data, the
offline-login cache, and sync bookkeeping are never touched by a metadata refresh.

## Helper queries worth knowing about

- `AppDatabase.setSyncInfo(key, value)` / `getSyncInfo(key)` — the key-value interface over
  `SyncInfoTable`.
- `userDatabaseExists(userKey)` / `deleteUserDatabase(userKey)` — top-level functions (not
  methods on `AppDatabase`, since they must work *before* a database connection exists) used
  by the offline-login gate and the wipe flow.
- `hasUnsyncedLocalData(db)` (in `lib/core/data/data_value_store.dart`) — true if any
  `pending`/`draft` data value or `pending` completion exists; gates whether the clock is
  safe to re-anchor to server time.
- `countUnsyncedWork(db)` — the superset used by the wipe confirmation flow: everything a
  wipe would destroy, including `error` rows (which `hasUnsyncedLocalData` deliberately
  excludes, since they're already surfaced to the user and don't block clock anchoring).

## Testing against the database

Tests use `AppDatabase.forTesting(NativeDatabase.memory())` — a fully in-memory database, no
file I/O, no platform plugins required. This is what makes `flutter test` fast and able to
run in plain CI without an emulator. See [Testing](11-testing.md).
