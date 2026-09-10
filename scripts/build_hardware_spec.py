#!/usr/bin/env python3
"""Builds RDHIS2_Mobile_Hardware_Specification.{docx,pdf} — the device
requirements to run the app in the field, with rationale, a storage-growth
model, and procurement guidance.

    pip install --break-system-packages python-docx
    python3 scripts/build_hardware_spec.py

Keep in step with docs/20-hardware-and-deployment.md (source of truth).
"""
import datetime as dt
import os
import re
import shutil
import subprocess

from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

BUILD_DATE = dt.date.today()
LONG_DATE = BUILD_DATE.strftime('%d %B %Y')

NAVY = RGBColor(0x1E, 0x28, 0x44)
ACCENT = RGBColor(0x28, 0x5A, 0x9E)
GREY = RGBColor(0x55, 0x55, 0x55)

doc = Document()
sec = doc.sections[0]
sec.left_margin = sec.right_margin = Inches(0.85)
sec.top_margin = sec.bottom_margin = Inches(0.8)

styles = doc.styles
normal = styles['Normal']
normal.font.name = 'Calibri'
normal.font.size = Pt(10.5)
normal.paragraph_format.space_after = Pt(6)
normal.paragraph_format.line_spacing = 1.08

for lvl, sz, col in [(1, 17, NAVY), (2, 13, NAVY), (3, 11.5, ACCENT)]:
    st = styles[f'Heading {lvl}']
    st.font.name = 'Calibri'
    st.font.size = Pt(sz)
    st.font.color.rgb = col
    st.font.bold = True
    st.paragraph_format.space_before = Pt(13 if lvl == 1 else 9)
    st.paragraph_format.space_after = Pt(5)
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
    p.paragraph_format.space_after = Pt(3)
    return p


def numbered(text):
    p = doc.add_paragraph(style='List Number')
    p.add_run(text)
    p.paragraph_format.space_after = Pt(3)
    return p


_TOKEN = re.compile(r'(\*\*.+?\*\*|`[^`]+`)')


def _emit(p, text):
    for tok in _TOKEN.split(str(text)):
        if not tok:
            continue
        if tok.startswith('**') and tok.endswith('**'):
            r = p.add_run(tok[2:-2])
            r.bold = True
            r.font.size = Pt(9)
        elif tok.startswith('`') and tok.endswith('`'):
            r = p.add_run(tok[1:-1])
            r.font.name = 'Consolas'
            r.font.size = Pt(8.5)
        else:
            r = p.add_run(tok)
            r.font.size = Pt(9)


def _cell(cell, text):
    cell.text = ''
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0)
    _emit(p, text)


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
        run.font.size = Pt(9)
        run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        _bg(hdr[i], '1E2844')
    for row in rows:
        cells = t.add_row().cells
        for i, val in enumerate(row):
            _cell(cells[i], val)
    for i, w in enumerate(widths):
        for row in t.rows:
            row.cells[i].width = Inches(w)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)
    return t


def note(text):
    p = doc.add_paragraph()
    p.paragraph_format.left_indent = Inches(0.15)
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(8)
    r = p.add_run(text)
    r.italic = True
    r.font.size = Pt(9.5)
    r.font.color.rgb = GREY


# ===========================================================================
# TITLE
# ===========================================================================
for _ in range(5):
    doc.add_paragraph()
para("RDHIS2 Mobile", bold=True, size=32, color=NAVY, align=WD_ALIGN_PARAGRAPH.CENTER)
para("Hardware Specification &", size=19, color=ACCENT, align=WD_ALIGN_PARAGRAPH.CENTER)
para("Deployment Requirements", size=19, color=ACCENT, align=WD_ALIGN_PARAGRAPH.CENTER)
doc.add_paragraph()
para("Device requirements for field deployment · rationale · storage-growth model · "
     "procurement guidance", italic=True, size=10.5, color=GREY,
     align=WD_ALIGN_PARAGRAPH.CENTER)
for _ in range(2):
    doc.add_paragraph()
