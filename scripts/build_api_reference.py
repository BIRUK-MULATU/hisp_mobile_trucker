#!/usr/bin/env python3
"""Builds RDHIS2_Mobile_API_Reference.{docx,pdf} — every DHIS2 Web API endpoint
the app calls, the method rules, and the exact request shape per call site.

    pip install --break-system-packages python-docx
    python3 scripts/build_api_reference.py

Keep in step with docs/19-api-reference.md (that file is the source of truth).
"""
import datetime as dt
import os
import shutil
import subprocess

from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.section import WD_ORIENT
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

BUILD_DATE = dt.date.today()
LONG_DATE = BUILD_DATE.strftime('%d %B %Y')

NAVY = RGBColor(0x1E, 0x28, 0x44)
ACCENT = RGBColor(0x28, 0x5A, 0x9E)
GREY = RGBColor(0x55, 0x55, 0x55)
GET_G = RGBColor(0x1B, 0x6B, 0x3A)
WRITE_R = RGBColor(0xA8, 0x2A, 0x2A)

doc = Document()

sec = doc.sections[0]
sec.orientation = WD_ORIENT.LANDSCAPE
sec.page_width, sec.page_height = sec.page_height, sec.page_width
sec.left_margin = sec.right_margin = Inches(0.7)
sec.top_margin = sec.bottom_margin = Inches(0.7)
USABLE = 10.0  # inches between margins (letter landscape)

styles = doc.styles
normal = styles['Normal']
normal.font.name = 'Calibri'
normal.font.size = Pt(10)
normal.paragraph_format.space_after = Pt(6)
normal.paragraph_format.line_spacing = 1.06

for lvl, sz in [(1, 16), (2, 12.5), (3, 11)]:
    st = styles[f'Heading {lvl}']
    st.font.name = 'Calibri'
    st.font.size = Pt(sz)
    st.font.color.rgb = NAVY if lvl < 3 else ACCENT
    st.font.bold = True
    st.paragraph_format.space_before = Pt(12 if lvl == 1 else 9)
    st.paragraph_format.space_after = Pt(4)
    st.paragraph_format.keep_with_next = True


def _bg(cell, hexcolor):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:fill'), hexcolor)
    tcPr.append(shd)


def para(text="", *, bold=False, italic=False, size=None, color=None, align=None):
    p = doc.add_paragraph()
    if align is not None:
        p.alignment = align
    if text:
        r = p.add_run(text)
        r.bold = bold
        r.italic = italic
        if size:
            r.font.size = Pt(size)
        if color:
            r.font.color.rgb = color
    return p


def h1(t): doc.add_heading(t, level=1)
def h2(t): doc.add_heading(t, level=2)
def h3(t): doc.add_heading(t, level=3)


def bullet(text):
    p = doc.add_paragraph(style='List Bullet')
    p.add_run(text)
    p.paragraph_format.space_after = Pt(2)
    return p


def code_block(text):
    p = doc.add_paragraph()
    p.paragraph_format.left_indent = Inches(0.15)
    p.paragraph_format.space_after = Pt(8)
    r = p.add_run(text)
    r.font.name = 'Consolas'
    r.font.size = Pt(8.5)
    r.font.color.rgb = GREY
    return p


def _mono_runs(cell, text):
    """Render a cell, styling `backtick` spans and METHOD tokens."""
    cell.text = ''
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0)
    parts = text.split('`')
    for i, chunk in enumerate(parts):
        if not chunk:
            continue
        r = p.add_run(chunk)
        r.font.size = Pt(8)
        if i % 2 == 1:
            r.font.name = 'Consolas'
            r.font.size = Pt(8)
        if chunk in ('GET', 'POST', 'DELETE', 'PUT', 'PATCH'):
            r.bold = True
            r.font.color.rgb = GET_G if chunk == 'GET' else WRITE_R


