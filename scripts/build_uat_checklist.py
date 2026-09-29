#!/usr/bin/env python3
"""Builds the RDHIS2 Mobile Tracker UAT Testing Checklist as a print-ready PDF.

    python3 scripts/build_uat_checklist.py

Output: docs/UAT_Testing_Checklist.pdf  (and the intermediate .html)

Uses wkhtmltopdf (already used elsewhere in this repo's tooling tree). If
wkhtmltopdf is missing the script still writes the HTML and exits non-zero.
"""
import datetime as dt
import html
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "docs")
HTML_PATH = os.path.join(OUT_DIR, "UAT_Testing_Checklist.html")
PDF_PATH = os.path.join(OUT_DIR, "UAT_Testing_Checklist.pdf")

APP_NAME = "RDHIS2 Mobile Tracker"
APP_VERSION = "1.0.0"
BUILD_DATE = dt.date.today().strftime("%d %B %Y")

# ---------------------------------------------------------------------------
# Test case data: (id, title, steps, expected)
# ---------------------------------------------------------------------------
SECTIONS = []


def section(code, title, blurb, cases):
    SECTIONS.append({"code": code, "title": title, "blurb": blurb, "cases": cases})


def case(cid, title, steps, expected):
    return {"id": cid, "title": title, "steps": steps, "expected": expected}


# --- A. Onboarding & first run ---------------------------------------------
section(
    "A",
    "Onboarding & First-Run Experience",
    "Fresh-install behaviour, the welcome carousel, spotlight app tours and the "
    "one-time battery-optimisation prompt.",
    [
        case("ONB-01", "First-launch carousel",
             "Fresh install. Open the app for the very first time.",
             "Four slides appear in order: 'Welcome to RDHIS2 Mobile App', "
             "'Capture data anywhere', \"Syncs when you're connected\", "
             "'Build and view charts'. Each has an illustration, title and body text."),
        case("ONB-02", "Carousel navigation",
             "Tap 'Next' through the slides; on the last slide read the button.",
             "Button reads 'Next' on slides 1-3 and changes to 'Get Started' on the last. "
             "'Skip' is visible on slides 1-3 and hidden on the last."),
        case("ONB-03", "Skip onboarding",
             "On slide 1 tap 'Skip'.",
             "Carousel closes and the Login screen is shown. Relaunching the app does "
             "not show the carousel again."),
        case("ONB-04", "Complete onboarding",
             "On the last slide tap 'Get Started'.",
             "Carousel closes and the Login screen is shown."),
        case("ONB-05", "Home spotlight tour",
             "Log in and land on Home for the first time.",
             "A spotlight tour highlights the menu, search, sync button and the "
             "Visualization/Capture toggle ('Switch modes'). It can be stepped through."),
        case("ONB-06", "Per-screen tours",
             "Visit a routine form, a disease-registration form and the Visualization tab.",
             "Each screen shows its own one-time spotlight tour (routine entry, disease "
             "entry, dashboards/builder). They do not repeat on later visits."),
        case("ONB-07", "Replay the app tour",
             "Open the drawer and tap 'App Tour'; return to Home, then revisit the other screens.",
             "Home's tour replays immediately; the other screens replay on their next visit."),
        case("ONB-08", "Battery-optimisation prompt",
             "Log in on an Android device the first time.",
             "Dialog 'Keep offline sync reliable' appears with 'Not now' / 'Allow'. "
             "Choosing either dismisses it and it is never shown again."),
        case("ONB-09", "Prompt fail-open",
             "Dismiss the battery prompt and continue working offline.",
             "No repeated nagging; the app continues to function if the prompt errors."),
    ],
)

# --- B. Authentication & session -------------------------------------------
section(
    "B",
    "Authentication & Session",
    "Online and offline login, credential validation, server switching, session "
    "expiry and logout.",
    [
        case("AUTH-01", "Online login with valid credentials",
             "On Wi-Fi/data, enter a valid username and password, tap 'Log in'.",
             "Login succeeds and Home opens. On the very first login a 'Downloading data' "
             "overlay appears while metadata is pulled for offline use."),
        case("AUTH-02", "Invalid credentials",
             "Enter a wrong username or password while online and submit.",
             "Login is refused with a clear message such as 'Invalid server URL or "
             "credentials.' The user stays on the login screen."),
        case("AUTH-03", "Empty-field validation",
             "Leave username and/or password blank and submit.",
             "'Please enter your username' and/or 'Please enter your password' is shown."),
        case("AUTH-04", "Short-password validation",
             "Enter a password shorter than the minimum and submit.",
             "'Password is too short' is shown; no login attempt is made."),
        case("AUTH-05", "Offline login (previously used account)",
             "Log in online once, log out, enable airplane mode, log in with the same credentials.",
             "Login succeeds offline using the locally stored verifier. No network error "
             "is shown."),
        case("AUTH-06", "Offline login (never-used account)",
             "On a fresh device in airplane mode, try an account never logged in before.",
             "Login fails with a clear message; the app does not hang."),
        case("AUTH-07", "Change DHIS2 server URL",
             "Tap the server icon on the login screen; open 'DHIS2 Server'.",
             "Dialog shows the hint 'https://server/api'. An invalid address shows "
             "'Enter a valid server address'. A valid address save shows 'Server set to <url>'."),
        case("AUTH-08", "Session expiry / 401",
             "Invalidate the session server-side (or wait for expiry), then use the app.",
             "The user is returned to login with 'Your session has ended. Please log in again.'"),
        case("AUTH-09", "Logout from drawer",
             "Drawer -> 'Log Out'.",
             "App returns to the Login screen."),
        case("AUTH-10", "Logout from Settings (confirmation)",
             "Settings -> 'Log out'.",
             "Confirm dialog 'Log out?' with text 'You will need to log in again. Data not "
             "yet synced stays on this device.', plus 'Cancel' / 'Log out'."),
        case("AUTH-11", "Re-login preserves local data",
             "With draft/unsynced values on the device, log out and log back in as the same user.",
             "The drafts and unsynced values are still present; the same local database is reused."),
        case("AUTH-12", "Login pushes queued work",
             "Create offline pending data, then log out and log in while online.",
             "Queued values are pushed automatically as part of login."),
        case("AUTH-13", "Per-user data isolation",
             "Log in as user A, enter data, log out, log in as user B.",
             "User B cannot see user A's drafts or data; each user has a separate database."),
    ],
)