para("HISP Ethiopia — Mobile team", size=10.5, align=WD_ALIGN_PARAGRAPH.CENTER)
para(f"Document version 1.0  ·  {LONG_DATE}", size=9.5, color=GREY,
     align=WD_ALIGN_PARAGRAPH.CENTER)
para("Build figures read from the app configuration; sizing figures marked (estimate) are "
     "for a national-scale DHIS2 instance.", size=9, color=GREY,
     align=WD_ALIGN_PARAGRAPH.CENTER)
doc.add_page_break()

# ===========================================================================
# 1  AT A GLANCE
# ===========================================================================
h1("1  At a Glance")
table(["", "Minimum", "Recommended"],
      [["Android OS", "7.0 (API 24, Nougat)", "11 (API 30) or newer"],
       ["Architecture", "32-bit ARM (armeabi-v7a)", "64-bit ARM (arm64-v8a)"],
       ["RAM", "2 GB", "3–4 GB"],
       ["Free storage at install", "1 GB", "4 GB+ (device ≥ 32 GB)"],
       ["Display", "5.0″, 720 × 1280 (HD)", "6″+ phone, or 8–10″ tablet, 1080 × 1920"],
       ["Battery", "2500 mAh", "3500 mAh+"],
       ["Connectivity", "Any 3G / Wi-Fi, intermittent", "4G / LTE or Wi-Fi for the first sync"],
       ["iOS (alternative)", "iOS 13.0 — iPhone 6s / iPad (5th gen)",
        "iOS 15+ — iPhone 11 / iPad (8th gen)"],
       ["Sensors / peripherals", "None required", "—"]],
      widths=[1.9, 2.5, 2.5])
para("The app is portrait-only and does not use the camera, GPS, fingerprint reader, NFC, "
     "Bluetooth, SD card, or a SIM / cellular connection for daily work (see §6).",
     italic=True)

# ===========================================================================
# 2  ANDROID
# ===========================================================================
h1("2  Android — Detailed")

h2("2.1  Operating system")
table(["Item", "Value", "Source / rationale"],
      [["minSdkVersion", "**24** — Android 7.0 (Nougat)",
        "Resolved from flutter.minSdkVersion (Flutter 3.41.4). The app will not install "
        "below this."],
       ["targetSdkVersion", "**36** — Android 16",
        "Keeps the app current with Google Play's target-API policy and the scoped-storage "
        "/ notification-permission / foreground-service-type behaviours it implements."],
       ["compileSdk", "36", "—"],
       ["Java 8+ APIs on older devices", "Enabled via core-library desugaring",
        "flutter_local_notifications uses java.time; desugaring makes it work down to API 24."]],
      widths=[1.9, 2.0, 3.5])
para("Practically: any Android phone or tablet sold from 2017 onward meets the OS floor. "
     "Android 10+ is recommended so the OS's own background-execution and notification "
     "controls behave predictably.")

h2("2.2  CPU architecture")
para("The release build ships native libraries for:")
table(["ABI", "Status", "Notes"],
      [["arm64-v8a", "**Recommended**", "Every 64-bit ARM phone / tablet. Best performance."],
       ["armeabi-v7a", "Supported", "Older / low-end 32-bit ARM devices."],
       ["x86_64", "Emulator / Chromebook only", "Not a field target."]],
      widths=[1.4, 2.2, 3.8])
para("A per-ABI split APK is ~25–28 MB; the universal APK is ~71 MB. Distribute the split "
     "APK or an Android App Bundle so each device downloads only its own ABI.")
note("The release build has no R8/ProGuard minification yet — enabling it would cut the "
     "APK and install size by roughly 30–40 %.")

h2("2.3  Memory (RAM)")
table(["", "Value", "Rationale"],
      [["Minimum", "**2 GB**",
        "The Flutter runtime plus the app's working set is ~150–300 MB. The first metadata "
        "sync decodes a multi-megabyte JSON payload on a background isolate — the transient "
        "peak is the memory-critical moment. On 1 GB devices that sync risks a low-memory "
        "kill mid-download, leaving the device needing a retry."],
       ["Recommended", "**3–4 GB**",
        "Headroom for the metadata decode, fl_chart dashboard rendering, and PDF / Excel "
        "export of a large form, with the OS keeping the app resident between sessions."]],
      widths=[1.3, 1.0, 5.1])

