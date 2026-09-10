# Hardware Specification & Deployment Requirements

The device requirements to run RDHIS2 Mobile in the field, with the rationale behind each
figure, plus a storage-growth model and procurement guidance.

Figures marked *(estimate)* depend on the target DHIS2 instance's metadata volume and the
user's data-entry workload; they are sized for a Federal-MoH-scale national instance and a
facility or woreda user. Everything else is read from the build configuration.

---

## 1  At a glance

| | Minimum | Recommended |
|---|---|---|
| **Android OS** | 7.0 (API 24, Nougat) | 11 (API 30) or newer |
| **Architecture** | 32-bit ARM (`armeabi-v7a`) | 64-bit ARM (`arm64-v8a`) |
| **RAM** | 2 GB | 3–4 GB |
| **Free storage at install** | 1 GB | 4 GB+ (device ≥ 32 GB) |
| **Display** | 5.0″, 720 × 1280 (HD) | 6″+ phone, or 8–10″ tablet, 1080 × 1920 |
| **Battery** | 2500 mAh | 3500 mAh+ |
| **Connectivity** | Any 3G / Wi-Fi, intermittent | 4G / LTE or Wi-Fi for the first sync |
| **iOS (alternative)** | iOS 13.0, iPhone 6s / iPad (5th gen) | iOS 15+, iPhone 11 / iPad (8th gen) |
| **Sensors / peripherals** | **None required** | — |

The app is **portrait-only** and does **not** use the camera, GPS, fingerprint reader, NFC,
Bluetooth, SD card, or a SIM/cellular connection for daily work. See §6.

---

## 2  Android — detailed

### 2.1  Operating system

| Item | Value | Source / rationale |
|---|---|---|
| `minSdkVersion` | **24** — Android 7.0 (Nougat) | Resolved from `flutter.minSdkVersion` (Flutter 3.41.4). The app will not install below this. |
| `targetSdkVersion` | **36** — Android 16 | Keeps the app current with Google Play's target-API policy and the scoped-storage / notification-permission / foreground-service-type behaviours it already implements. |
| `compileSdk` | 36 | — |
| Java 8+ APIs on older devices | Enabled via core-library desugaring | `flutter_local_notifications` uses `java.time`; desugaring makes it work down to API 24. |

**Practically:** any Android phone or tablet sold from **2017 onward** meets the OS floor.
Android 10+ is recommended so the OS's own scoped background-execution and notification
controls behave predictably.

### 2.2  CPU architecture

The release build ships native libraries for:

| ABI | Status | Notes |
|---|---|---|
| `arm64-v8a` | **Recommended** | Every 64-bit ARM phone/tablet. Best performance. |
| `armeabi-v7a` | Supported | Older / low-end 32-bit ARM devices. |
| `x86_64` | Emulator / Chromebook only | Not a field target. |

A per-ABI split APK is ~25–28 MB; the universal APK (all ABIs) is ~71 MB. Prefer the split
APK or an Android App Bundle for distribution so each device downloads only its own ABI.

> The release build has **no R8/ProGuard minification** yet (see
> [Roadmap](15-roadmap-and-known-issues.md)) — enabling it would cut the APK and install
> size roughly 30–40 %.

### 2.3  Memory (RAM)

| | Value | Rationale |
|---|---|---|
| Minimum | **2 GB** | The Flutter runtime plus the app's working set is ~150–300 MB. The **first metadata sync** decodes a multi-megabyte JSON payload on a background isolate — the transient peak is the memory-critical moment. On 1 GB devices that sync risks a low-memory kill mid-download, leaving the device needing a retry. |
| Recommended | **3–4 GB** | Headroom for the metadata decode, `fl_chart` dashboard rendering, and PDF/Excel export of a large form, with the OS keeping the app resident between sessions. |

### 2.4  Storage

| Component | Size | Notes |
|---|---|---|
| App install (per-ABI) | ~55–90 MB *(estimate)* | Download ~25–28 MB; extracted native libs + assets roughly double it. Universal APK install is ~150 MB. |
| Bundled assets | 3.2 MB | Noto Sans Ethiopic font (1.1 MB, needed for Amharic period labels) + images. |
| **Per-user database** | **~20–80 MB typical, up to ~150 MB** *(estimate)* | One SQLite file **per logged-in user** (`hisp_<user>.sqlite` + WAL/SHM sidecars). Dominated by the instance-wide metadata cache (data elements, the category-combo tower, option sets, datasets, validation rules). Grows with captured data (~2–5 MB per year of active entry) and the local audit trail. |
| Caches | < 5 MB | Outlier-history snapshots and local-dashboard result caches (JSON in the DB). |