# --- C. Home shell & navigation --------------------------------------------
section(
    "C",
    "Home Shell & Navigation",
    "The mode toggle, mode-aware search, app-bar actions, filters, drawer and "
    "connectivity indicator.",
    [
        case("HOME-01", "Default mode",
             "Open Home after login.",
             "Visualization mode is selected by default."),
        case("HOME-02", "Mode toggle",
             "Tap between 'Visualization' and 'Capture'.",
             "The content area swaps between dashboards and the organisation-unit tree."),
        case("HOME-03", "Mode-aware search hint",
             "Open search in each mode.",
             "Capture mode hint: 'Search reports...'. Visualization mode hint: "
             "'Search dashboards or charts...'."),
        case("HOME-04", "Drawer items",
             "Open the drawer.",
             "Items present: Home, Setting, App Tour, Log Out, About. Each opens the "
             "expected destination."),
        case("HOME-05", "About dialog",
             "Drawer -> 'About'.",
             "Shows app name and 'Version 1.0.0' plus description; 'Close' dismisses it."),
        case("HOME-06", "Connectivity indicator",
             "Toggle airplane mode on/off while on Home.",
             "Indicator shows 'Online' / 'Offline' with tooltips 'Connected to the server' / "
             "'No server connection — changes are saved on this device'."),
        case("HOME-07", "Sync button states",
             "Observe the sync button before/during/after a sync.",
             "Tooltips read 'Sync' / 'Syncing' / 'Sync all'; a result snackbar is shown when done."),
        case("HOME-08", "Filter panel rows",
             "Switch to Capture and open filters.",
             "Rows labelled DATE, ORG. UNIT, SYNC. Idle summary reads 'No filters applied'."),
        case("HOME-09", "Date filter options",
             "Open the DATE filter.",
             "Options include Today, Yesterday, Tomorrow, This/Last/Next Week, "
             "This/Last/Next month, From -To, Other, Any time. A custom range shows as dd/MM/yyyy."),
        case("HOME-10", "Sync-state filter options",
             "Open the SYNC filter.",
             "Options are 'Synced', 'UnSynced', 'Sync Error'. Selecting one filters the report list."),
        case("HOME-11", "Organisation-unit filter",
             "Open ORG. UNIT; search and use 'Choose from organisation unit tree'.",
             "Search filters the list; the full-page tree allows selection; "
             "'Apply Filter' applies and a clear control removes it."),
        case("HOME-12", "Sync refreshes capture tree",
             "In Capture with unsynced chips shown, tap Sync.",
             "On completion the tree/chips refresh to reflect the just-completed push."),
    ],
)

# --- D. Capture workflow ----------------------------------------------------
section(
    "D",
    "Capture Workflow (Org Unit -> Dataset -> Section -> Period)",
    "The offline capture navigation: lazily loaded org-unit tree, dataset selection, "
    "sections, the Ethiopian-calendar period picker and disease-registration combos.",
    [
        case("CAP-01", "Org-unit tree lazy loading",
             "Open Capture; expand nodes one level at a time.",
             "Only one level loads per expand ('Loading organisation units...' while fetching). "
             "The full ~38,000-unit tree is never loaded at once and the UI stays responsive."),
        case("CAP-02", "Org-unit search & empty states",
             "Search for an org unit; also test a query with no matches.",
             "Matching units are listed; a no-match query shows 'No results for \"<query>\"'. "
             "Header reads 'Select an organisation unit to capture data for'."),
        case("CAP-03", "Select an organisation unit",
             "Tap an org unit leaf.",
             "Header shows 'Selected: <name>' and 'Continue' is enabled to proceed."),
        case("CAP-04", "Dataset list",
             "Open 'Select Dataset' for an org unit.",
             "Datasets assigned to the org unit are listed, each searchable, with a "
             "Synced/Unsynced chip. Empty state: 'No datasets available' or the "
             "'No datasets are assigned to <orgUnit>' message."),
        case("CAP-05", "Load-failure state",
             "Open the dataset list with the local DB empty / metadata missing.",
             "A 'Could not load datasets' error with 'Try Again' (or a prompt to log in "
             "online) is shown; retry recovers."),
        case("CAP-06", "Dataset 'Sync all'",
             "From the dataset page tap 'Sync all' while online.",
             "Button changes to 'Syncing' and the list refreshes after the push."),
        case("CAP-07", "Section selection",
             "Open a dataset that has sections.",
             "Page 'Select Section' lists numbered sections; subtitle shows '<dataset> · <period>'. "
             "Datasets without sections skip straight to the period."),
        case("CAP-08", "Period picker",
             "Reach 'Report Period'.",
             "Field labelled 'Report Period', defaults to the current period for the dataset's "
             "period type (default 'Monthly'). Ethiopian month names are displayed."),
        case("CAP-09", "Period gating",
             "Try to select an expired or not-yet-open period.",
             "Expired periods are not selectable; future ones may show 'not open yet'. "
             "Period open/expired honours expiryDays and openFuturePeriods."),
        case("CAP-10", "Clock-tamper warning",
             "With the tamper flag set, open the period picker.",
             "Warning shown: \"This device's clock was set backwards. Only the current period "
             "is open until the app reconnects to the server.\""),
        case("CAP-11", "Disease registration flow",
             "Open a Disease Registration dataset.",
             "A category-combo picker appears before the form; the app bar/section show 'Disease "
             "Registration' and the form is themed accordingly."),
        case("CAP-12", "New-report entry point",
             "Tap the '+' / 'New report' button.",
             "The capture flow starts (org unit -> dataset -> ...) as expected."),
        case("CAP-13", "Category-combo resolution error",
             "Select combos when metadata is incomplete.",
             "Banner: 'Could not resolve the selected combination — try again once metadata "
             "has synced.' The user can recover."),
    ],
)