def table(headers, rows, widths):
    t = doc.add_table(rows=1, cols=len(headers))
    t.style = 'Light Grid Accent 1'
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.autofit = False
    hdr = t.rows[0].cells
    for i, htext in enumerate(headers):
        hdr[i].text = ''
        run = hdr[i].paragraphs[0].add_run(htext)
        run.bold = True
        run.font.size = Pt(8.5)
        run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        _bg(hdr[i], '1E2844')
    for row in rows:
        cells = t.add_row().cells
        for i, val in enumerate(row):
            _mono_runs(cells[i], str(val))
    for i, w in enumerate(widths):
        for row in t.rows:
            row.cells[i].width = Inches(w)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)
    return t


# ===========================================================================
# TITLE
# ===========================================================================
for _ in range(3):
    doc.add_paragraph()
para("RDHIS2 Mobile", bold=True, size=30, color=NAVY, align=WD_ALIGN_PARAGRAPH.CENTER)
para("DHIS2 Web API Reference", size=18, color=ACCENT, align=WD_ALIGN_PARAGRAPH.CENTER)
para("Every endpoint the application calls · method rules · exact request shape per call site",
    italic=True, size=10, color=GREY, align=WD_ALIGN_PARAGRAPH.CENTER)
doc.add_paragraph()
para("HISP Ethiopia — Mobile team", size=10, align=WD_ALIGN_PARAGRAPH.CENTER)
para(f"Document version 1.0  ·  {LONG_DATE}  ·  verified against the source at the current head",
    size=9, color=GREY, align=WD_ALIGN_PARAGRAPH.CENTER)
para("Companion to docs/19-api-reference.md (source of truth) and the RDHIS2 Mobile "
     "Technical Documentation.", size=9, color=GREY, align=WD_ALIGN_PARAGRAPH.CENTER)
doc.add_page_break()

# ===========================================================================
# 1  CONVENTIONS
# ===========================================================================
h1("1  Conventions")
para("If an endpoint is not in this document, the app does not call it.", italic=True)
table(["Aspect", "Value"],
      [["Base URL", "`{server}/api` — compiled default `https://hmis-staging.moh.gov.et/api` "
        "(ApiConstants.baseUrl). Runtime-overridable from the login screen or Settings; "
        "normalised to https:// + /api."],
       ["Authentication", "HTTP Basic on every request — `Authorization: Basic "
        "base64(username:password)`. Built in one place (AuthInterceptor.buildBasicToken). "
        "No tokens, no OAuth."],
       ["Default headers", "`Content-Type: application/json`, `Accept: application/json`. "
        "The connectivity probe additionally sends `X-Requested-With: XMLHttpRequest`."],
       ["Timeouts", "30 s each for connect / receive / send."],
       ["Response decoding", "Large JSON bodies decoded on a background isolate (Dio "
        "BackgroundTransformer) so the UI never freezes during a metadata sync."],
       ["Paging", "Every metadata list request sends `paging=false` — whole (scoped) "
        "collections, never pages."],
       ["Field selection", "Every request sends a DHIS2 `fields=` selector; the app never "
        "fetches `*`."],
       ["Server-side filtering", "`filter=` clauses; more than one is OR-combined with "
        "`rootJunction=OR`."]],
      widths=[1.7, 8.3])

h2("1.1  The two HTTP clients")
table(["Client", "Interceptors", "Used for"],
      [["`ApiClient()` (singleton)", "AuthInterceptor → LoggingInterceptor. A 401 anywhere "
        "ends the session and redirects to /login?reason=session-expired.",
        "Metadata sync, form value pull/push, capture browse, dashboards / analytics, "
        "audits, icons."],
       ["`ApiClient.withBasicAuth(...)`", "None — a fixed Authorization header, no plugins. "
        "A 401 here never ends the session.",
        "The login credential probe, the per-session sync client on AppSession.instance.api, "
        "the connectivity probe, and tests."]],
      widths=[2.3, 3.9, 3.8])
doc.add_page_break()