h2("2.4  Storage")
table(["Component", "Size", "Notes"],
      [["App install (per-ABI)", "~55–90 MB (estimate)",
        "Download ~25–28 MB; extracted native libs + assets roughly double it. Universal "
        "APK install is ~150 MB."],
       ["Bundled assets", "3.2 MB",
        "Noto Sans Ethiopic font (1.1 MB, for Amharic period labels) + images."],
       ["Per-user database", "**~20–80 MB typical, up to ~150 MB** (estimate)",
        "One SQLite file per logged-in user (hisp_<user>.sqlite + WAL/SHM sidecars). "
        "Dominated by the instance-wide metadata cache. Grows ~2–5 MB per year of active "
        "entry, plus the local audit trail."],
       ["Caches", "< 5 MB", "Outlier-history snapshots and local-dashboard result caches "
        "(JSON in the DB)."]],
      widths=[1.7, 2.3, 3.4])
para("Sizing rule: provision at least 1 GB free at install and budget ~200 MB per user who "
     "will log in on a shared device. A 16 GB device is the practical floor; 32 GB+ is "
     "comfortable. The app never writes to an SD card or shared storage.", bold=True)

h2("2.5  Display")
bullet("Portrait orientation is locked.")
bullet("Minimum usable: 5.0″, 720 × 1280 (HD).")
bullet("Recommended: a 6″+ phone, or better an 8–10″ tablet. The data-entry form is a "
       "table (data elements as rows, category-option-combo disaggregations as columns) "
       "plus collapsible sections — more width means less horizontal scrolling per row and "
       "fewer entry errors. For facilities capturing large disaggregated datasets a tablet "
       "materially improves entry speed and accuracy.")
bullet("Rendering uses Flutter's Impeller engine (Vulkan, GLES 3 fallback) — satisfied by "
       "any device meeting the API-24 floor. No dedicated GPU class is required.")

h2("2.6  Battery & power")
bullet("A push in flight is protected by an Android foreground service (dataSync type) so "
       "the OS does not kill it when the app is backgrounded.")
bullet("Deadline reminders use inexact alarms (no SCHEDULE_EXACT_ALARM) — low power "
       "impact, but the device must be powered on around 08:00 local to receive them.")
bullet("Recommend ≥ 3500 mAh for a full field day of intermittent capture and sync, or a "
       "power bank / vehicle charger for mobile teams.")
doc.add_page_break()

# ===========================================================================
# 3  iOS
# ===========================================================================
h1("3  iOS (Alternative Platform)")
table(["Item", "Value"],
      [["Deployment target", "iOS 13.0"],
       ["Minimum device", "iPhone 6s / iPhone SE (1st gen) / iPad (5th gen) / iPad mini 4"],
       ["Recommended", "iOS 15+, iPhone 11 or newer, iPad (8th gen) or newer"],
       ["Background sync", "Best-effort only — iOS caps background execution at a few "
        "seconds; no foreground-service equivalent. Sync completes reliably only while "
        "the app is open."],
       ["Notifications", "Require the user to grant permission on first launch."]],
      widths=[1.8, 4.8])
para("Storage, RAM, and display guidance match the Android figures in §2.")

# ===========================================================================
# 4  WEB
# ===========================================================================
h1("4  Web (Development & Demonstration Only)")
para("The web build is not a field-deployment target — it exists for development and demos.")
table(["Item", "Requirement"],
      [["Browser", "Chromium-based (Chrome / Edge) recommended; any browser with "
        "WebAssembly + a persistent store."],
       ["Persistence", "OPFS preferred; falls back to IndexedDB. A private-browsing "
        "window will not persist the database."],
       ["Assets", "sqlite3.wasm (732 KB) + drift_worker.js (344 KB) from web/, plus the "
        "Flutter web engine."],
       ["Host", "Served from localhost:3000 or localhost:3001 against staging — its CORS "
        "policy allows no other origin. Use ./run_web.sh (pins port 3001)."],
       ["Machine", "Any modern desktop / laptop, ~4 GB RAM."]],
      widths=[1.5, 5.1])

