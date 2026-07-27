# HISP Mobile Tracker — Executive Summary

**Prepared for:** Federal Ministry of Health, Ethiopia
**Prepared by:** HISP Ethiopia
**Subject:** Architecture, Security & Readiness Review of the HISP Mobile Tracker Flutter application

## What it is

HISP Mobile Tracker is an offline-first mobile application for capturing aggregate health
data into DHIS2 (version 2.40), built for health facility staff working under Ethiopia's
real connectivity conditions — intermittent or absent network access at the point of care.
The app is developed by HISP Ethiopia in collaboration with the Federal Ministry of Health,
and currently targets the HMIS staging instance (`hmis-staging.moh.gov.et`).

## What we reviewed

This review is based on a direct, file-by-file analysis of the production Flutter codebase —
118 Dart source files, approximately 32,000 lines of production code, plus 1,450 lines of
automated tests. Every claim in the accompanying presentation and technical appendix traces
to a specific file, class, or line in the repository; nothing is based on assumption or
documentation alone.

## Key findings

**Architecture.** The app follows Clean Architecture with a feature-first folder structure
(`auth`, `capture`, `data_entry`, `home`, `settings`, `visualization`), each split into
Presentation, Domain, and Data layers, backed by shared Core infrastructure (network,
database, storage, sync, auth, error handling). Domain-layer code was verified to have zero
dependency on Flutter, Dio, or Drift — business rules are fully framework-independent and
testable in isolation.

**Offline-first, verified in code.** Every data entry save lands in a local, per-user SQLite
database (via Drift) as a draft before any network call is made. Metadata (organisation
units, datasets, data elements) is downloaded once at first login, scoped to the user's own
organisation-unit subtree, and cached — the app remains fully usable offline indefinitely
afterward.

**Synchronization & conflict resolution.** Sync runs automatically on three triggers
(connectivity restored, login, a 5-minute heartbeat) plus an on-demand manual button. A
verified conflict-resolution engine ensures unsubmitted local drafts are never overwritten
by server data; submitted-but-unsynced values are resolved by timestamp comparison with a
clock-tampering guard, favoring the server when local trust cannot be established.

**Security.** Passwords are never stored in plaintext, online or offline. Offline login uses
a salted SHA-256 verifier bound to the specific server URL, compared in constant time.
Credentials live in OS-level secure storage (Android EncryptedSharedPreferences / iOS
Keychain). Release builds are HTTPS-only and fail to build without a genuine signing
keystore. Three gaps are identified and prioritized: the local database is not encrypted at
rest, there is no certificate pinning, and Android release builds do not yet use
ProGuard/R8 minification. None of these gaps expose credentials; all have scoped,
well-understood fixes.

**Code quality & testing.** The codebase shows strong adherence to SOLID principles
(focused, single-purpose repository interfaces and use cases) and is gated by `flutter
analyze` and `flutter test` in CI on every push and pull request. Test coverage is
strongest exactly where it matters most: the offline sync and conflict-resolution engine,
tested against an in-memory database. Bloc and widget-level test coverage is a known,
addressable gap.

## Recommendation

The application is architecturally sound and already offline-capable in production use. We
recommend proceeding with continued rollout alongside HISP Ethiopia and Ministry review,
adopting the near-term security hardening items (database-at-rest encryption, release build
minification, certificate pinning) ahead of any national-scale expansion. A full prioritized
roadmap (Now / Next / Later) is included in the accompanying presentation.
