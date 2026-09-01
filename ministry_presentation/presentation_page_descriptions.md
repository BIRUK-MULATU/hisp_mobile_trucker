# RDHIS2 Mobile App — Slide-by-Slide Page Descriptions

Use this as the text content for each slide. Add your own screenshot for
each one where noted; the description under it is what you'd say / write
on the slide.

---

## 1. Title Slide
**RDHIS2 Mobile App**
Health Management Information System — Ministry of Health

The official mobile data collection and reporting application built on
DHIS2. It lets health workers record, review, and submit facility health
data directly from a phone, with or without an internet connection.

---

## 2. Welcome / Onboarding
*[Screenshot: first onboarding slide]*

Shown once, the first time the app is opened. A short four-slide
walkthrough introduces the app before login:
1. **Welcome** — what the app is for.
2. **Capture data anywhere** — pick a facility, dataset and period, enter
   values, and everything saves to the phone first, even with no signal.
3. **Syncs when you're connected** — saved reports are sent to the
   server automatically once the phone is back online.
4. **Build and view charts** — turn indicators and datasets into charts,
   viewable anytime, even offline.

Users can skip ahead or step through with Next / Get Started.

---

## 3. Login
*[Screenshot: login screen]*

A simple username and password screen branded with the Ministry of
Health identity. Key details worth highlighting:
- Shows whether the phone is currently online or offline before the
  user even logs in.
- A previously logged-in user can open the app and reach Home straight
  away, without needing an internet connection.
- The DHIS2 server address can be changed from this screen (useful for
  switching between staging and production servers).
- If the server ever rejects a stored login (e.g. password changed, or
  the session ran out), the user is sent back to this screen with a
  clear "Your session has ended, please log in again" message, instead
  of a confusing silent failure.

---

## 4. Home Screen
*[Screenshot: Home, Visualization mode]*
*[Screenshot: Home, Capture mode]*

The main screen of the app, built around one big toggle at the top:

- **Visualization** — browse dashboards and charts.
- **Capture** — enter facility data.

From here the user can also open the side menu, search, and trigger a
manual sync with the server. The app remembers whichever mode was last
open.

---

## 5. Side Menu (Drawer)
*[Screenshot: open side drawer]*

Reached via the menu icon on Home. Gives access to:
- **Home**
- **Settings**
- **App Tour** — replay the guided walkthrough of the app's features
- **Log Out**
- **About** — app version and a short description of the app's purpose

---

## 6. Filter & Search Your Data
*[Screenshot: Home, filter panel expanded in Capture mode]*

A collapsible filter panel on the Capture side of Home helps a user
with many facilities or many reports narrow things down quickly:
- **Date** — quick options like Today, This Week, Last Month, or a
  custom date range.
- **Organisation Unit** — pick one facility from the full hierarchy to
  filter by, instead of typing its name.
- **Sync Status** — show only work that is Synced, Unsynced, or has a
  Sync Error.

A search bar is also available on most list screens to find an item by
name directly.

---

## 7. Capture — Step 1: Select Organisation Unit
*[Screenshot: organisation unit tree]*

The first step of data entry. Shows the health facilities and
administrative units assigned to the logged-in user as an expandable
tree (region → zone → woreda → facility, etc.). The user searches or
browses the tree and picks the unit they're reporting for.

A banner appears the first time the app downloads a user's facility
data for offline use, so entry can continue even without a connection.

---

## 8. Capture — Step 2: Select Dataset
*[Screenshot: dataset selection grid]*

After picking a facility, the user sees the datasets (report forms)
assigned to it, shown as cards. This screen has a second tab:

- **Select Dataset** — start a new report.
- **Report Period** — every report the user has already started or
  completed, across every facility they work with, so unfinished
  drafts are easy to find and continue without having to re-pick the
  facility, dataset and period from scratch.

Each report card shows whether it's Completed or Incomplete, and
whether it's Synced or still waiting to be sent to the server.

---

## 9. Capture — Step 3: Select Section
*[Screenshot: section selection]*

Some datasets are broken into sections (e.g. by disease, by service
type). This screen lists them as numbered cards. Datasets without
sections skip this step automatically and go straight to period
selection.

---

## 10. Capture — Step 4: Select Period
*[Screenshot: period selection]*

The user confirms the facility, dataset and section, then picks the
reporting period (e.g. month) from a calendar-aware picker that follows
the Ethiopian calendar. If the dataset has its own extra breakdowns
(like Department or Outcome), a dropdown for each appears here too,
right before opening the form, so the form itself only ever shows one
combination at a time.

---

## 11. Data Entry Form — Routine Reporting
*[Screenshot: data entry table, filled in]*

The core data-capture screen: a table of data elements for the chosen
dataset, section and period. Users type values directly into cells.
Highlights to call out:
- Works fully offline — values are saved to the device as they're
  typed.