# ===========================================================================
# 5  CONNECTIVITY
# ===========================================================================
h1("5  Connectivity")
para("The app is offline-first: a health worker completes an entire day's or month's "
     "capture with no network and loses nothing. Connectivity is needed only to seed and "
     "drain the local database.")
table(["Phase", "Requirement", "Volume (estimate)"],
      [["First login + full metadata sync", "A stable connection for ~2–10 minutes. The "
        "one time a solid link matters — an interrupted first sync must be retried from "
        "the start.", "~5–30 MB download"],
       ["Returning login (delta sync)", "Brief connectivity.", "Typically < 1 MB"],
       ["Data push", "Brief connectivity; auto-retried on reconnect, on login, and on a "
        "5-minute heartbeat.", "Small — values batched at 500 per request"],
       ["Daily capture", "**None.**", "—"],
       ["Dashboards / analytics", "Live connection to view (results then cached offline).",
        "Varies per chart"]],
      widths=[2.2, 3.1, 1.3])
bullet("Any bearer works: 2G/3G/4G/LTE/5G mobile data, or Wi-Fi. No SIM is required if "
       "Wi-Fi is available for the periodic sync.")
bullet("Works behind HTTP proxies (id-list requests are chunked to keep URLs short).")
bullet("Transport is HTTPS only in release builds; the server's TLS certificate must "
       "chain to a CA in the device's system trust store (no certificate pinning).")

# ===========================================================================
# 6  NOT REQUIRED
# ===========================================================================
h1("6  Sensors & Peripherals — What Is NOT Required")
para("Procurement can safely choose devices without any of the following. The app "
     "requests none of the corresponding permissions.")
table(["Capability", "Required?"],
      [["Rear / front camera", "No"],
       ["GPS / location", "No"],
       ["Fingerprint / face unlock", "No (biometric app-lock is a roadmap item, not built)"],
       ["NFC", "No"],
       ["Bluetooth", "No"],
       ["SD card / external storage", "No"],
       ["Cellular modem / SIM (for daily use)", "No — only for the periodic sync, and "
        "Wi-Fi substitutes"],
       ["Google Play Services / GMS", "No — no Firebase, Maps, or Play-only APIs"],
       ["Accelerometer / gyroscope / other sensors", "No"]],
      widths=[3.6, 3.0])
para("The only Android permissions requested are INTERNET, ACCESS_NETWORK_STATE, "
     "FOREGROUND_SERVICE (+ FOREGROUND_SERVICE_DATA_SYNC), POST_NOTIFICATIONS, "
     "RECEIVE_BOOT_COMPLETED, and REQUEST_IGNORE_BATTERY_OPTIMIZATIONS.", size=9.5,
     color=GREY)
doc.add_page_break()

# ===========================================================================
# 7  OEM NOTES
# ===========================================================================
h1("7  OEM & Power-Management Notes")
para("Some manufacturers (Xiaomi/Redmi, Huawei/Honor, Oppo/Realme, Vivo, Samsung, Tecno, "
     "Infinix) kill background apps aggressively regardless of Android's standard rules. "
     "For reliable background sync and reminders on those devices:")
numbered("Allow notifications when prompted on first launch (Android 13+ requires it "
         "explicitly).")
numbered("Grant the battery-optimisation exemption — the app shows a one-time system "
         "prompt after login. Or set it manually: Settings → Apps → RDHIS2 → Battery → "
         "Unrestricted.")
numbered("On the OEMs above, also enable Autostart / Allow background activity in the "
         "manufacturer's own battery / security app.")
para("If these are not granted the app still works — sync simply happens the next time the "
     "user opens it, and reminders may be delayed — but the field experience is worse.")

