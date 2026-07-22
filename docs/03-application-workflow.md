# Application Workflow

This walks the full journey a user takes through the app, tying each step to the exact code
that runs it. Read this after [Architecture](02-architecture.md) — it assumes you know the
Presentation/Domain/Data/Core split.

## The end-to-end flow

```
User opens app
      │
      ▼
AppRouter checks AppSession.instance.isLoggedIn ──false──▶ /login
      │ true
      ▼
LoginPage: AuthBloc(AuthCheckRequested) → AuthAuthenticated → context.go('/home')
      │
      │  (first time here: user types credentials, submits LoginSubmitted)
      ▼
AuthRepositoryImpl.login()
  → ConnectivityNetworkInfo().isConnected  (are we online right now?)
  → SessionService.login(serverUrl, username, password, online)
      ├─ ONLINE:  GET /api/me.json via ApiClient.withBasicAuth  (server-verified)
      │             → AppDatabase.forUser(username)  (opens/creates per-user SQLite file)
      │             → PeriodAccess.anchorToServer(serverDate)  (clock trust reset)
      │             → CredentialStore.store(...)  (persist salted verifier for offline use)
      │             → first login ever?  → MetadataSyncService.syncMetadata()  (FULL, background)
      │             → returning login?    → MetadataSyncService.syncMetadataDelta()  (background)
      └─ OFFLINE: CredentialStore.verify(...)  (SHA-256 hash check, no network)
                    → AppDatabase.forUser(username)  (must already exist on this device)
      ▼
AppSession.instance.api = ApiClient.withBasicAuth(...)   (kept for background sync pushes)
AppSession.instance.sessionChanged()                      (notifies the router's refreshListenable)
      ▼
Router redirects to /home
      ▼
HomePage: SegmentedToggle between Visualization and Capture (default: Visualization)
      │
      ▼ (user switches to Capture)
CaptureOrgUnitView → org unit tree, lazily loaded one level at a time
  (CaptureRepositoryImpl.getOrgUnitChildren — reads OrgUnitsTable, no network)
      │  user taps a leaf org unit
      ▼
DatasetSelectionPage → datasets assigned to that org unit
  (CaptureRepositoryImpl.getDataSetsForOrgUnit — reads DataSetsTable + DataValueStore
   for the synced/unsynced chip)
      │  user taps a dataset
      ▼
SectionSelectionPage (only if the dataset has sections) → PeriodSelectionPage
  (period gated by PeriodAccess.isOpen — expiryDays / openFuturePeriods / clock tamper)
      │
      ▼
DataEntryPage opens
  → if online: DataValueSync(db, api).syncForm(...)  — pull server values, resolve
    conflicts (see doc 07), push anything still pending. Failure here is NON-FATAL —
    local data is shown regardless.
  → DataEntryRepositoryImpl.getDataElements(...)  — form metadata from local tables
  → DataValueStore.valuesForForm(...)              — cached values, local-first
      │  user edits cells
      ▼
DataEntryBloc.DataEntryValueChanged  → in-memory map update, isModified=true
      │  user taps Save
      ▼
DataEntryRepositoryImpl.saveDataValues()
  → DataValueStore.setValue(..., draft: true)   — upsert as DRAFT, device-only, NO network call
      │  user taps Complete
      ▼
DataEntryRepositoryImpl.completeDataSet()
  → DataValueStore.promoteDrafts(...)            — DRAFT rows → PENDING (now sync-eligible)
  → CompletenessStore.setComplete(..., completed: true)   — registration → PENDING
  → best-effort immediate push if online (non-blocking, unawaited)
      ▼
Meanwhile, independent of any user action:
SyncCoordinator (started once in main()) fires pushPending() on THREE doors:
  1. connectivity offline→online transition
  2. user logs in (session change) while already connected
  3. a 5-minute heartbeat, for pushes stuck behind a link that "looks" connected
      ▼
DriftSyncManager.pushPending()
  → pushDataValueBatch(...)   — POST /api/dataValueSets.json, importStrategy=CREATE_AND_UPDATE,
                                 atomicMode=NONE, 500 values per request, chunked
  → CompletenessSync.pushPending()  — POST/DELETE /api/completeDataSetRegistrations
      ▼
Server verdict parsed per value (HTTP 200 or 409+ImportSummary):
  accepted → DataValuesTable.syncState = synced
  rejected → DataValuesTable.syncState = error, syncError = server's reason text
      ▼
Rejected cells show red in DataEntryPage with the server's reason; editing the cell
clears syncError and re-queues it as pending on the next save.
```

## Where the network is, and isn't, in this flow

Network calls happen at exactly these points, and nowhere else in the capture/data-entry
path:

1. **Login** — one `GET /api/me.json` call (online path only).
2. **Metadata sync** — a burst of `GET` calls to `/api/{resource}.json` for each metadata
   type, triggered by login (full on first login, delta after) or a manual "sync metadata"
   action.
3. **Form open** — `GET /api/dataValueSets.json` to pull fresh server values for that one
   form (`DataValueSync.syncForm`), best-effort, only if online.
4. **Sync push** — `POST /api/dataValueSets.json` and
   `POST`/`DELETE /api/completeDataSetRegistrations`, triggered by the three
   `SyncCoordinator` doors or the manual sync button.
5. **Visualization tab** — `GET /api/dashboards.json`, `/api/visualizations/{id}.json`,
   `/api/analytics.json` — entirely separate from the capture flow, online-only, no local
   cache (see [Features](10-features.md#visualization-libfeaturesvisualization)).

Everything else — browsing the org unit tree, picking a dataset, opening a form, typing into
a cell, saving a draft — is a **pure local database read/write**. This is the offline-first
property in concrete terms: you can fly-mode the device after the first login and every one
of those steps still works exactly the same way.

## Sequence in one sentence per stage

1. **Open** — router checks `AppSession`, sends you to `/login` or `/home`.
2. **Authenticate** — online verifies against the server and refreshes the offline verifier;
   offline checks the verifier locally; both end with a per-user database open.
3. **Metadata** — downloaded once (full) at first login, refreshed (delta) on every
   subsequent online login, scoped to the user's own org-unit subtree.
4. **Store locally** — every metadata object and every captured value lands in the per-user
   Drift database before anything else happens to it.
5. **Display datasets** — the capture screens are pure reads against that local database.
6. **Open forms** — form metadata and existing values load locally; a best-effort server
   sync refreshes them if online, but never blocks the form from opening.
7. **Save data** — every edit is a local upsert as `draft`.
8. **Complete** — promotes `draft` → `pending` and attempts an immediate best-effort push.
9. **Synchronization** — `SyncCoordinator` retries pushing `pending` rows on connectivity
   restore, login, and a 5-minute heartbeat, plus a manual button.
10. **Conflict handling** — `DataValueSync` resolves per-cell conflicts on form open (see
    [Offline & Sync](07-offline-and-sync.md)).
11. **Upload to DHIS2** — `pushDataValueBatch` and `CompletenessSync` send queued writes,
    parse the server's per-value verdict, and settle each row as `synced` or `error`.
