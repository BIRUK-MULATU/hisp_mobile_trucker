# Reminders, To-Do, Onboarding & Background Sync

Four smaller subsystems that share a theme: making the app work *for* a field user who
opens it infrequently and on a device that fights background work.

## Expected reports — the "To-do" band

`CaptureRepository.getExpectedReports()` computes, on the fly, every report the user still
**owes**:

- every dataset assigned to one of their facilities (**capture roots + their direct
  children** — the same depth bound as offline org-unit storage, see
  [Offline & Sync — Metadata sync](07-offline-and-sync.md#metadata-sync-full-and-delta)),
- for every period still **open for entry**,
- that is **not** already completed — locally *or* on the server.

When online it best-effort pulls the server's completion state first, so a report finished
on the web doesn't linger in the list. Results are sorted most-urgent first. Nothing is
stored — the list is recomputed each time.

`ExpectedReportEntity` carries a `ReportUrgency`:

| Urgency | Meaning |
|---|---|
| `overdue` | The period has ended but is still inside its lock window — fill it now. |
| `dueSoon` | The period is ending within a few days. |
| `open` | Open, deadline not yet close. |

It also flags `isDiseaseRegistration`, `needsComboPick` (the dataset has a real category
combination — opening it needs the combo-picker step, not a straight jump to the form), and
`localStarted` (something is already queued — a "resume", not a "start").

The band renders in Capture mode via `expected_reports_section.dart`.

## Deadline reminders

`ReportReminderService` (`core/notifications/report_reminder_service.dart`) schedules
**on-device local notifications** — no server, no push — for reports due before their lock
date. It is a singleton, initialised in `main()` (safe to `await`: no-op on web,
self-disables silently if the platform refuses init or permission).

`reschedule(expected)` is called every time the expected-reports list is recomputed, so the
reminders always match reality:

- **Cancel-and-recreate** across a reserved notification-id range (`42000..42080`).
- **Grouped by lock date** — a facility owing five reports on the same day gets **one**
  notification, not five.
- **At most two per day**: a heads-up **3 days out** and a "locks today" **on the day**,
  both at **08:00**.
- **Time zone pinned to `Africa/Addis_Ababa`** — this is a Federal Ministry of Health app;
  the server and every period boundary run on Addis time. (Pinning the zone avoids pulling
  in a device-timezone plugin.)
- **Inexact alarms only** (`AndroidScheduleMode.inexactAllowWhileIdle`) — a reminder a few
  minutes late is fine, and this keeps the app off the `SCHEDULE_EXACT_ALARM` permission
  entirely.
- `RECEIVE_BOOT_COMPLETED` lets `flutter_local_notifications` re-arm the schedule after a
  reboot; without it the app just reschedules on next launch.

## Onboarding & the app tour

`OnboardingService` (`core/onboarding/onboarding_service.dart`) — first-run gating, backed
by plain `SharedPreferences` (UI-state flags, not credentials; must survive login/logout).
Loaded **synchronously** in `main()` so the router's `redirect` (a sync function) can read
`hasSeenOnboarding` without an async round-trip.

- **First-run carousel** — `lib/features/onboarding/presentation/pages/onboarding_page.dart`,
  gated by `has_seen_onboarding`.
- **Per-screen spotlight tours** (`showcaseview`, wired via `ShowCaseWidget` in
  `main.dart`'s `MaterialApp.router` builder). Each screen with a tour owns a distinct
  `tourId` — `home`, `data_entry_routine`, `data_entry_disease`, `visualization` — so it
  triggers **once, on that screen's first visit**, rather than one monolithic tour trying
  to span separate routes.
- **"Take the tour again"** in the Home drawer → `resetAllTours()` clears every screen's
  flag; Home's replays immediately, the others on next visit.

## Background-kill protection (Android)

Once the app is backgrounded, Android's execution limits — and, more aggressively, several
OEM battery managers (Xiaomi, Huawei, Samsung, Oppo) — will kill the process mid-push.
Two mechanisms mitigate this, both under `lib/core/sync/`:

### `SyncForegroundService`

A thin wrapper over a native Android foreground service
(`android/.../SyncForegroundService.kt`, `foregroundServiceType="dataSync"`) that keeps the
process at foreground priority while a push is in flight. **Started and stopped by
`SyncCoordinator` around each push attempt** — never left running with nothing queued, so
the notification only appears when there's actually work to protect. Best-effort: a failed
service start doesn't block the sync itself. No-op on every platform except Android (iOS
caps background execution at a few seconds regardless).

Permissions: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `POST_NOTIFICATIONS`.

### `BatteryOptimization`

A one-time-**ever** prompt (tracked like `OnboardingService`'s flags) shown after login on
the Home screen, asking the user to exempt the app from OEM battery optimisation via the
OS's own dialog. Fire-and-forget — Android doesn't hand back the user's choice, so callers
re-check `isIgnoringOptimizations()` later if they need to know. Fails **open** (doesn't
nag) if the platform check itself errors.

Permission: `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (an install-time permission; the actual
exemption still requires explicit user consent in the system dialog it triggers).

## Chart draft coordinator

`ChartDraftCoordinator` (started in `main()`) finishes local-dashboard charts that were
saved while offline — running their analytics query and caching the result — the moment
connectivity returns. See [Features — visualization](10-features.md).
