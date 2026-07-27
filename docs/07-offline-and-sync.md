# Offline & Synchronization

## Why offline-first

Health facilities in the field frequently have zero or intermittent connectivity. This app's
entire architecture is built around one constraint: **a health worker must be able to
complete an entire day's data entry with no network at all, and lose nothing.** Every design
decision documented below exists to make that true.

## The moving pieces

| Class | File | Responsibility |
|---|---|---|
| `SyncManager` (interface) | `core/sync/sync_manager.dart` | Contract: `pushPending()`, `pullLatest()`, `isSyncing` stream |
| `NoopSyncManager` | `core/sync/sync_manager.dart` | No-op fallback so the app stays "fully remote" behavior if ever needed |
| `DriftSyncManager` | `core/sync/drift_sync_manager.dart` | The real engine — singleton `.instance` |
| `SyncCoordinator` | `core/sync/sync_coordinator.dart` | Decides **when** to fire `pushPending()` automatically |
| `runManualSync()` | `core/sync/manual_sync.dart` | User-triggered sync with a precise, user-facing outcome message |
| `DataValueStore` | `core/data/data_value_store.dart` | Local CRUD + sync-state transitions for data values |
| `DataValueSync` | `core/data/data_value_sync.dart` | Per-form pull + conflict resolution + push |
| `pushDataValueBatch()` | `core/data/data_value_push.dart` | The actual `POST /api/dataValueSets.json` call + verdict parsing |
| `CompletenessStore` / `CompletenessSync` | `core/data/completeness.dart` | Same pattern for dataset completion registrations |
| `MetadataSyncService` | `core/metadata/metadata_sync_service.dart` | Full/delta download of DHIS2 configuration |
| `PeriodAccess` | `core/data/period_access.dart` | Tamper-resistant clock + period-open gating |

## Auto-sync: three doors, one push

`SyncCoordinator.start()` (called once, in `main()`) listens for **three independent
triggers**, any of which calls the same idempotent `_pushIfOnline()`:

1. **Offline → online transition** — `NetworkInfo.onConnectivityChanged` fires, and the
   previous state was disconnected.
2. **Login while already online** — a previous *offline* session may have left queued work
   with no connectivity-transition event to catch it; this door specifically catches "logged
   out → logged in" edges via `AppSession.instance.addListener`.
3. **A 5-minute heartbeat** (`Timer.periodic`) — catches pushes stuck behind a connection
   that *looks* alive (captive portal, flaky link) and would otherwise wait forever for
   another event.

`pushPending()` itself is safe to call repeatedly (already-synced rows are simply skipped)
and no-ops while logged out, so firing it from all three doors is safe by design. Failures
are swallowed with a debug print — a background sync must never crash the app; failed rows
simply stay queued for the next attempt.

## Manual sync

`runManualSync()` (`core/sync/manual_sync.dart`) is what the sync button on Home/Capture
screens calls. It:
1. Counts pending values + completions *before* doing anything.
2. Force-refreshes connectivity (`ConnectivityService.instance.checkNow()` — the cached flag
   can be up to 30 seconds stale).