# ===========================================================================
# 2  METHOD RULES
# ===========================================================================
h1("2  Method Rules")
para("The app is read-mostly. It issues GET for everything except three write calls.")
table(["Method", "Where the app uses it", "Rules"],
      [["GET", "All metadata, all reads, login, ping, analytics, audits, icons.",
        "Never mutates server state. Every GET at a feature boundary is best-effort: on "
        "failure the caller falls back to the local database or a cache and the UI is never "
        "blocked. Metadata GETs always carry `fields=` + `paging=false`."],
       ["POST", "`/api/dataValueSets.json` (bulk data value import) and "
        "`/api/completeDataSetRegistrations` (mark a form complete).",
        "Both idempotent by composite key — re-sending the same values / registration is "
        "safe, which is what makes the offline retry loop correct. Data import uses "
        "`importStrategy=CREATE_AND_UPDATE` + `atomicMode=NONE` (see §5)."],
       ["DELETE", "`/api/completeDataSetRegistrations` (re-open a completed form).",
        "Addressed by query params (`ds`, `pe`, `ou`), plus `cc` / `cp` for a non-default "
        "attribute option combo — the default combo sends neither. A 409 here is treated "
        "as permanent (row marked error, not retried)."],
       ["PUT / PATCH", "Never. The app issues no PUT or PATCH request anywhere.",
        "Updates to an existing data value go through the same "
        "`POST /api/dataValueSets.json` — DHIS2's dataValueSets import is an upsert, so a "
        "separate update verb is unnecessary and would complicate the single-push-path "
        "offline model."]],
      widths=[1.1, 3.6, 5.3])
para("The app never creates or edits server-side metadata, users, visualizations, "
     "dashboards, option sets, or organisation units. Metadata “deletes” during a "
     "delta sync are local database deletes only, never an API call.", italic=True)
doc.add_page_break()

# ===========================================================================
# 3  ENDPOINT CATALOGUE
# ===========================================================================
h1("3  Endpoint Catalogue")

CAT_W = [0.75, 2.5, 3.2, 2.35, 1.2]

h2("3.1  Authentication & session")
table(["Method", "Endpoint", "Purpose", "Key parameters", "Caller"],
      [["GET", "`/api/me.json`", "Validate credentials on online login; capture the Date "
        "response header to anchor the tamper-resistant clock.", "`fields=id`",
        "SessionService._serverAccepts"],
       ["GET", "`/api/me.json`", "Cache the user row for offline login and read the "
        "capture-root org units (id, level) that scope the org-unit sync.",
        "`fields=id,username,displayName,organisationUnits[id,level]`",
        "MetadataSyncService._fetchUserCaptureRoots"],
       ["GET", "`/me`", "Transitional legacy glue: after an online login, cache the Basic "
        "token + full /me payload some older SecureStorage-reading code still expects.",
        "`fields=id,username,firstName,surname,email,phoneNumber,avatar,authorities,"
        "organisationUnits[id,displayName,shortName,code,level,path]`; validateStatus < 500",
        "AuthRemoteDataSourceImpl.login"],
       ["GET", "`/api/system/ping`", "App-wide connectivity ground truth — probed every "
        "30 s, on every OS connectivity event, and on checkNow().", "none (bare client)",
        "ConnectivityService.checkNow"]],
      widths=CAT_W)
para("Rules: 401 on the first row → invalidCredentials. Any other error on the first two "
     "rows → the caller falls back to the offline verifier path / retries next login. For "
     "the ping, any HTTP response (incl. 401) counts as online; only a transport error is "
     "offline.", size=9, color=GREY)

h2("3.2  Metadata synchronization")
para("All metadata GETs go through MetadataResource and share three shapes:")
table(["Method", "Endpoint", "Purpose", "Parameters"],
      [["GET", "`/api/{resource}.json`", "Full sync — every object of a resource.",
        "`fields=<selector>`, `paging=false` [, `filter=<clauses>`, `rootJunction=OR` when >1]"],
       ["GET", "`/api/{resource}.json`", "Delta sync, step 1 — cheap change list.",
        "`fields=id,lastUpdated`, `paging=false` [, filter…]"],
       ["GET", "`/api/{resource}.json`", "Delta sync, step 2 — only changed/new objects, "
        "chunked at 100 ids/request.", "`fields=<selector>`, `filter=id:in:[…]`, `paging=false`"]],
      widths=[0.75, 2.4, 3.6, 3.25])