# ===========================================================================
# 8  STORAGE GROWTH
# ===========================================================================
h1("8  Storage-Growth Model")
para("For capacity planning on a shared or long-lived device. All figures are estimates "
     "for a national-scale instance.")
table(["Item", "One-time", "Per year of active entry", "Notes"],
      [["Metadata cache", "15–60 MB / user", "negligible (delta only)",
        "Re-downloaded fully only on first login or after a wipe."],
       ["Captured data values", "—", "2–5 MB",
        "~10 datasets/month × ~100 values, plus completion registrations."],
       ["Local audit trail", "—", "1–3 MB",
        "One row per value change; never cleared by a metadata sync."],
       ["Result / history caches", "< 5 MB", "< 5 MB", "Bounded — overwritten, not appended."],
       ["Total per user", "**~20–70 MB**", "**~5–10 MB / year**",
        "Multiply by the number of users on the device."]],
      widths=[1.7, 1.1, 1.6, 2.2])
para("A device used by 5 users for 3 years: roughly 5 × (50 MB + 3 × 8 MB) ≈ 370 MB. Well "
     "within a 16 GB device; trivial on 32 GB+.")

# ===========================================================================
# 9  DEVICE PROFILES
# ===========================================================================
h1("9  Recommended Device Profiles")
table(["Profile", "Use case", "Suggested spec"],
      [["Field phone", "A single health worker, mobile, one facility",
        "Android 11+, arm64, 3 GB RAM, 32 GB storage, 6″ 1080p, 4000 mAh, 4G"],
       ["Facility tablet", "Shared at a facility, multiple users, large disaggregated "
        "datasets",
        "Android 11+, arm64, 4 GB RAM, 64 GB storage, 8–10″ 1200p, Wi-Fi (+ optional LTE)"],
       ["Supervisor device", "Woreda / zone user, dashboards + spot capture",
        "Android 12+, arm64, 4 GB RAM, 64 GB storage, 6.5″+ or tablet, 4G/LTE"],
       ["Minimum viable", "Budget constraint",
        "Android 7.0, armeabi-v7a, 2 GB RAM, 16 GB storage, 5″ 720p, 2500 mAh — expect "
        "slower first sync and occasional memory pressure"]],
      widths=[1.3, 2.3, 3.0])

# ===========================================================================
# 10  SERVER NOTE
# ===========================================================================
h1("10  Server-Side Note")
para("The app places a light, read-mostly load on the DHIS2 server. It does not change the "
     "server's own hardware requirements. The only server-side configuration it depends on:")
bullet("CORS allowing the web dev origin (localhost:3000/3001) — web only.")
bullet("Data-value auditing enabled if the server-side audit trail is to appear in the "
       "app's cell-history sheet (optional).")
bullet("A valid TLS certificate chaining to a public CA (no pinning; self-signed "
       "certificates will fail in release builds).")

hr = doc.add_paragraph()
pPr = hr._p.get_or_add_pPr()
bdr = OxmlElement('w:pBdr'); b = OxmlElement('w:bottom')
b.set(qn('w:val'), 'single'); b.set(qn('w:sz'), '6'); b.set(qn('w:color'), 'BBBBBB')
bdr.append(b); pPr.append(bdr)
para(f"Prepared from the build configuration at the current head, {LONG_DATE}. Companion "
     "to docs/20-hardware-and-deployment.md.", italic=True, size=9, color=GREY)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out_dir = os.path.join(REPO, 'technical_documentation')
os.makedirs(out_dir, exist_ok=True)
out = os.path.join(out_dir, 'RDHIS2_Mobile_Hardware_Specification.docx')
doc.save(out)
print("saved", out)

soffice = shutil.which('soffice') or shutil.which('libreoffice')
if soffice:
    subprocess.run([soffice, '--headless', '--convert-to', 'pdf',
                    '--outdir', out_dir, out], check=False)
    print("saved", out.replace('.docx', '.pdf'))
else:
    print("libreoffice not found — skipping PDF conversion")