# --- E. Reports list & To-do band ------------------------------------------
section(
    "E",
    "Reports Overview & To-do Band",
    "The Report Period list (all reports across all org units) and the 'Reports to "
    "fill' / To-do band with urgency.",
    [
        case("RPT-01", "Empty report list",
             "Open Report Period with no reports touched.",
             "'No reports yet' plus guidance to tap + to start one."),
        case("RPT-02", "Reports across all org units",
             "Complete/draft reports at more than one facility.",
             "All reports appear in one list, routine and disease registration merged."),
        case("RPT-03", "Report status chips",
             "Inspect report cards.",
             "Cards show 'Completed'/'Incomplete' and 'Synced'/'Unsynced' as applicable."),
        case("RPT-04", "Report card identity",
             "Inspect a disease-registration report card.",
             "Card reads '<period> · <org unit>' and, for disease registration, also "
             "'· <combo>' so reports sharing dataset/period/org unit are not conflated."),
        case("RPT-05", "'Reports to fill' band",
             "Open the To-do band online and offline.",
             "Lists reports still owed. Empty state: 'Nothing to fill' + 'Every report assigned "
             "to your organisation units is up to date.'"),
        case("RPT-06", "Urgency labels",
             "Inspect items due at different times.",
             "Labels show Overdue / Due soon / Open with the relevant lock date "
             "(e.g. 'Overdue — locked 5 Jan', 'Locks 5 Jan')."),
        case("RPT-07", "Started / Not started",
             "Inspect an item that has local work vs one with none.",
             "'Started' is shown when something is already queued; otherwise 'Not started'."),
        case("RPT-08", "Report search & filters",
             "Search and filter the report list with no matches.",
             "Matching reports remain; a no-match state shows 'No results' + "
             "'No reports match the current search or filters.'"),
        case("RPT-09", "Reopening un-finishes a report",
             "Open a completed report and save a draft instead of completing.",
             "The report shows as 'Incomplete' in the list (intended behaviour)."),
        case("RPT-10", "Server completion pull",
             "Complete a report for the same dataset/period/org unit on the web, then refresh in-app.",
             "The item disappears from 'Reports to fill' after the best-effort server pull."),
    ],
)

# --- F. Data entry form -----------------------------------------------------
section(
    "F",
    "Data Entry Form",
    "Opening, editing, saving, completing and reopening forms, plus all the entry "
    "controls (options, booleans, controller elements, disease list, totals).",
    [
        case("DE-01", "Open a form online",
             "Open a routine form while online.",
             "Server values for that form are pulled, conflicts resolved, and the form renders. "
             "A pull failure does not block the form."),
        case("DE-02", "Open a form offline",
             "Open the same form in airplane mode after a prior sync.",
             "The form opens from local data with cached values; no blocking network error."),
        case("DE-03", "Edit a numeric cell",
             "Type a number into a numeric/ integer/ positive-integer cell.",
             "The value is accepted and shown; the cell is marked modified."),
        case("DE-04", "Edit other value types",
             "Enter values into percentage, unit-interval, date, phone and e-mail cells.",
             "Each type accepts only valid input; invalid input is flagged inline."),
        case("DE-05", "Option-set picker",
             "Tap a cell that uses an option set.",
             "An option grid opens; choosing an option sets the value. 'Clear value' "
             "removes it."),
        case("DE-06", "Boolean / true-only cells",
             "Tap boolean and true-only cells repeatedly.",
             "Values cycle 'Yes'/'No'/'-' (true-only toggles Yes/none)."),
        case("DE-07", "Greyed-out field",
             "Hover/tap a greyed field.",
             "Not editable; tooltip \"This combination isn't applicable and can't be entered.\""),
        case("DE-08", "Controller element gating",
             "Change a controller element that others depend on from Yes to No.",
             "Confirm dialog 'Clear entered data?' explains N values will be erased; "
             "'Clear and close' erases and hides them, 'Cancel' reverts."),
        case("DE-09", "Save as draft",
             "Edit values and tap the 'Save' FAB.",
             "Values save locally as a draft; snackbar confirms saving as a draft on this device."),
        case("DE-10", "Invalid value blocks save",
             "Enter an invalid value (e.g. letters in a number cell) and tap Save.",
             "Save is blocked; message names the first problem and asks to fix the red cell(s). "
             "Nothing invalid reaches the database."),
        case("DE-11", "Complete - clean form",
             "With all mandatory fields filled and no issues, tap Save then 'Complete'.",
             "Dialog 'Everything looks good'; completing shows 'Data set completed successfully!' "
             "and values are queued/pushed."),
        case("DE-12", "Complete - missing mandatory fields",
             "Leave a compulsory field blank and try to complete.",
             "Dialog 'N required field(s) missing' blocks completion; the required cell is indicated."),
        case("DE-13", "Complete - validation issues",
             "Create a validation-rule violation and try to complete.",
             "Dialog 'N validation issue(s) found' warns; the user may 'Review data' or "
             "'Complete anyway'."),
        case("DE-14", "Reopen a completed form",
             "Open a completed report, change a value and tap Save.",
             "Dialog 'This data set is completed' offers 'Incomplete' (reopen, edits stay drafts) "
             "or 'Keep completed' (sends saved changes and stays completed)."),
        case("DE-15", "Closed period is view-only",
             "Open a form whose period is closed.",
             "Header chip 'Closed · View only'; the Save FAB is hidden and cells are read-only."),
        case("DE-16", "Search within the form",
             "Use the form search field.",
             "Data elements filter as typed; 'No results for \"<query>\"' when empty."),
        case("DE-17", "Reload values",
             "Make an unsaved edit, then tap 'Reload values'.",
             "If unsaved changes exist, 'Save your changes before reloading.'; otherwise "
             "server/local values reload."),
        case("DE-18", "Row totals & calculated fields",
             "Inspect summation rows and auto-calculated cells.",
             "Totals sum the row; calculated cells show 'Automatically calculated — not entered directly'."),
        case("DE-19", "Previous-entries hint",
             "Enter a numeric value in a cell with history.",
             "Hint shows 'Higher/Lower/Within last N' with the previous values listed."),
        case("DE-20", "Disease entry list",
             "On a disease form, use 'Select for new disease'.",
             "A new disease form is added; existing diseases can be 'Collapse'/'Expand'; "
             "when all are added, 'Every disease has already been added'."),
        case("DE-21", "Section navigation",
             "Move between collapsible sections in a large form.",
             "Sections expand/collapse smoothly and the correct fields are shown."),
    ],
)