h3("Resources, in dependency order, with the exact fields selector")
table(["#", "resource", "fields selector", "Notes"],
      [["1", "`categoryOptions`", "`id,name,displayName,shortName,startDate,endDate,lastUpdated`", ""],
       ["2", "`categories`", "`id,name,displayName,dataDimensionType,categoryOptions[id],lastUpdated`", ""],
       ["3", "`categoryCombos`", "`id,name,displayName,dataDimensionType,skipTotal,categories[id],lastUpdated`", ""],
       ["4", "`categoryOptionCombos`", "`id,name,categoryCombo[id],categoryOptions[id],lastUpdated`", ""],
       ["5", "`optionSets`", "`id,name,displayName,valueType,lastUpdated,attributeValues[value,attribute[id]]`", ""],
       ["6", "`options`", "`id,code,name,displayName,sortOrder,optionSet[id],lastUpdated`", ""],
       ["7", "`attributes`", "`id,name,displayName,valueType`",
        "No lastUpdated → delta falls back to a full syncAll."],
       ["8", "`dataElements`", "`id,name,displayName,formName,description,valueType,"
        "categoryCombo[id],optionSet[id],lastUpdated,attributeValues[value,attribute[id]]`", ""],
       ["9", "`indicators`", "`id,name,displayName,numerator,denominator,description,"
        "annualized,indicatorType[factor],lastUpdated,attributeValues[…]`", ""],
       ["10", "`dataElementGroups`", "`id,name,displayName,dataElements[id],lastUpdated,attributeValues[…]`", ""],
       ["11", "`organisationUnits`", "`id,name,displayName,parent[id,name],path,code,"
        "openingDate,closedDate,lastUpdated`",
        "Scoped: `filter=path:like:<captureRootUid>` per root, OR-combined. Depth bounded "
        "to root + direct children client-side after the fetch (OrgUnitResource.isValid)."],
       ["12", "`dataSets`", "`id,name,displayName,periodType,version,openFuturePeriods,"
        "expiryDays,lastUpdated,categoryCombo[id],attributeValues[…],"
        "dataSetElements[sortOrder,compulsory,categoryCombo[id],"
        "dataElement[id,categoryCombo[id]]],"
        "compulsoryDataElementOperands[dataElement[id],categoryOptionCombo[id]],"
        "organisationUnits[id]`", ""],
       ["13", "`sections`", "`id,name,displayName,sortOrder,lastUpdated,dataSet[id],"
        "dataElements[id],indicators[id],"
        "greyedFields[dataElement[id],categoryOptionCombo[id]]`", ""],
       ["14", "`validationRules`", "`id,name,displayName,description,importance,operator,"
        "instruction,periodType,lastUpdated,"
        "leftSide[expression,description,missingValueStrategy],rightSide[…]`", ""]],
      widths=[0.35, 1.7, 6.3, 1.65])
para("One targeted metadata GET outside the resource loop:")
table(["Method", "Endpoint", "Purpose", "Parameters", "Caller"],
      [["GET", "`/api/categoryCombos.json`", "Resolve the canonical default category combo "
        "+ its unique COC on an instance that has duplicated the default COC.",
        "`filter=name:eq:default`, `fields=id,name,displayName,categoryOptionCombos[id,name]`",
        "fetchCanonicalDefaultCombo"]],
      widths=CAT_W)