**Sizing rule:** provision **at least 1 GB free** at install and budget **~200 MB per
user** who will log in on a shared device. A 16 GB device is the practical floor; 32 GB+ is
comfortable. The app never writes to an SD card or shared storage.

### 2.5  Display

- **Portrait orientation is locked** (`SystemChrome.setPreferredOrientations`).
- Minimum usable: **5.0″, 720 × 1280 (HD)**.
- **Recommended: a 6″+ phone, or better an 8–10″ tablet.** The data-entry form is a table
  (data elements as rows, category-option-combo disaggregations as columns) plus
  collapsible sections — more screen width means less horizontal scrolling per row and
  fewer entry errors. For facilities capturing large disaggregated datasets, a tablet
  materially improves entry speed and accuracy.
- Rendering uses Flutter's Impeller engine (Vulkan, with a GLES 3 fallback) — satisfied by
  any device meeting the API-24 floor. No dedicated GPU class is required.

### 2.6  Battery & power

- A push in flight is protected by an Android **foreground service** (`dataSync` type) so
  the OS does not kill it when the app is backgrounded.
- **Deadline reminders** are scheduled as **inexact** alarms (no `SCHEDULE_EXACT_ALARM`) —
  low power impact, but the device must be powered on around the reminder time (08:00
  local) to receive them.
- Recommend **≥ 3500 mAh** for a full field day of intermittent capture and sync, or
  provision a power bank / vehicle charger for mobile teams.

---

## 3  iOS (alternative platform)

| Item | Value |
|---|---|
| Deployment target | **iOS 13.0** |
| Minimum device | iPhone 6s / iPhone SE (1st gen) / iPad (5th gen) / iPad mini 4 |
| Recommended | iOS 15+, iPhone 11 or newer, iPad (8th gen) or newer |
| Background sync | Best-effort only — iOS caps background execution at a few seconds; there is no foreground-service equivalent. Sync completes reliably only while the app is open. |
| Notifications | Require the user to grant permission on first launch. |

Storage, RAM, and display guidance match the Android figures above.

---

## 4  Web (development & demonstration only)

The web build is **not a field-deployment target** — it exists for development and demos.

| Item | Requirement |
|---|---|
| Browser | Chromium-based (Chrome / Edge) recommended; any browser with WebAssembly + a persistent store. |
| Persistence | OPFS preferred; falls back to IndexedDB (a warning is logged). A private-browsing window will not persist the database. |
| Assets | `sqlite3.wasm` (732 KB) + `drift_worker.js` (344 KB) served from `web/`, plus the Flutter web engine. |
| Host | Must be served from `localhost:3000` or `localhost:3001` against the staging server — its CORS policy allows no other origin. Use `./run_web.sh` (pins port 3001). |
| Machine | Any modern desktop/laptop, ~4 GB RAM. |

---

## 5  Connectivity

The app is **offline-first**: a health worker completes an entire day's or month's capture
with no network and loses nothing. Connectivity is needed only to seed and drain the local
database.

| Phase | Requirement | Volume *(estimate)* |
|---|---|---|
| **First login + full metadata sync** | A **stable** connection for ~2–10 minutes. This is the one time a solid link matters — an interrupted first sync must be retried from the start. | ~5–30 MB download, depending on the instance's metadata size. |
| **Returning login (delta sync)** | Brief connectivity. | Typically < 1 MB — only changed metadata objects. |
| **Data push** | Brief connectivity; auto-retried on reconnect, on login, and on a 5-minute heartbeat. | Small — values batched at 500 per request; a facility's monthly backlog is well under 1 MB. |
| **Daily capture** | **None.** | — |
| **Dashboards / analytics** | Live connection to view (results are then cached for offline viewing). | Varies per chart. |

- **Any bearer works:** 2G/3G/4G/LTE/5G mobile data, or Wi-Fi. No SIM is required if Wi-Fi
  is available for the periodic sync.