# --- G. Data quality --------------------------------------------------------
section(
    "G",
    "Data Quality & Validation",
    "The offline data-quality suite: value-type checks, validation rules, "
    "mandatory fields, outliers and the per-cell audit trail.",
    [
        case("DQ-01", "Value-type validation",
             "Type an out-of-range or wrong-format value into a typed cell.",
             "The cell is flagged and the value cannot be saved with the form."),
        case("DQ-02", "Validation rules warn (do not block)",
             "Enter values that violate a synced DHIS2 validation rule.",
             "A warning is shown at completion and in the live banner; completing anyway "
             "is still possible (same contract as the DHIS2 web app)."),
        case("DQ-03", "Live validation banner",
             "Enter values that trigger a rule while typing.",
             "Banner 'N validation issue(s) — tap to review' updates live; tapping shows details "
             "with rule name and comparison."),
        case("DQ-04", "Mandatory fields block completion",
             "Attempt to complete with compulsory operands blank.",
             "Completion is blocked until the mandatory field(s) are filled."),
        case("DQ-05", "Grey fields cannot be entered",
             "Try to edit a server-configured grey field.",
             "Field is non-editable."),
        case("DQ-06", "Controller element hides group",
             "Set a controller element to No.",
             "Dependent elements are hidden and their existing values cleared after confirmation."),
        case("DQ-07", "Outlier warning (single value)",
             "Type a value far outside the cell's recent history.",
             "After ~600 ms a dialog 'Are you sure?' shows the typical value, historical range and "
             "bounds, with 'Go back and correct' / 'Save value'."),
        case("DQ-08", "Outlier acknowledgement",
             "Choose 'Save value' on an outlier, then edit the cell again.",
             "The value is kept and the warning is not repeated for that cell until settings change."),
        case("DQ-09", "Outlier warning (multiple)",
             "Produce several outliers at once.",
             "Dialog lists the values with 'N values look very different...' and offers "
             "'Go back' / 'Save anyway'."),
        case("DQ-10", "Outlier settings",
             "Open 'Outlier check' from the form menu.",
             "Algorithms 'Z-score', 'Modified Z-score', 'Min-Max' and a threshold slider "
             "('more sensitive' ... 'less sensitive') are available; 'Save' applies and re-runs "
             "the check."),
        case("DQ-11", "Audit trail - local edits",
             "Long-press a cell with local edits and open its history.",
             "History sheet shows 'On this device' entries with old/new value, actor and time "
             "(statuses include 'Saved as a draft', 'Waiting to sync', 'Synced', 'Rejected')."),
        case("DQ-12", "Audit trail - server history",
             "Open history online for a cell changed on another client.",
             "Server entries appear (CREATE/UPDATE/DELETE) under the server banner "
             "'Change history below is from the DHIS2 server'."),
        case("DQ-13", "Audit trail - offline",
             "Open history in airplane mode.",
             "Banner 'Offline — showing this device's own edit log below'; local entries still show."),
        case("DQ-14", "Audit trail - empty",
             "Open history for a never-edited cell.",
             "'No changes recorded for this cell yet.'"),
    ],
)