h2("3.3  Data capture — value pull & push")
table(["Method", "Endpoint", "Purpose", "Key parameters", "Caller"],
      [["GET", "`/api/dataValueSets.json`", "On form open (online): pull the server's "
        "current values for one dataset/period/org unit, for per-cell conflict resolution.",
        "`dataSet`, `period`, `orgUnit`", "DataValueSync._pullAndResolve"],
       ["GET", "`/api/dataValueSets.json`", "Build the outlier-detection history snapshot "
        "— ~25 months of this dataset's values at this org unit.",
        "`dataSet`, `orgUnit`, `startDate`, `endDate` (~770 days)",
        "OutlierDetectionService.fetchHistory"],
       ["POST", "`/api/dataValueSets.json`", "Push queued (pending) data values. Bulk "
        "import, ≤ 500 values/request, chunked recursively.",
        "body `{dataValues:[{dataElement,period,orgUnit,categoryOptionCombo,"
        "attributeOptionCombo,value,comment?,deleted?}]}`; query "
        "`importStrategy=CREATE_AND_UPDATE`, `atomicMode=NONE`",
        "pushDataValueBatch"]],
      widths=CAT_W)
para("On failure: the pull returns null (local data stands); the outlier fetch falls back "
     "to the cached snapshot; the push — on a transport failure — leaves every value "
     "pending for the next retry (a 409 is a verdict, not a failure — see §5).",
     size=9, color=GREY)
h3("Payload entry rules (_payloadEntry)")
bullet("`value` is always trimmed before sending.")
bullet("A cleared cell (no value and no comment) is sent as `\"deleted\": true` — not "
       "`\"value\": \"\"`, which DHIS2 rejects with E7610. A deleted entry removes the "
       "server value if present and is silently ignored if it never existed.")
bullet("`comment` is included only when non-null.")
bullet("Routine datasets use the dataset instance's default attributeOptionCombo; Disease "
       "Registration datasets thread the picked combo through.")

h2("3.4  Completion registrations")
table(["Method", "Endpoint", "Purpose", "Key parameters", "Caller"],
      [["POST", "`/api/completeDataSetRegistrations`", "Mark a form complete. One call per "
        "pending registration.",
        "body `{completeDataSetRegistrations:[{dataSet,period,organisationUnit,"
        "attributeOptionCombo}]}`", "CompletenessSync.pushPending"],
       ["DELETE", "`/api/completeDataSetRegistrations`", "Re-open a completed form "
        "(un-complete).",
        "`ds`, `pe`, `ou` [, `cc`, `cp` for a non-default attributeOptionCombo — the "
        "default combo sends neither]", "CompletenessSync.pushPending (completed==false)"],
       ["GET", "`/api/completeDataSetRegistrations.json`", "Pull the server's completion "
        "state so a report finished on the web drops out of the “To-do” list. "
        "Org units fanned out ≤ 40/request.",
        "`orgUnit` (list), `startDate`, `endDate`, "
        "`fields=dataSet,period,organisationUnit,attributeOptionCombo,completed,date`",
        "CompletenessSync.pullRecent"]],
      widths=CAT_W)
para("On failure: POST/DELETE — a 409 marks the row error with the server's reason "
     "(permanent, not retried); any other DioException leaves it pending. GET pullRecent "
     "is best-effort; the local view is left as-is.", size=9, color=GREY)

h2("3.5  Audit trail")
table(["Method", "Endpoint", "Purpose", "Key parameters", "Caller"],
      [["GET", "`/api/audits/dataValue.json`", "DHIS2's own server-side audit trail for "
        "one cell — the “Show history” query.",
        "`de`, `pe`, `ou` [, `cc`, `cp`], `pageSize` (default 50)",
        "ServerAuditService.fetchForCell"]],
      widths=CAT_W)
para("On failure: returns null; the history sheet shows only the local AuditLogStore "
     "trail. Server-side auditing must be enabled for any rows to exist — an empty result "
     "does not prove nothing changed.", size=9, color=GREY)