- Works behind HTTP proxies (id-list requests are chunked to keep URLs short).
- Transport is **HTTPS only** in release builds; the server's TLS certificate must chain to
  a CA in the device's system trust store (there is no certificate pinning).

---

## 6  Sensors & peripherals — what is NOT required

Procurement can safely choose devices without any of the following. The app requests **none**
of the corresponding permissions.

| Capability | Required? |
|---|---|
| Rear / front camera | No |
| GPS / location | No |
| Fingerprint / face unlock | No (biometric app-lock is a roadmap item, not built) |
| NFC | No |
| Bluetooth | No |
| SD card / external storage | No |
| Cellular modem / SIM (for daily use) | No — only for the periodic sync, and Wi-Fi substitutes |
| Google Play Services / GMS | No — the app uses no Firebase, Maps, or Play-only APIs |
| Accelerometer / gyroscope / other sensors | No |

The only Android permissions requested are `INTERNET`, `ACCESS_NETWORK_STATE`,
`FOREGROUND_SERVICE` (+ `FOREGROUND_SERVICE_DATA_SYNC`), `POST_NOTIFICATIONS`,
`RECEIVE_BOOT_COMPLETED`, and `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` — see
[Authentication & Security](04-authentication-and-security.md#android-build--manifest-security).

---

## 7  OEM & power-management notes

Some manufacturers (Xiaomi/Redmi, Huawei/Honor, Oppo/Realme, Vivo, Samsung, Tecno, Infinix)
kill background apps aggressively regardless of Android's standard rules. For reliable
background sync and reminders on those devices:

1. **Allow notifications** when prompted on first launch (Android 13+ requires it explicitly).
2. **Grant the battery-optimisation exemption** — the app shows a one-time system prompt
   after login. Or set it manually: *Settings → Apps → RDHIS2 → Battery → Unrestricted*.
3. On the OEMs above, also enable *Autostart* / *Allow background activity* in the
   manufacturer's own battery/security app.

If these are not granted the app still works — sync simply happens the next time the user
opens it, and reminders may be delayed — but the field experience is worse.

---

## 8  Storage-growth model

For capacity planning on a shared or long-lived device. All figures are *estimates* for a
national-scale instance.

| Item | One-time | Per year of active entry | Notes |
|---|---|---|---|
| Metadata cache | 15–60 MB per user | negligible (delta only) | Re-downloaded fully only on first login or after a wipe. |
| Captured data values | — | 2–5 MB | ~10 datasets/month × ~100 values, plus completion registrations. |
| Local audit trail | — | 1–3 MB | One row per value change; never cleared by a metadata sync. |
| Result / history caches | < 5 MB | < 5 MB | Bounded — overwritten, not appended. |
| **Total per user** | **~20–70 MB** | **~5–10 MB / year** | Multiply by the number of users who log in on the device. |

A device used by 5 users for 3 years: roughly **5 × (50 MB + 3 × 8 MB) ≈ 370 MB**. Well
within a 16 GB device; trivial on 32 GB+.

---

## 9  Recommended device profiles

| Profile | Use case | Suggested spec |
|---|---|---|
| **Field phone** | A single health worker, mobile, one facility | Android 11+, arm64, 3 GB RAM, 32 GB storage, 6″ 1080p, 4000 mAh, 4G |
| **Facility tablet** | Shared at a facility, multiple users, large disaggregated datasets | Android 11+, arm64, 4 GB RAM, 64 GB storage, 8–10″ 1200p, Wi-Fi (+ optional LTE) |
| **Supervisor device** | Woreda/zone user, dashboards + spot capture | Android 12+, arm64, 4 GB RAM, 64 GB storage, 6.5″+ or tablet, 4G/LTE |
| **Minimum viable** | Budget constraint | Android 7.0, armeabi-v7a, 2 GB RAM, 16 GB storage, 5″ 720p, 2500 mAh — expect slower first sync and occasional memory pressure |

---

## 10  Server-side note

The app places a light, read-mostly load on the DHIS2 server (see
[API Reference](19-api-reference.md)). It does **not** change the server's own hardware
requirements. The only server-side configuration it depends on:

- CORS allowing the web dev origin (`localhost:3000/3001`) — web only.
- Data-value **auditing enabled** if the server-side audit trail is to appear in the app's
  cell-history sheet (optional).
- A valid TLS certificate chaining to a public CA (no pinning; self-signed certificates
  will fail in release builds).