# --- H. Offline & synchronization ------------------------------------------
section(
    "H",
    "Offline-First & Synchronization",
    "Draft -> pending -> synced/error state machine, automatic and manual sync, "
    "conflict resolution, server rejections and metadata sync.",
    [
        case("SYNC-01", "Full offline data entry",
             "In airplane mode: browse, open a form, enter values, save and complete.",
             "Everything works with no network. Nothing is lost; values are queued locally."),
        case("SYNC-02", "State transitions",
             "Observe a value's state after complete and after a successful push.",
             "Value moves draft -> pending on Complete -> synced after the server accepts it."),
        case("SYNC-03", "Auto-sync on reconnect",
             "Create offline pending data, then restore connectivity.",
             "Queued values upload automatically on the offline->online transition."),
        case("SYNC-04", "Auto-sync on login",
             "Log in while online with pending data already on the device.",
             "Queued values upload as part of login."),
        case("SYNC-05", "Heartbeat sync",
             "Leave pending data and stay online without any event.",
             "Within the 5-minute heartbeat the pending values are eventually pushed."),
        case("SYNC-06", "Manual sync outcomes",
             "Tap the sync button in each situation: offline with pending, offline with none, "
             "all synced, uploaded, partial, failed.",
             "Each shows its specific message, e.g. 'Sync complete — N entry/entries uploaded.', "
             "'Everything is already synced.', 'Sync failed — your entries are safe on this device...'."),
        case("SYNC-07", "Conflict - draft always wins",
             "Create a draft, change the same cell on the web, reopen the form online.",
             "The local draft is kept and not overwritten by the server value."),
        case("SYNC-08", "Conflict - newest wins",
             "With a pending value differing from the server, reopen the form online.",
             "The newer of the two wins; a genuinely newer local edit stays pending and is pushed."),
        case("SYNC-09", "Conflict - tampered clock",
             "Set the device clock back, create a conflicting pending value, reopen online.",
             "The server value wins while the clock is suspect."),
        case("SYNC-10", "Server rejection handling",
             "Push a value the server rejects (wrong type / not in option set).",
             "The cell turns red with the server's reason; editing it clears the error and "
             "re-queues it as pending."),
        case("SYNC-11", "Completion registration push",
             "Complete a dataset online, then mark it incomplete.",
             "Completion is POSTed (and DELETE) to the server; reopen succeeds."),
        case("SYNC-12", "Metadata full sync",
             "Log in for the first time on a fresh device.",
             "A full metadata download scoped to the user's own org-unit subtree completes; "
             "only then is the device ready for offline capture."),
        case("SYNC-13", "Metadata delta sync",
             "Log in again online later.",
             "Only changed/new metadata is fetched; deletions on the server are removed locally."),
        case("SYNC-14", "Offline org-unit depth bound",
             "Inspect the offline org-unit tree for a woreda-assigned user.",
             "Capture roots plus their direct children are stored; deeper levels remain "
             "reachable online via the live fallback."),
        case("SYNC-15", "Tamper-resistant clock",
             "Set the device clock backwards, then reopen the app.",
             "Past periods are refused/warned; the current period still works; reconnecting "
             "anchors the clock to the server and clears the flag."),
        case("SYNC-16", "Background kill protection (Android)",
             "Start a sync, background the app and check notifications.",
             "A foreground 'dataSync' notification appears only while work is in flight; "
             "if the process is killed, pending values remain queued and retry later."),
        case("SYNC-17", "Transport failure safety",
             "Cause a sync to fail mid-flight (drop network during push).",
             "Values remain pending (never marked synced); a later sync retries them."),
    ],
)

# --- I. Reports list & To-do band (VIS moved) -------------------------------
section(
    "I",
    "Visualization & Dashboards",
    "Server dashboards, on-device local dashboards, the chart builder and offline "
    "caching.",
    [
        case("VIS-01", "Three visualization tabs",
             "Open the Visualization tab.",
             "Flat tabs 'Server Dashboard', 'Local Dashboard', 'Create New' are present."),
        case("VIS-02", "Server dashboards load",
             "Open 'Server Dashboard' online.",
             "DHIS2 server dashboards are listed; opening one renders its charts natively. "
             "Each chart loads independently, so one failure does not block the rest."),
        case("VIS-03", "Per-chart retry",
             "With a chart that failed to load, tap its 'Retry'.",
             "Only that chart re-fetches; the rest of the dashboard is unaffected."),
        case("VIS-04", "Unsupported items notice",
             "Open a dashboard containing unsupported item types (e.g. maps).",
             "A notice such as 'N items not supported' is shown; the rest renders."),
        case("VIS-05", "Offline cache banner",
             "Load a dashboard, then switch to airplane mode and reopen it.",
             "Charts render from cache with 'Offline — showing cached data' (and a timestamp)."),
        case("VIS-06", "Local dashboard empty state",
             "Open 'Local Dashboard' with no saved charts.",
             "'No local charts yet' + 'Build your first chart...'."),
        case("VIS-07", "Create a chart",
             "In 'Create New', choose chart type, data type, group/items, org unit and period, then save.",
             "'Chart saved.'; the chart appears under Local Dashboard and is never pushed to the server."),
        case("VIS-08", "Chart types render",
             "Create/view Column, Bar, Line, Pie, Single Value and Gauge charts.",
             "Each renders correctly; an empty result shows 'No data'."),
        case("VIS-09", "Data types",
             "Build charts from Indicator, Data Element and Dataset sources.",
             "Each source offers the right group/item picker and metric options "
             "(Reporting Rate, Actual Reports, etc.)."),
        case("VIS-10", "Relative vs fixed period",
             "Toggle 'Relative Period' / 'Fixed Period' in the builder.",
             "Relative flags (This Month, Last 3 Months, This Financial Year, ...) and fixed "
             "periods both produce a query."),
        case("VIS-11", "Edit a local chart",
             "Open a saved chart and tap 'Edit chart'.",
             "'Edit Chart' page loads; 'Save Changes' updates it and shows 'Chart updated.'"),
        case("VIS-12", "Delete a local chart",
             "Tap the delete action on a local chart.",
             "Dialog 'Delete chart?' with '\"<name>\" will be removed from your charts.'; "
             "'Delete' removes it."),
        case("VIS-13", "Offline chart-builder draft",
             "Build a chart while offline and tap 'Save as Draft'.",
             "A 'Saved offline — will finish building once back online' chip appears; on regaining "
             "connectivity the draft is finished automatically."),
        case("VIS-14", "Misconfigured visualization",
             "Attempt to render a visualization with no period dimension.",
             "A clear, displayable configuration message is shown instead of a generic network error."),
        case("VIS-15", "Search dashboards/charts",
             "Search in Visualization mode.",
             "Dashboards are searched in Server mode and local charts in Local mode; "
             "no-match states are shown."),
    ],
)

# --- J. Export --------------------------------------------------------------
section(
    "J",
    "Export (PDF & Excel)",
    "Exporting an open form for paper backup or off-device review.",
    [
        case("EXP-01", "Export as PDF",
             "Open a form, tap 'Download' -> 'Download as PDF'.",
             "Prompt 'What should the PDF include?' with 'Only recorded' / 'All elements'. "
             "A saved/shared PDF is produced."),
        case("EXP-02", "PDF content",
             "Open the exported PDF.",
             "Header '<org unit> · <period>', 'Generated <date>', a value table, "
             "'Page N / M' footers, and 'Nothing to show.' when empty."),
        case("EXP-03", "Export as Excel",
             "Open a form, tap 'Download' -> 'Download as Excel'.",
             "An .xlsx is shared with a 'Data' sheet, columns 'Data Element' / 'Category' / "
             "'Value', and a 'Generated by <user>' line."),
        case("EXP-04", "Export offline",
             "Export a form in airplane mode.",
             "Export succeeds from local data."),
        case("EXP-05", "Export filenames",
             "Check the suggested filename for each export.",
             "Format '<title> - <period>.pdf' / '.xlsx'."),
    ],
)

