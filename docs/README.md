# HISP Mobile Tracker — Developer Documentation

This is the full onboarding documentation for the HISP Mobile Tracker codebase — an
offline-first Flutter application for capturing aggregate health data into DHIS2, built by
HISP Ethiopia for the Federal Ministry of Health. It is written for a developer who has
never seen this codebase before and needs to become productive in it quickly, without
guessing at how anything works.

Every claim in these documents is backed by a specific file in the repository. Where a file
path is given, it is worth opening alongside the doc — the docs explain *why* the code is
shaped the way it is; the code itself is the source of truth for exact current behavior.

For a one-page snapshot of the project (features list, tech stack table, quick-start
commands), see the top-level [`README.md`](../README.md) and
[`OFFLINE_INTEGRATION.md`](../OFFLINE_INTEGRATION.md) — the latter is an older design note
from before the offline layer was fully built, kept for historical context on the interface
seams it describes.

## Reading order

If you are completely new to the project, read in this order:

1. **[Getting Started](01-getting-started.md)** — clone, install, run, configure, generate code.
2. **[Architecture](02-architecture.md)** — Clean Architecture layers, folder structure, dependency injection, why each layer exists.
3. **[Application Workflow](03-application-workflow.md)** — the full journey from opening the app to data landing on the DHIS2 server.
4. **[Authentication & Security](04-authentication-and-security.md)** — login (online/offline), credential storage, the full security posture.
5. **[Networking](05-networking.md)** — Dio, interceptors, error handling, request/response flow.
6. **[Database](06-database.md)** — the Drift/SQLite schema, every table, migrations, per-user isolation.
7. **[Offline & Synchronization](07-offline-and-sync.md)** — the sync engine, conflict resolution, metadata sync.
8. **[State Management](08-state-management.md)** — the Bloc pattern as used in this app.
9. **[Routing](09-routing.md)** — go_router configuration and the auth guard.
10. **[Features](10-features.md)** — a tour of every feature module (auth, capture, data_entry, home, settings, visualization).
11. **[Testing](11-testing.md)** — what's tested, how to run tests, how to write new ones.
12. **[Build & Release](12-build-and-release.md)** — Android release signing, CI, web deployment quirks.
13. **[Code Conventions](13-code-conventions.md)** — naming, lint rules, patterns to follow when adding code.
14. **[Troubleshooting & FAQ](14-troubleshooting-faq.md)** — known gotchas and how to resolve them.
15. **[Roadmap & Known Issues](15-roadmap-and-known-issues.md)** — what's intentionally not built yet, and why.
16. **[Performance Notes](16-performance.md)** — the network/database/UI decisions made for weak-connection, mid-range devices.

## The one-paragraph mental model

Every screen in this app reads from and writes to a **local, per-user SQLite database**
first. The network is not a dependency for daily work — it is how that local database gets
seeded (metadata sync) and how locally-queued writes eventually reach the DHIS2 server (data
sync). If you remember nothing else: **local database is truth for the UI; the server is a
sync target, not a live dependency.** Nearly every design decision in this codebase — the
draft/pending/error state machine, the conflict resolution rules, the per-user database
files, the background sync triggers — exists to make that one sentence true and safe.