h2("3.6  Organisation-unit browse (Capture)")
para("These supplement, never replace, the locally-synced depth-bounded tree.")
table(["Method", "Endpoint", "Purpose", "Key parameters", "Caller"],
      [["GET", "`/api/organisationUnits.json`", "Live children of one node (browse below "
        "the offline depth bound). Not persisted.",
        "`filter=parent.id:eq:<id>`, `fields=id,displayName,path,children[id]`, `paging=false`",
        "CaptureRepositoryImpl._fetchChildrenLive"],
       ["GET", "`/api/organisationUnits.json`", "Batched “which of these have "
        "children” check — one request for the expand-arrow decision.",
        "`filter=parent.id:in:[…]`, `fields=parent[id]`, `paging=false`",
        "CaptureRepositoryImpl._liveChildrenExistence"],
       ["GET", "`/api/organisationUnits/{id}.json`", "On visiting an org unit: fetch it + "
        "its assigned dataset ids, mirror the org unit and its dataset links locally "
        "(links replaced, not merged).",
        "`fields=id,name,displayName,parent[id,name],path,code,openingDate,closedDate,"
        "lastUpdated,dataSets[id]`",
        "CaptureRepositoryImpl._fetchAndCacheVisitedOrgUnit"]],
      widths=CAT_W)

h2("3.7  Data-entry form metadata")
table(["Method", "Endpoint", "Purpose", "Key parameters", "Caller"],
      [["GET", "`/api/dataSets/{id}.json`", "Resolve a dataset's categoryCombo + its COCs "
        "when missing from the local cache; persist both.",
        "`fields=categoryCombo[id,name,displayName,categoryOptionCombos[id,name]]`",
        "DataEntryRepositoryImpl._fetchDefaultComboFromDataSet"]],
      widths=CAT_W)

h2("3.8  Visualization — server dashboards (read-only)")
para("Nothing here is written to the local database; only the last analytics answer is "
     "cached (under a SyncInfoTable key) so a chart stays viewable offline.")
table(["Method", "Endpoint", "Purpose", "Key parameters", "Caller"],
      [["GET", "`/api/dashboards.json`", "List server dashboards.",
        "`fields=id,name`, `paging=false`", "ChartRepositoryImpl.getDashboards"],
       ["GET", "`/api/dashboards/{id}.json`", "The visualization items on one dashboard "
        "(MAP / APP items skipped).",
        "`fields=dashboardItems[type,visualization[id,name,type]]`",
        "ChartRepositoryImpl.getDashboardVisualizations"],
       ["GET", "`/api/visualizations.json`", "Flat reference list of visualizations the "
        "user can see.", "`fields=id,name,type`, `paging=false`",
        "ChartRepositoryImpl.getServerVisualizations"],
       ["GET", "`/api/visualizations/{id}.json`", "One visualization's own definition — "
        "its column / row / filter dimensions and items.",
        "`fields=id,name,type,columns[dimension,items[id,displayName]],rows[…],filters[…]`",
        "ChartRepositoryImpl.runServerVisualization"],
       ["GET", "`/api/analytics.json`", "Run a server visualization's own query. "
        "columns+rows → dimension=; filters → filter=.",
        "`dimension` (repeated), `filter` (repeated), `includeMetadataDetails=false`",
        "ChartRepositoryImpl.runServerVisualization"]],
      widths=CAT_W)

h2("3.9  Visualization — local dashboards & the chart builder")
para("Builder pickers prefer the live server and fall back to locally-synced metadata (or, "
     "for org units, the depth-bounded local tree) when offline.")