3. If offline, returns immediately with an "will sync automatically" message.
4. If nothing is pending, returns "already synced" (mentioning any drafts still on-device,
   so that message doesn't read as "nothing left on this phone" when there is).
5. Otherwise pushes, then best-effort refreshes metadata (a metadata hiccup must not mask a
   successful data upload), and reports one of five outcomes:
   `offline / nothingToSync / uploaded / partial / failed`, each with a specific
   user-facing message (`ManualSyncResult.message`).

## The write path: draft, pending, synced, error

Every user-entered value goes through this exact state machine, never skipping a step:

```
user types in a cell
        │
        ▼
DataValueStore.setValue(..., draft: true)   ── upsert, SyncState.draft ── LOCAL ONLY
        │  user taps "Complete"
        ▼
DataValueStore.promoteDrafts(...)           ── draft → SyncState.pending
        │
        ▼
push attempt (immediate best-effort, or later via SyncCoordinator)
        │
        ├─ accepted by server ──▶ SyncState.synced
        │
        └─ rejected by server ──▶ SyncState.error, syncError = server's reason text
                                          │  user edits the cell again
                                          ▼
                                   SyncState.pending (re-queued), syncError cleared
```

**Drafts are never touched by any sync path.** This is the core offline-safety guarantee:
work in progress cannot be pushed half-finished, and cannot be silently overwritten by a
conflicting server value while the user is still editing it (see conflict resolution below).

## Conflict resolution — per cell, on form open

`DataValueSync.syncForm()` runs whenever a form is opened while online (best-effort — a pull
failure just means the local data stands, nothing is pushed that round). For every value the
server returns:

```dart
// local == null or already synced
  → server value applied as-is, marked synced

// local.value == serverValue
  → marked synced, NOT pushed (nothing to transmit)

// local.syncState == draft  (regardless of server value)
  → DRAFT ALWAYS WINS — unsubmitted device-only work, never silently replaced.
    It leaves the device only when the user completes the form.

// otherwise (pending or error), values differ — a real conflict:
  if clockTampered            → SERVER WINS (local timestamps are suspect)
  else if no server timestamp → SERVER WINS (can't compare fairly)
  else if local.lastModified.isAfter(server.lastUpdated + 2min tolerance)
                               → LOCAL WINS (stays pending, pushed in phase 2)
  else                        → SERVER WINS
```

The 2-minute tolerance is a **conservative bias toward the server** for near-ties — it
absorbs residual clock skew between the app's anchored local clock and the server's clock
without letting a genuinely stale local edit win on a technicality.

After resolution, phase 2 pushes everything still `pending` for that form (empty-slot values
plus conflicts the local side won) via `pushDataValueBatch`. Then, **only if nothing local
remains pending anywhere in the database**, the app's clock is re-anchored to the server's
`Date` header (`PeriodAccess.anchorToServer`) — deferred otherwise, so the clock never
recalibrates underneath data that hasn't confirmed yet.

`DataValueSyncResult` reports `equalSkipped` / `serverWon` / `localWon` counts for logging
and debugging.

## Server verdict parsing (`pushDataValueBatch`)

DHIS2 2.38+ answers a `dataValueSets` import that has any rejected values with **HTTP 409**
(so Dio throws a `DioException`) — but the response body is still a full `ImportSummary`.
`pushDataValueBatch` treats the 200 and 409 paths identically once it has that body:

- **No conflicts, no ignored count** → every value in the batch marked `synced`.
- **Conflicts present** → each conflict's `indexes` (or top-level `rejectedIndexes`) maps
  back to the exact position in the request payload — an **exact per-value verdict**, not a
  guess. Values not listed as rejected are marked `synced`; listed ones get `error` with the
  server's message.
- **Older servers with no index info** → falls back to a substring match of the conflict
  text against each value's `dataElementUid`/`period`, best-effort.
- **A true transport failure** (no parseable `ImportSummary` at all) → nothing is marked;
  every value stays `pending` for the next retry.

Batches are capped at **500 values per request** (`_maxBatchSize`) and chunked recursively —
a mid-transfer drop on a flaky field connection only loses the unsent slice, not the whole
backlog.

## Completion registrations follow the same shape, simpler

`CompletenessSync.pushPending()` — one HTTP call per pending registration (not batched, since
DHIS2's `completeDataSetRegistrations` endpoint semantics differ by verb):
`completed: true` → `POST`; `completed: false` → `DELETE`. A 409 here is treated as a
**permanent** rejection (marked `error` — retrying an already-rejected registration forever
cannot succeed); any other `DioException` leaves it `pending` for a future retry. Non-default
attribute option combos require explicit `cc`/`cp` query parameters on the `DELETE` — the
default combo is resolved server-side and needs neither.

## Metadata sync — full and delta

`MetadataSyncService` is **the only place in the app that holds an `ApiClient` for
metadata** — every `MetadataResource` subclass is constructed with just a database handle,
so by construction it cannot reach the network on its own.

**Full sync** (`syncMetadata()`) — triggered on first login into an empty database:
1. Clears all 20 metadata/link tables.
2. Syncs every resource in **dependency order**: category options → categories → category
   combos → category option combos → option sets → options → attributes → data elements →
   indicators → data element groups → (fetch the user's own capture-root org units from
   `/api/me`, then sync org units **scoped to that subtree only** — a facility user never
   pulls the national ~38,000-unit tree) → data sets → sections → validation rules.
3. Writes `lastMetadataSync` **only after the full pass succeeds** — an interrupted download
   leaves that timestamp `null`, so the *next* online login retries a full sync rather than
   getting stuck on the delta path with half-empty metadata forever.

**Delta sync** (`syncMetadataDelta()`) — every subsequent online login. Each
`MetadataResource.syncDelta()` (base class method, inherited by every resource):
1. Fetches a cheap `id + lastUpdated` list for the whole resource.
2. Compares against local `(uid, lastUpdated)` pairs (1-second tolerance, since Drift stores
   `DateTime` at second precision but the server sends milliseconds).
3. Fetches **only** the changed/new objects (`fetchByIds`, chunked at 100 ids per request to
   avoid breaking long URLs on proxies).
4. Deletes locally anything the server no longer has.

Resources without a `lastUpdatedColumn` (returns `null`) can't do a delta and silently fall
back to a full `syncAll()` for that one resource.

**Failure model:** each resource syncs in its own step; a network drop mid-sequence leaves
earlier resources fully synced and later ones untouched — stale but internally consistent,
never half-written.

## Ethiopian calendar & period ids

Two files carry all the date/period logic: `core/data/ethiopian_calendar.dart` (pure calendar
math + DHIS2 period-id generation) and `core/data/ethiopian_period_service.dart` (bridges that
math to the period picker's open/expired/notYetOpen gating via `PeriodAccess`, below).

### `EthiopianCalendar` — the math

- **Core conversion** goes through a Julian Day Number (JDN) — a single running day-count that
  turns calendar arithmetic into integer math:
  - `_gregorianToJdn` — the standard proleptic-Gregorian → JDN formula.
  - `_ethiopianToJdn` / `_jdnToEthiopian` — Ethiopian ↔ JDN via a fixed epoch offset
    (`1723856`) and a 4-year leap cycle (`year % 4 == 3` is an Ethiopian leap year, giving
    Pagume 6 days instead of 5 — see `daysInMonth`).
  - `toEthiopian(DateTime)`, `toGregorian(year, month, day)`, and `today()` are the public entry
    points; everything else in the class builds on these three.
  - Every Ethiopian month 1–12 has exactly 30 days; month 13 (Pagume) has 5 or 6.
- **`generatePeriods({periodType, count})`** produces DHIS2-ready `EthiopianPeriod`s (id +
  Amharic/English label), newest-first, one generator function per DHIS2 `periodType`:
  - **Monthly / Quarterly / SixMonthly / Yearly / Daily / Weekly / BiWeekly** — id shape follows
    DHIS2's own convention (`yyyyMM`, `yyyyQn`, `yyyySn`, `yyyy`, EC `yyyyMMdd`, ISO `yyyyWn`,
    `yyyyBiWn`), each walking backward month-by-month/quarter-by-quarter/etc. from `today()`.
  - **The "Nov family" — QuarterlyNov / SixMonthlyNov / Financial\*** — the one non-obvious
    part. On a DHIS2 server running the Ethiopian calendar, "Nov" in a DHIS2 period-type name
    does **not** mean Gregorian November — it means Ethiopian month 11 (Hamle). These are
    DHIS2's Ethiopian-fiscal-year period types (fiscal year = Hamle–Sene), and their **id
    carries the year the fiscal year ends in**, not the year it starts in. Verified against
    staging analytics: `2017Nov` = "Hamle 2016 – Sene 2017", `2018NovQ1` = "Hamle 2017 –
    Meskerem 2018". `_fiscalYearOf(ecYear, ecMonth)` encodes this: Hamle–Pagume (month ≥ 11)
    belong to *next* year's fiscal id.
- **`formatPeriodId(String)`** is the reverse direction — given a DHIS2 period id already on the
  wire (or read back from local storage), regenerate its Amharic display label. It recognizes
  every id shape `generatePeriods` can produce, **plus a few legacy shapes**
  (`yyyyEth01`, `yyyyEthQ1`, `yyyyEthS1`, `yyyyEth`) kept only so pre-fix locally-stored data
  (from before the 2026-07-09 period-id fix — see [Known Issues](15-roadmap-and-known-issues.md))
  still displays a real label instead of a raw unparsed id.

### `EthiopianPeriodService` — bridging to the picker

A thin, database-backed wrapper that turns `EthiopianCalendar`'s pure period list into what the
period picker actually needs: **which periods are currently selectable**.

- **`periodsFor(dataSet, count)`** — calls `EthiopianCalendar.generatePeriods` for the dataset's
  `periodType`, then for each period asks `PeriodAccess.statusOf(...)` whether it's `open`,
  `expired`, or `notYetOpen`, using that period's Gregorian start/end (`_gregorianBounds`, below)
  plus the dataset's `expiryDays`/`openFuturePeriods`.
  - Note the hardcoded `periodsAhead: 0` for every period in the returned list
    (`ethiopian_period_service.dart:40`). `generatePeriods` always returns newest-first starting
    at what *it* considers the current period, so nothing this service generates is ever treated
    as "ahead" of now. This is exactly why the picker can only show periods up to what
    `EthiopianCalendar.today()` computes — it has no way to independently notice if the
    **server** disagrees about what "now" is. See the staging period-lag bug in
    [Known Issues](15-roadmap-and-known-issues.md#staging-environment-bugs-not-app-bugs) for a
    real, worked example of that exact disagreement.
- **`currentPeriodId(periodType)`** — just `generatePeriods(..., count: 1).first.id`: "what would
  the app call today's period."
- **`_gregorianBounds(EthiopianPeriod)`** — the inverse of generation: given a period id already
  produced by the generator, work out its Gregorian start/end instants, because
  `PeriodAccess`'s expiry math runs in Gregorian (the device clock). This duplicates the
  id-shape parsing in `EthiopianCalendar.formatPeriodId`, but for a different purpose (bounds,
  not a label) — and errs toward a generous fallback for any id shape it doesn't specifically
  recognize, since the server enforces the real expiry check at import time regardless of what
  this client-side gate decides.
- **`plainPeriodsFor(periodType, count)`** — a static, ungated variant used when there's no
  `DataSet` (and therefore no `expiryDays`/`openFuturePeriods`) to gate against yet, e.g. before
  metadata has synced. Every period comes back `PeriodStatus.open`.

### The one thing to remember

**`EthiopianCalendar.today()` is the single source of truth for "what period is current"
throughout the app** — every period list, the default period-picker selection, and every id
ever pushed to the server all trace back to it. It has been independently verified correct
against the standard (Amete Mihret) Ethiopian calendar. If a "period looks wrong" report ever
comes up again, check whether the **server's own** period-open logic agrees with this calendar
before assuming this code is at fault — see the
[staging period-lag known issue](15-roadmap-and-known-issues.md#staging-environment-bugs-not-app-bugs)
for a worked example of exactly that happening.

## The tamper-resistant clock

`PeriodAccess` (`core/data/period_access.dart`) exists because period-based access control
("can I still edit August's report in October?") is meaningless if the device clock can be
set backward to reopen a closed period.

- **High-water mark**: the latest time the app has ever observed, persisted in
  `SyncInfoTable`. `effectiveNow()` never returns earlier than this mark — moving the device
  clock backward literally cannot make `effectiveNow()` go backward.
- **Tamper flag**: `checkAtSessionStart()` (called on every login and app resume) compares
  wall-clock `now` against the high-water mark; a backward jump beyond a 2-minute tolerance
  (to avoid false-flagging legitimate NTP corrections) sets a **persistent** tamper flag.
  While set, the UI contract is: refuse/warn on entry into *past* periods; entry into the
  *current* open period may continue (the data itself isn't suspect — only backdating
  claims are).
- **Healing**: any successful online contact anchors the clock to the server's `Date` header
  (`anchorToServer`) and clears the tamper flag — server time re-establishes ground truth.
  This is gated by `hasUnsyncedLocalData()` at login (won't re-anchor if local data is still
  pending) but is unconditional inside `DataValueSync._maybeAnchor()` once a sync round
  fully settles.
- Data value `lastModified` stamps and completion `date`/`lastModified` stamps all come from
  `PeriodAccess.effectiveNow()`, not raw `DateTime.now()` — so a backdated device can never
  produce a timestamp earlier than anything the app has already observed, which is exactly
  the property the newest-wins conflict rule depends on.

## Error and conflict handling

The recurring pattern across every sync-adjacent class in this codebase: **a
transport failure leaves data exactly where it was (still pending, still queued); a server
verdict (2xx accepted, or 409 rejected) is the only thing allowed to change a row's sync
state.** Nothing is ever guessed into `synced` or silently dropped because a request failed
to even reach the server.