# --- K. Notifications -------------------------------------------------------
section(
    "K",
    "Notifications & Deadline Reminders",
    "On-device local reminders for reports due before their lock date.",
    [
        case("NOT-01", "Reminder permission",
             "First time reminders are needed, grant/deny notification permission.",
             "Permission is requested; if denied the app disables reminders silently and keeps working."),
        case("NOT-02", "3-day heads-up",
             "Have a report locking in 3 days and wait/trigger the schedule.",
             "At 08:00 (Africa/Addis_Ababa) a 'Reports lock soon' notification lists the report(s)."),
        case("NOT-03", "Lock-day reminder",
             "Have a report locking today.",
             "A 'Reports lock today' notification is delivered at 08:00."),
        case("NOT-04", "Grouping by facility/date",
             "Have multiple reports locking on the same day at one facility.",
             "A single grouped notification is delivered, not one per report."),
        case("NOT-05", "Reschedule on change",
             "Complete one of the pending reports and refresh the To-do list.",
             "The stale reminder is cancelled and the schedule reflects the remaining reports."),
        case("NOT-06", "Reboot behaviour (Android)",
             "Reboot the device.",
             "Reminders are re-armed (or rescheduled on next launch) without duplication."),
    ],
)

# --- L. Settings ------------------------------------------------------------
section(
    "L",
    "Settings",
    "Account, server and app information plus logout.",
    [
        case("SET-01", "Profile information",
             "Open Settings.",
             "Shows the logged-in username and primary organisation unit "
             "(fallbacks 'Not logged in' / 'No organisation unit')."),
        case("SET-02", "Server URL display/edit",
             "Inspect and change the server URL from Settings.",
             "Current URL is shown; 'DHIS2 Server' dialog validates and saves it."),
        case("SET-03", "App version",
             "Inspect the About section.",
             "Shows 'App version' with 'RDHIS2 Mobile App 1.0.0'."),
        case("SET-04", "Logout confirmation",
             "Tap 'Log out'.",
             "Dialog 'Log out?' with the 'Data not yet synced stays on this device.' notice; "
             "confirming returns to login."),
    ],
)

# --- M. Edge cases & error handling ----------------------------------------
section(
    "M",
    "Edge Cases & Error Handling",
    "Recovery paths and boundary conditions testers should actively try to break.",
    [
        case("EDGE-01", "No connectivity at first use",
             "Fresh install, no network, attempt login.",
             "A clear 'No internet connection.'-style message is shown; the app does not crash."),
        case("EDGE-02", "Server error / timeout",
             "Point at an unreachable or erroring server and act.",
             "'Server error. Please try again.' / 'Connection timed out. Please try again.' "
             "messages are shown; local data is unaffected."),
        case("EDGE-03", "No datasets assigned",
             "Open an org unit with no assigned datasets.",
             "Guidance is shown: 'No datasets are assigned to <orgUnit>...' to pick another "
             "unit or contact an administrator."),
        case("EDGE-04", "Same report, different combos",
             "Create two disease reports with the same dataset/period/org unit but different combos.",
             "They remain separate entries and are not conflated."),
        case("EDGE-05", "Large org-unit hierarchy performance",
             "Expand deep branches of the national org-unit tree.",
             "The tree stays responsive (lazy per-level loading); no freeze or memory spike."),
        case("EDGE-06", "App backgrounded during entry",
             "Enter values, background the app, return.",
             "Entered values are preserved and the form/state is intact."),
        case("EDGE-07", "Rotation / small screen",
             "Rotate the device and test on a small screen.",
             "Layouts reflow without clipping key controls."),
        case("EDGE-08", "Duplicate / rapid taps",
             "Rapidly tap Save and Complete.",
             "No duplicate submissions or crashes; state remains consistent."),
        case("EDGE-09", "Storage pressure",
             "Fill the local database with many values and sync.",
             "Batches are chunked (500 values/request) and no data is lost on a mid-transfer drop."),
    ],
)

# --- N. Non-functional ------------------------------------------------------
section(
    "N",
    "Non-Functional Checks",
    "Performance, reliability, security and usability observations.",
    [
        case("NFR-01", "Performance",
             "Time form open, org-unit expansion, saving and syncing.",
             "All interactions complete in an acceptable time with no visible jank."),
        case("NFR-02", "Battery / background behaviour",
             "Leave the app installed and connected over a period.",
             "Heartbeat and reminders do not noticeably drain the battery."),
        case("NFR-03", "Credential security",
             "Inspect stored credentials.",
             "Passwords are not stored in plain text (a salted verifier is used); session data "
             "is in secure storage."),
        case("NFR-04", "Data durability",
             "Force-kill the app mid-sync.",
             "No committed data is lost; pending items retry on next launch."),
        case("NFR-05", "Text scaling / accessibility",
             "Increase the system font size.",
             "Labels remain readable and controls usable."),
        case("NFR-06", "Localization",
             "Inspect the UI language.",
             "UI is English with the Amharic Ministry heading on login; note any untranslated text."),
        case("NFR-07", "Release HTTPS-only",
             "In a release build, configure an http:// server.",
             "The insecure server is refused (http works only in debug builds)."),
    ],
)


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------
def e(text):
    return html.escape(str(text))