table(["Method", "Endpoint", "Purpose", "Key parameters", "Caller"],
      [["GET", "`/api/indicatorGroups.json`", "Indicator-group picker.",
        "`fields=id,displayName`, `paging=false`", "getIndicatorGroups"],
       ["GET", "`/api/indicatorGroups/{id}.json`", "Indicators within a group (indicator "
        "groups aren't synced offline — falls back to a flat local indicator list).",
        "`fields=indicators[id,displayName]`", "getIndicatorsInGroup"],
       ["GET", "`/api/dataElementGroups.json`", "Data-element-group picker.",
        "`fields=id,displayName`, `paging=false`", "getDataElementGroups"],
       ["GET", "`/api/dataElementGroups/{id}.json`", "Aggregatable data elements of a "
        "group, each with its COCs.",
        "`fields=dataElements[id,displayName,domainType,"
        "categoryCombo[categoryOptionCombos[id,displayName]]]`", "getDataElementsInGroup"],
       ["GET", "`/api/dataSets.json`", "Dataset picker.",
        "`fields=id,displayName`, `paging=false`", "getDataSets"],
       ["GET", "`/api/organisationUnits.json`", "Live org-unit children for the builder's "
        "picker — deliberately the full hierarchy, never cached.",
        "`filter=parent.id:eq:<id>`, `fields=id,displayName,path,level,children[id]`, "
        "`paging=false`", "getOrgUnitChildrenLive"],
       ["GET", "`/api/analytics.json`", "Run one saved local chart.",
        "`dimension=dx:<items>;pe:<period>` (repeated), `filter=ou:<orgUnit>`, "
        "`includeMetadataDetails=false`", "LocalVisualizationRepositoryImpl.runChart"]],
      widths=CAT_W)
para("Local chart configurations and their cached results are stored on the device only "
     "(JSON under savedCharts / chartCache_<id> keys in SyncInfoTable) — no server object "
     "is ever created or updated.", size=9, color=GREY)

h2("3.10  Assets")
table(["Method", "Endpoint", "Purpose", "Notes", "Caller"],
      [["GET", "`/api/icons/{iconKey}/icon.svg`", "The DHIS2 icon for a dataset card.",
        "responseType: bytes; one fetch per key per run (in-memory cache); a failure just "
        "shows the fallback icon.", "DataSetIcon._fetch"]],
      widths=CAT_W)
doc.add_page_break()

# ===========================================================================
# 4  DELTA SYNC
# ===========================================================================
h1("4  Delta-Sync Algorithm (per resource)")
doc.add_paragraph(style='List Number').add_run(
    "GET /api/{resource}.json?fields=id,lastUpdated&paging=false (+ scope filter).")
doc.add_paragraph(style='List Number').add_run(
    "Compare each (id, lastUpdated) against the local row (1-second tolerance — Drift "
    "stores DateTime at second precision, the server sends milliseconds).")
doc.add_paragraph(style='List Number').add_run(
    "GET …&filter=id:in:[…]&fields=<full selector> for the changed/new ids, chunked at "
    "100 ids per request (long id:in URLs break on proxies).")
doc.add_paragraph(style='List Number').add_run(
    "Delete locally any id the server's list no longer contains — a local delete, no API "
    "call.")
doc.add_paragraph(style='List Number').add_run(
    "Resources with no lastUpdated column (attributes) cannot delta — they fall back to a "
    "full syncAll.")
para("A network drop mid-sequence leaves earlier resources fully synced and later ones "
     "untouched: stale but internally consistent, never half-written. lastMetadataSync is "
     "written only after a full pass completes.")

# ===========================================================================
# 5  VERDICT PARSING
# ===========================================================================
h1("5  Data-Push Verdict Parsing (POST /api/dataValueSets.json)")
table(["Server response", "Meaning", "App action"],
      [["HTTP 200, no conflicts, no ignored", "Whole batch accepted.",
        "Every value in the batch → synced."],
       ["HTTP 200 or 409 with an ImportSummary body", "Partial: atomicMode=NONE judges "
        "each value individually. Each conflict's indexes (or top-level rejectedIndexes) "
        "maps back to the exact payload position.",
        "Rejected values → error + the server's message; all others → synced."],
       ["HTTP 409 on an older server with no index info", "Conflicts present but not "
        "located.", "Best-effort substring match of the conflict text against each value's "
        "dataElementUid / period."],
       ["No parseable ImportSummary (true transport failure)", "The request never reached "
        "the server, or the body is unusable.",
        "Nothing is marked. Every value stays pending for the next retry."]],
      widths=[2.9, 3.6, 3.5])