- A sync icon lets the user pull the latest values from the server or
  push what's saved locally.
- Pull-down-to-refresh reloads the form's values from the server.
- A search bar helps find a specific data element in a long form.

---

## 12. Data Entry Form — Disease Registration
*[Screenshot: disease registration list]*
*[Screenshot: "select a new disease" search]*

A specialised entry mode for disease case registration datasets, using
a searchable list layout instead of a table — suited to registering
individual cases rather than aggregate totals. A search field at the
top lets the user find and add a disease that hasn't been recorded yet
for this report; a fresh entry block appears for it above the ones
already filled in.

---

## 13. Live Validation
*[Screenshot: validation warning banner expanded]*

As the user types, the app checks the entered values against the
dataset's validation rules in the background and shows a banner if
anything looks off (e.g. totals that don't add up). Tapping the banner
expands the full list of issues, ranked by how serious they are, so
the user can review and fix them before submitting — without ever
blocking data entry itself.

---

## 14. Save, Complete & Reopen
*[Screenshot: complete confirmation]*

When finished, the user saves the report and marks it **Complete**.
Completed reports can be reopened later if a correction is needed
(subject to the reporting deadline for that period). Once a period's
deadline has passed, its data becomes view-only.

---

## 15. Print / Export to PDF
*[Screenshot: PDF export options]*
*[Screenshot: PDF preview]*

A completed or in-progress report can be exported as a PDF and printed
or shared. Before generating it, the user chooses between two options:
**only the values that were recorded**, or **the full form including
blank fields** — useful for keeping a paper record or sharing with a
supervisor.

---

## 16. Cell History (Audit Trail)
*[Screenshot: cell history bottom sheet]*

Tapping into a single data-entry cell's history shows who changed that
value and when — both the change history recorded on the server and
anything edited on this device that hasn't been sent yet. This gives
full accountability for every reported number.

---

## 17. Visualization — Server Dashboards
*[Screenshot: server dashboard list]*

Mirrors the dashboards available on the DHIS2 web application. The user
browses every dashboard they have access to on the server.

---

## 18. Visualization — Dashboard Detail
*[Screenshot: dashboard with charts]*
*[Screenshot: offline cache banner]*

Opening a dashboard shows all of its charts, tables and indicators laid
out the same way as on the web dashboard, rendered natively on the
phone. If the phone can't reach the server, the app falls back to the
last successful copy of the dashboard and shows a banner noting the
data is cached, along with when it was last refreshed.

---

## 19. Visualization — Local Dashboard
*[Screenshot: local dashboard / saved charts list]*

A separate, personal collection of charts the user has built themselves
directly on their device. These stay available offline and are kept
completely separate from the server's own dashboards.

---

## 20. Visualization — Create a New Chart
*[Screenshot: chart builder form]*

A simple chart-building screen: pick a chart type (bar, line, pie,
etc.), choose what to chart (an indicator, data element or dataset), an
organisation unit, and a period — then preview it instantly. Saving adds
it to the Local Dashboard.

---

## 21. Visualization — View / Edit a Saved Chart
*[Screenshot: single chart view with edit option]*

Opens a saved chart full-screen, re-running it against the latest data.
From here the user can edit the chart's settings or delete it.

---

## 22. Settings
*[Screenshot: settings screen]*

Shows the logged-in user's name and assigned facility, the DHIS2 server
address in use, the app version, and a Log Out option.

---

## 23. Designed for the Field — Offline & Sync
*[Screenshot: connectivity status pill, online and offline]*
*[Screenshot: battery optimization prompt]*

A cross-cutting set of features worth its own slide, since it touches
every screen in the app:
- **Always-visible connection status** — a small pill in the header
  shows Online or Offline at a glance, based on an actual check against
  the server (not just the phone's Wi-Fi/data icon), and can be tapped
  to re-check immediately.
- **Offline-first capture** — data typed offline is stored safely on
  the device and automatically sent to the national server the moment
  the phone reconnects, so field staff are never blocked by poor
  connectivity.
- **Pull-to-refresh** — available throughout the app (facility lists,
  reports, forms, charts) to manually re-sync a screen with the server
  on demand.
- **Reliable background sync** — on first use, Android phones are
  prompted (once) to exempt the app from battery-saving restrictions,
  so queued reports still reach the server automatically even if the
  app isn't open at the time.

---

## 24. Guided App Tour
*[Screenshot: onboarding tour tooltip overlay, e.g. on Home]*

New users are guided through each major screen the first time they
visit it, with short pop-up tips pointing at key buttons (search, sync,
mode toggle, save). The full tour can be replayed anytime from the side
menu.

---

*End of deck outline — insert your own screenshots where marked and
adjust wording to match your narration.*