def render_case(row):
    return f"""<tr>
  <td class="id">{e(row['id'])}</td>
  <td class="title"><span class="tname">{e(row['title'])}</span><br><span class="steps">{e(row['steps'])}</span></td>
  <td class="expect">{e(row['expected'])}</td>
  <td class="result"><span class="box"></span> Pass &nbsp; <span class="box"></span> Fail</td>
  <td class="notes"></td>
</tr>"""


def render_section(sec):
    rows = "\n".join(render_case(c) for c in sec["cases"])
    return f"""<section class="sec">
<h2><span class="secnum">{e(sec['code'])}</span> {e(sec['title'])}</h2>
<p class="blurb">{e(sec['blurb'])}</p>
<table class="cases">
<thead>
<tr>
  <th class="id">ID</th>
  <th class="title">Test Case &amp; Steps</th>
  <th class="expect">Expected Result</th>
  <th class="result">Result</th>
  <th class="notes">Notes / Evidence</th>
</tr>
</thead>
<tbody>
{rows}
</tbody>
</table>
</section>"""


def build_html():
    total_cases = sum(len(s["cases"]) for s in SECTIONS)
    toc = "\n".join(
        f"<li><span class='toc-code'>{e(s['code'])}</span> {e(s['title'])} "
        f"<span class='toc-count'>{len(s['cases'])}</span></li>"
        for s in SECTIONS
    )
    sections = "\n".join(render_section(s) for s in SECTIONS)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{e(APP_NAME)} — UAT Testing Checklist</title>
