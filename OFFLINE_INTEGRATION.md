# Offline (SQLite) Integration Guide

The frontend is structured so the offline layer plugs in by implementing
a small set of Dart interfaces. No UI, bloc, or usecase code needs to
change — repositories already contain the offline-first logic and fall
back to the local store whenever the API throws `NetworkException` or
`TimeoutException`.

## Interfaces to implement (the seams)

| Interface | File | Purpose |
|---|---|---|
| `HomeLocalDataSource` | `lib/features/home/data/datasources/home_local_datasource.dart` | Cache the dataset list + report pending changes per dataset |
| `DatasetDetailLocalDataSource` | `lib/features/dataset_detail/data/datasources/dataset_detail_local_datasource.dart` | Cache records per dataset/org unit + queue records created offline |
| `DataEntryLocalDataSource` | `lib/features/data_entry/data/datasources/data_entry_local_datasource.dart` | Cache form metadata & data values + queue offline saves/completions |
| `SyncManager` | `lib/core/sync/sync_manager.dart` | Push queued writes / pull fresh caches |

Already implemented on the frontend side (no backend work needed):

- **Connectivity detection** — `ConnectivityNetworkInfo`
  (`lib/core/network/network_info.dart`, backed by connectivity_plus).
- **Auto-sync trigger** — `SyncCoordinator` (`lib/core/sync/sync_coordinator.dart`)
  is started in `main()` and calls `SyncManager.pushPending()` whenever
  the device comes back online. Swap its `NoopSyncManager` for the real
  engine at integration time.
- **Offline login** — the `/me` response is cached at login and restored
  by `AuthRepositoryImpl.getCurrentUser()`, so a previously logged-in
  user reaches the home screen without a network connection.
- **Sync badges** — the home page derives the green "Synced" / red
  "unsync" chips from `HomeLocalDataSource.hasPendingChanges(dataSetId)`;
  implement it as "does this dataset have any queued rows?".

Each interface ships with an `Unimplemented*` / `Noop*` stub that keeps
the app fully remote (today's behavior). Replace the stubs by passing
your SQLite-backed implementations where the repositories are built.

## Contract conventions

- **Reads never throw for "no data"** — return an empty list when the
  cache is empty. The repository decides whether to surface an error.
- **`cache*` methods replace** previously cached rows for the same key
  (dataset id, org unit, period). Queued (unsynced) rows must survive
  a cache replace.
- **`queuePending*` methods** store writes made while offline for the
  `SyncManager` to upload. Until implemented they throw
  `CacheException`, which makes the repository surface the original
  network error — so the current online-only behavior is preserved.
- Queued records/values must come back from the corresponding
  `getCached*` call (records with `isSynced == false`) so the UI can
  show the red "unsync" badge.

## How repositories use the local store (already wired)

- `getDataSets` / `getRecords` / `getDataElements`: remote first; on
  success the result is written to the cache; on network/timeout error
  the cached rows are returned instead (error only if the cache is
  empty too).
- `getDataValues`: remote first, falls back to cached values.
- `saveDataValues` / `completeDataSet` / `createRecord`: remote first;
  on network/timeout error the write is queued locally and reported as
  success.
- `HomeRepository.syncAll()` (the sync button in the home app bar)
  calls `SyncManager.pushPending()` then `pullLatest()`.

## Injection points

Repositories accept the local datasources as optional constructor
parameters, defaulting to the stubs:

```dart
HomeRepositoryImpl(
  remoteDataSource: ...,
  localDataSource: SqliteHomeLocalDataSource(db),   // ← plug in here
  syncManager: appSyncManager,                      // ← and here
)
```

They are currently constructed in:

- `lib/features/home/presentation/pages/home_page.dart` (`HomePage.build`)
- `lib/features/dataset_detail/presentation/pages/dataset_detail_page.dart`
- `lib/features/dataset_detail/presentation/pages/add_record_page.dart`
- `lib/features/data_entry/presentation/pages/data_entry_page.dart`

When the SQLite layer lands, prefer registering the database, local
datasources, and `SyncManager` once at startup (e.g. a simple service
locator such as `get_it`, or an `InheritedWidget`/`RepositoryProvider`
above the router in `main.dart`) instead of constructing them in each
page.

## Suggested SQLite tables

```
datasets           (id TEXT PK, name, period_type, description, style_json, updated_at)
data_elements      (id TEXT PK, dataset_id, display_name, value_type, combos_json)
records            (dataset_id, org_unit_id, org_unit_name, period_id,
                    complete_date, created_at, last_updated,
                    is_synced INTEGER, PRIMARY KEY(dataset_id, org_unit_id, period_id))
data_values        (dataset_id, org_unit_id, period_id, data_element_id,
                    category_option_combo_id, value, is_pending INTEGER,
                    PRIMARY KEY(dataset_id, org_unit_id, period_id,
                                data_element_id, category_option_combo_id))
pending_completions(dataset_id, org_unit_id, period_id, queued_at)
```

Model classes already provide the JSON mapping used by the API
(`DataSetModel`, `DataRecordModel`, `DataElementModel`,
`DataValueModel`); reuse their `fromJson`/`toJson` where convenient.

## Sync engine expectations

- `pushPending()`: upload queued data values (`POST /dataValueSets`),
  queued completions (`POST /completeDataSetRegistrations`), oldest
  first; mark rows synced on success; keep and retry on failure.
- `pullLatest()`: refresh datasets, data elements, and records caches.
- `isSyncing`: emit `true`/`false` around a run so the UI can show
  progress.
- Use `NetworkInfo.onConnectivityChanged` to trigger `pushPending()`
  automatically when the device comes back online.
