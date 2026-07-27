# Performance Notes

This app targets mid-range Android phones on weak, often rural, field connections — every
decision below exists because of that constraint, not as generic optimization. Each item is
documented in depth in its own doc; this page collects them in one place.

## Network

- **Background JSON decoding.** `ApiClient` installs Dio's `BackgroundTransformer`, so
  large responses (a full metadata sync payload can be sizable) are decoded off the UI
  isolate — loading spinners never freeze during a big download. See
  [Networking](05-networking.md#apiclient).
- **Chunked, batched sync pushes.** `pushDataValueBatch` caps requests at 500 values and
  recursively chunks larger queues, so a mid-transfer drop on a flaky connection only loses
  the unsent slice, not weeks of backlog. `MetadataResource.fetchByIds` chunks id-list
  requests at 100 per call to avoid breaking long URLs on proxies. See
  [Offline & Sync](07-offline-and-sync.md#server-verdict-parsing-pushdatavaluebatch).
- **Delta sync over full sync.** Every login after the first does a cheap
  `id + lastUpdated` diff per metadata resource and fetches only what changed, instead of
  re-downloading everything. See
  [Offline & Sync — Metadata sync](07-offline-and-sync.md#metadata-sync-full-and-delta).
- **Scoped org unit sync.** A facility user's metadata sync pulls only their own
  organisation-unit subtree (via `/api/me`'s capture roots), never the full ~38,000-unit
  national hierarchy — keeping both the sync payload and the local database small.
- **Independent per-chart analytics queries.** Each dashboard visualization fetches its own
  `/api/analytics` data separately, so one slow or misconfigured chart never blocks the rest
  of a dashboard from rendering. See
  [Features — visualization](10-features.md#visualization-libfeaturesvisualization).

## Database

- **WAL journal mode** (`PRAGMA journal_mode = WAL`, set in `AppDatabase.migration.beforeOpen`)
  allows concurrent reads without blocking on writes.
- **Lazy-loaded org unit tree** — `CaptureRepositoryImpl.getOrgUnitChildren` fetches one
  level at a time, with a single grouped query to compute child counts for expand arrows,
  rather than loading the whole tree into memory.
- **Batched upserts** — `MetadataResource.saveAll` writes a full page of synced objects in
  one `db.batch(...)` transaction rather than row-by-row inserts.
- **Per-user database files** keep each user's working set small and mean one user's data
  volume never affects another's query performance on a shared device.

## UI

- **Offstage, not removed, for the mode toggle.** `HomePage` uses `Offstage` (not
  conditional widget removal) when the keyboard opens, specifically because removing and
  re-adding a subtree causes Flutter to recreate it, stealing focus from an active search
  field right as the keyboard appears — see the code comment in `home_page.dart` for the
  exact reasoning. This is a UI-correctness-driven performance/UX trade-off worth knowing
  before "simplifying" that widget tree.
- **Resolved-once lookups in data entry.** `DataEntryRepositoryImpl.getDataElements` caches
  category-option-combo lists and option-set option lists **per combo/set**, not per data
  element, since many elements share the same combo or option set — avoids redundant
  database queries when a form has dozens of elements pointing at a handful of shared
  combos.

## What's not addressed yet

There is no image/asset optimization pipeline (the app has minimal image assets), no
explicit `flutter analyze`-driven rebuild-optimization pass (no documented use of `const`
audits or `RepaintBoundary` placement), and no APM/performance-monitoring integration (see
[Roadmap](15-roadmap-and-known-issues.md)). If you're chasing a specific jank/perf issue,
start with Flutter DevTools' performance overlay rather than assuming one of the above is
the cause — none of these notes substitute for profiling the actual symptom.