para("Batching: _maxBatchSize = 500 values per request, chunked recursively — a "
     "mid-transfer drop only loses the unsent slice. Completion-registration verdicts "
     "follow the same “a 409 is a verdict, a transport error is not” rule, but "
     "a 409 there is permanent (retrying an already-rejected registration cannot succeed).")
doc.add_page_break()

# ===========================================================================
# 6  SUMMARY
# ===========================================================================
h1("6  Summary — one line per endpoint")
table(["Method", "Endpoint", "Read / Write", "Retriable"],
      [["GET", "`/api/me.json`", "read", "yes"],
       ["GET", "`/me`", "read", "yes"],
       ["GET", "`/api/system/ping`", "read", "yes"],
       ["GET", "`/api/{resource}.json` (14 metadata resources)", "read", "yes"],
       ["GET", "`/api/categoryCombos.json?filter=name:eq:default`", "read", "yes"],
       ["GET", "`/api/dataValueSets.json`", "read", "yes"],
       ["POST", "`/api/dataValueSets.json`", "write (upsert)", "yes — idempotent by key"],
       ["POST", "`/api/completeDataSetRegistrations`", "write", "yes — idempotent by key"],
       ["DELETE", "`/api/completeDataSetRegistrations`", "write", "yes — but 409 is permanent"],
       ["GET", "`/api/completeDataSetRegistrations.json`", "read", "yes"],
       ["GET", "`/api/audits/dataValue.json`", "read", "yes"],
       ["GET", "`/api/organisationUnits.json`", "read", "yes"],
       ["GET", "`/api/organisationUnits/{id}.json`", "read", "yes"],
       ["GET", "`/api/dataSets/{id}.json`", "read", "yes"],
       ["GET", "`/api/dataSets.json`", "read", "yes"],
       ["GET", "`/api/dashboards.json`", "read", "yes"],
       ["GET", "`/api/dashboards/{id}.json`", "read", "yes"],
       ["GET", "`/api/visualizations.json`", "read", "yes"],
       ["GET", "`/api/visualizations/{id}.json`", "read", "yes"],
       ["GET", "`/api/analytics.json`", "read", "yes"],
       ["GET", "`/api/indicatorGroups.json`", "read", "yes"],
       ["GET", "`/api/indicatorGroups/{id}.json`", "read", "yes"],
       ["GET", "`/api/dataElementGroups.json`", "read", "yes"],
       ["GET", "`/api/dataElementGroups/{id}.json`", "read", "yes"],
       ["GET", "`/api/icons/{iconKey}/icon.svg`", "read", "yes"]],
      widths=[1.0, 5.4, 2.0, 1.6])
para("No PUT. No PATCH. Three write calls, all idempotent, all on the same offline retry "
     "queue.", bold=True)

hr = doc.add_paragraph()
pPr = hr._p.get_or_add_pPr()
bdr = OxmlElement('w:pBdr'); b = OxmlElement('w:bottom')
b.set(qn('w:val'), 'single'); b.set(qn('w:sz'), '6'); b.set(qn('w:color'), 'BBBBBB')
bdr.append(b); pPr.append(bdr)
para(f"Prepared from the repository at the current head, {LONG_DATE}. Verify any "
     "consequential claim against the file cited.", italic=True, size=8.5, color=GREY)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out_dir = os.path.join(REPO, 'technical_documentation')
os.makedirs(out_dir, exist_ok=True)
out = os.path.join(out_dir, 'RDHIS2_Mobile_API_Reference.docx')
doc.save(out)
print("saved", out)

soffice = shutil.which('soffice') or shutil.which('libreoffice')
if soffice:
    subprocess.run([soffice, '--headless', '--convert-to', 'pdf',
                    '--outdir', out_dir, out], check=False)
    print("saved", out.replace('.docx', '.pdf'))
else:
    print("libreoffice not found — skipping PDF conversion")