<style>
  * {{ box-sizing: border-box; }}
  body {{ font-family: "DejaVu Sans", "Liberation Sans", Arial, sans-serif;
         color: #1c2333; font-size: 9.5px; line-height: 1.35; margin: 0; }}
  h1, h2, h3 {{ color: #14284b; margin: 0; }}
  .cover {{ border: 2px solid #14284b; border-radius: 6px; padding: 22px 26px;
            margin-bottom: 16px; background: #f5f8fd; }}
  .cover .kicker {{ letter-spacing: 2px; font-size: 9px; color: #285a9e; font-weight: bold;
                    text-transform: uppercase; }}
  .cover h1 {{ font-size: 24px; margin: 6px 0 2px; }}
  .cover .sub {{ font-size: 12px; color: #285a9e; font-weight: bold; }}
  .cover .meta {{ margin-top: 14px; font-size: 9.5px; color: #333; }}
  .cover .meta b {{ color: #14284b; }}
  .infogrid {{ width: 100%; border-collapse: collapse; margin-top: 14px; }}
  .infogrid td {{ border: 1px solid #c3d0e4; padding: 7px 9px; font-size: 9.5px;
                  background: #fff; width: 50%; }}
  .infogrid .lbl {{ color: #285a9e; font-weight: bold; font-size: 8.5px; display: block;
                    text-transform: uppercase; letter-spacing: .5px; margin-bottom: 8px; }}
  .summary {{ background: #fff; border: 1px solid #c3d0e4; border-left: 5px solid #285a9e;
              padding: 12px 16px; margin-bottom: 16px; }}
  .summary p {{ margin: 0 0 6px; }}
  .summary ul {{ margin: 4px 0 0 18px; padding: 0; }}
  .summary li {{ margin-bottom: 3px; }}
  .toc {{ background: #fff; border: 1px solid #c3d0e4; padding: 12px 16px; margin-bottom: 16px; }}
  .toc h3 {{ font-size: 12px; margin-bottom: 6px; }}
  .toc ul {{ list-style: none; margin: 0; padding: 0; columns: 2; column-gap: 26px; }}
  .toc li {{ padding: 2px 0; border-bottom: 1px dotted #d5ddea; }}
  .toc-code {{ display: inline-block; width: 16px; color: #285a9e; font-weight: bold; }}
  .toc-count {{ float: right; color: #777; }}
  .sec {{ page-break-inside: auto; margin-bottom: 14px; }}
  h2 {{ font-size: 13px; border-bottom: 2px solid #14284b; padding-bottom: 4px;
        margin: 14px 0 4px; page-break-after: avoid; }}
  .secnum {{ display: inline-block; background: #14284b; color: #fff; border-radius: 4px;
             padding: 1px 7px; margin-right: 6px; font-size: 11px; }}
  .blurb {{ color: #555; font-style: italic; margin: 0 0 6px; font-size: 9px; }}
  table.cases {{ width: 100%; border-collapse: collapse; }}
  table.cases th {{ background: #14284b; color: #fff; text-align: left; font-size: 8.5px;
                    padding: 4px 5px; border: 1px solid #14284b; }}
  table.cases td {{ border: 1px solid #c3d0e4; padding: 4px 5px; vertical-align: top; }}
  table.cases tr {{ page-break-inside: avoid; }}
  table.cases tbody tr:nth-child(even) td {{ background: #f7f9fc; }}
  td.id, th.id {{ width: 7%; font-weight: bold; color: #285a9e; white-space: nowrap; }}
  th.title, td.title {{ width: 31%; }}
  th.expect, td.expect {{ width: 30%; }}
  th.result, td.result {{ width: 13%; }}
  th.notes, td.notes {{ width: 19%; }}
  .tname {{ font-weight: bold; color: #1c2333; }}
  .steps {{ color: #556; font-size: 8.5px; }}
  .expect {{ color: #21402a; }}
  .box {{ display: inline-block; width: 9px; height: 9px; border: 1.4px solid #14284b;
          border-radius: 2px; vertical-align: -1px; }}
  .signoff {{ page-break-inside: avoid; border: 1px solid #c3d0e4; padding: 12px 16px;
              margin-top: 8px; }}
  .signoff h3 {{ font-size: 12px; margin-bottom: 8px; }}
  .defects {{ width: 100%; border-collapse: collapse; margin: 8px 0 14px; }}
  .defects th {{ background: #14284b; color: #fff; font-size: 8.5px; padding: 4px; border: 1px solid #14284b; }}
  .defects td {{ border: 1px solid #c3d0e4; padding: 9px 4px; }}
  .sigrow {{ width: 100%; border-collapse: collapse; margin-top: 10px; }}
  .sigrow td {{ padding: 20px 8px 4px; border-bottom: 1px solid #8fa4c4; font-size: 9px; color: #555; }}
  .footer-note {{ margin-top: 12px; font-size: 8px; color: #888; text-align: center; }}
  .legend span {{ display: inline-block; margin-right: 14px; }}
</style>
</head>
<body>

<div class="cover">
  <div class="kicker">User Acceptance Testing</div>
  <h1>{e(APP_NAME)}</h1>
  <div class="sub">UAT Test Checklist &mdash; Version {e(APP_VERSION)}</div>
  <div class="meta">Prepared for the Ministry of Health / HISP Ethiopia UAT session &middot; {e(BUILD_DATE)}</div>
  <table class="infogrid">
    <tr>
      <td><span class="lbl">Tester name</span>&nbsp;</td>
      <td><span class="lbl">Test date</span>&nbsp;</td>
    </tr>
    <tr>
      <td><span class="lbl">Device / OS</span>&nbsp;</td>
      <td><span class="lbl">Build / APK version</span>&nbsp;</td>
    </tr>
    <tr>
      <td><span class="lbl">DHIS2 server URL</span>&nbsp;</td>
      <td><span class="lbl">Test account / org unit</span>&nbsp;</td>
    </tr>
    <tr>
      <td><span class="lbl">Network conditions tested</span>&nbsp;</td>
      <td><span class="lbl">Total test cases ({total_cases})</span>&nbsp;</td>
    </tr>
  </table>
</div>

<div class="summary">
  <p><b>Purpose.</b> This checklist walks a tester through every user-facing feature of the
  {e(APP_NAME)}. Each row is a single test case with the steps to perform and the expected
  result. Mark <b>Pass</b> or <b>Fail</b>, and record the actual behaviour, screenshots or
  defect IDs in the Notes column.</p>
  <p><b>How to use it.</b></p>
  <ul>
    <li>Work top to bottom within each section; sections are independent, so you may split them across testers.</li>
    <li>A case passes only when the observed result matches the expected result in full.</li>
    <li>For any fail, capture a screenshot, note the exact on-screen text and log a defect ID.</li>
    <li>Re-test offline-first behaviour explicitly (airplane mode) &mdash; it is central to this app.</li>
    <li>Use a <b>staging/test</b> DHIS2 server and non-production accounts. Do not enter real patient data.</li>
  </ul>
  <p class="legend" style="margin-top:6px;"><b>Legend:</b>
    <span><span class="box"></span> Pass</span>
    <span><span class="box"></span> Fail</span>
    <span>N/A &mdash; note why in Notes</span>
  </p>
</div>

<div class="toc">
  <h3>Contents</h3>
  <ul>{toc}</ul>
</div>

{sections}

<div class="signoff">
  <h3>Defect Log</h3>
  <table class="defects">
    <thead>
      <tr>
        <th style="width:12%">Defect ID</th>
        <th style="width:14%">Test Case ID</th>
        <th style="width:36%">Description / Steps to reproduce</th>
        <th style="width:12%">Severity</th>
        <th style="width:26%">Screenshot / Attachment</th>
      </tr>
    </thead>
    <tbody>
      <tr><td>&nbsp;</td><td></td><td></td><td></td><td></td></tr>
      <tr><td>&nbsp;</td><td></td><td></td><td></td><td></td></tr>
      <tr><td>&nbsp;</td><td></td><td></td><td></td><td></td></tr>
      <tr><td>&nbsp;</td><td></td><td></td><td></td><td></td></tr>
      <tr><td>&nbsp;</td><td></td><td></td><td></td><td></td></tr>
      <tr><td>&nbsp;</td><td></td><td></td><td></td><td></td></tr>
    </tbody>
  </table>

  <h3 style="margin-top:14px;">Overall Result</h3>
  <p class="legend">
    <span><span class="box"></span> Accepted &mdash; ready to release</span>
    <span><span class="box"></span> Accepted with minor issues</span>
    <span><span class="box"></span> Rejected &mdash; must re-test</span>
  </p>
  <table class="sigrow">
    <tr>
      <td style="width:50%">Tester signature / name</td>
      <td style="width:50%">Date</td>
    </tr>
  </table>
  <table class="sigrow">
    <tr>
      <td style="width:50%">Development / QA representative</td>
      <td style="width:50%">Date</td>
    </tr>
  </table>
</div>

<p class="footer-note">{e(APP_NAME)} {e(APP_VERSION)} &mdash; generated {e(BUILD_DATE)} from the application's feature documentation.</p>

</body>
</html>
"""


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    html_text = build_html()
    with open(HTML_PATH, "w", encoding="utf-8") as fh:
        fh.write(html_text)
    print(f"Wrote {HTML_PATH}")

    wk = shutil.which("wkhtmltopdf")
    if not wk:
        print("wkhtmltopdf not found on PATH; HTML written but no PDF produced.",
              file=sys.stderr)
        return 1

    cmd = [
        wk,
        "--enable-local-file-access",
        "--page-size", "A4",
        "--orientation", "Portrait",
        "--margin-top", "14mm",
        "--margin-bottom", "14mm",
        "--margin-left", "11mm",
        "--margin-right", "11mm",
        "--header-left", f"{APP_NAME} - UAT Testing Checklist",
        "--header-right", APP_VERSION,
        "--header-font-size", "7",
        "--header-font-name", "DejaVu Sans",
        "--header-spacing", "5",
        "--footer-center", "Page [page] of [topage]",
        "--footer-font-size", "7",
        "--footer-font-name", "DejaVu Sans",
        "--footer-spacing", "4",
        "--quiet",
        HTML_PATH,
        PDF_PATH,
    ]
    subprocess.run(cmd, check=True)
    print(f"Wrote {PDF_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
