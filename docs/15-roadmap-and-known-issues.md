# Roadmap & Known Issues

Stated transparently, so nobody discovers these by surprise. None of the items below involve
credential exposure or remote data tampering — they're prioritized defense-in-depth and
engineering-investment items.

## Security hardening (highest priority — before any large-scale rollout)

1. **Encrypt the local database at rest.** Currently plain `sqlite3_flutter_libs`, not an
   SQLCipher-backed variant. It holds cached metadata and pending field data, never
   credentials — but a lost/stolen device should still not expose facility health data in
   a plain-readable file. See [Database](06-database.md).
2. **Enable R8/ProGuard minification** for Android release builds — `minifyEnabled` is not
   currently set, and no `proguard-rules.pro` exists.
3. **Certificate pinning** for the production DHIS2 host — currently relies entirely on the
   OS/system trust store.
4. **Explicitly set `android:allowBackup="false"`** — health data shouldn't ride Android's
   default auto-backup mechanism.

## Engineering investment (next)

5. **Offline caching for the Visualization tab.** Blocked on the database migration
   strategy — `schemaVersion` is frozen at 1 with no migration steps defined yet (see
   [Database — Migrations](06-database.md#migrations)). Adding analytics-cache tables means
   writing the *first* real migration, which is worth doing carefully and deliberately
   rather than as a side effect of an unrelated change.
6. **Bloc and widget test coverage.** The offline-critical core (sync, conflict resolution,
   validation) is well tested; `AuthBloc`/`DataEntryBloc` and most widgets are not. See
   [Testing](11-testing.md).
7. **A lightweight service locator (`get_it`)** to remove the repeated manual-DI wiring
   snippets across pages (`AuthRepositoryImpl` alone is reconstructed identically in at
   least three places) — see
   [Architecture — Dependency Injection](02-architecture.md#dependency-injection).
8. **A real, exercised schema migration** — the current `onUpgrade` is an empty map that
   throws on any bump. The first non-trivial schema change (likely the analytics-cache
   tables above) should be the one that proves the migration path actually works.

## Product roadmap (longer-term, depends on Ministry/HISP Ethiopia priorities)

- Biometric app-lock for at-rest device access.
- Push notifications for sync outcomes.
- Crash and performance monitoring (e.g. Sentry or Firebase Crashlytics) — there is
  currently no automated crash reporting in the app.
- Role-based dashboards, an audit log, and a move from Basic Auth to OAuth2/PAT
  token-based authentication once the target DHIS2 deployment supports it.
- Multi-language support (Amharic, Afaan Oromo, Tigrinya) — the app is currently
  English-only.
- Dark mode.

## Known, accepted trade-offs (not necessarily "to fix", but worth knowing)

- **Manual dependency injection** instead of a DI framework — simple and traceable, at the
  cost of repeated wiring code. See item 7 above.
- **No certificate pinning, no ProGuard** — see security items above.
- **`AuthRemoteDataSource` is transitional legacy glue** (see
  [Features — auth](10-features.md#auth-libfeaturesauth)) still called after online logins
  to keep older `SecureStorage`-reading code paths working. Worth auditing whether anything
  still actually depends on it before removing.
- **The UI does not support non-default attribute category combos** in data entry — every
  value is stored under the dataset instance's default combo, matching the previous
  remote-only flow's behavior. This is a scope decision, not a bug.
- **`OFFLINE_INTEGRATION.md`** at the repo root is a pre-implementation design note, now
  superseded by the actual offline layer described throughout `docs/` — kept for historical
  context, not current-state documentation.

## Staging environment bugs (not app bugs)

Two issues on `hmis-staging.moh.gov.et` have caused real confusion — logged here so nobody
re-investigates the app's calendar code by mistake.

### The staging server's own "current period" runs ~2 months behind the real Ethiopian calendar

Investigated 2026-07-21. On that date the app correctly computed today as **Hamle 14, 2018
EC** — verified two independent ways (the app's own JDN-based conversion in
`core/data/ethiopian_calendar.dart`, and a third-party Ethiopian date converter both agree).
Data pushed under period `201811` (Hamle 2018) landed on the server fine (confirmed via
`GET /api/dataValueSets.json?dataSet=...&orgUnit=...&period=201811`).

But the staging server itself does not consider Hamle 2018 open yet. Evidence: the
`"00 - Monthly common dataset"` dataset (`Mit66Ie5u6x`) has `openFuturePeriods: 1` and
`dataInputPeriods: []` (no manual override), yet the staging web Data Entry app's period
picker topped out at **Sene 2018** with "Next periods" disabled. Working backward through
`openFuturePeriods: 1`, that means DHIS2's own period generation believes the true current
period is **Genbot 2018** — two months behind the real Ethiopian calendar date.

**Implication:** data entered "for today" will keep landing in a period the staging web UI
won't display for roughly two more months, even though the push succeeded. This is not
something to "fix" by changing the app's calendar math to match — the app's conversion is the
correct one; the server's period generation is what's wrong. If you hit a "my data isn't
showing up" report, check via the API directly (see
[Troubleshooting — proving a value reached the server](14-troubleshooting-faq.md)) before
assuming a sync bug.

### The staging "Routine Data Entry" app's section tabs don't switch

In that same custom web app (`dhis-web-routine-dataentry`), clicking any section tab other
than the first (e.g. "EPI", "Neonatal and Child") does nothing — the form stays on whatever
section loaded first, no error in console, no network request even fires. Reproduced directly
in-browser. Likely a front-end bug specific to that app choking on `"00 - Monthly common
dataset"`'s unusually large number of sections. Not related to this codebase; flagged to
whoever administers the staging instance.

## Where to look for the most current state

This documentation reflects the codebase as read at the time it was written. Code moves
faster than docs. Before relying on a specific claim here for something consequential
(planning a migration, assessing security posture for a compliance review), verify against
the actual file referenced — every doc in this folder cites exact paths for that reason.
