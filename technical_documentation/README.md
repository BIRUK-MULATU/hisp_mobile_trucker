# Technical Documentation (consolidated)

Two single-file, stakeholder-facing documents (`.docx` + `.pdf` each):

| File | Covers | Regenerate |
|---|---|---|
| `RDHIS2_Mobile_Technical_Documentation` | The whole system — overview, architecture, offline-first design, data capture & quality, synchronization, visualization, reminders & onboarding, security posture, database schema, build / release / CI, testing, roadmap. Two appendices: a DHIS2 glossary and a key-file reference. | `python3 scripts/build_technical_doc.py` |
| `RDHIS2_Mobile_API_Reference` | Every DHIS2 Web API endpoint the app calls, as formatted tables — the GET / POST / DELETE method rules (no PUT/PATCH anywhere), the exact request shape and caller per endpoint, the metadata field selectors, and the delta-sync + push-verdict algorithms. Landscape. | `python3 scripts/build_api_reference.py` |
| `RDHIS2_Mobile_Hardware_Specification` | The device requirements to run the app in the field — Android (min API 24) / iOS (13.0) / web, RAM / storage / display / battery with rationale, connectivity needs, the storage-growth model, an explicit list of hardware the app does *not* need, OEM power-management notes, and recommended device profiles for procurement. | `python3 scripts/build_hardware_spec.py` |

**Audience:** engineers new to the project, and technical reviewers / HISP / Ministry
stakeholders who need an accurate picture of the system without reading the code.

## Regenerating

```bash
pip install --break-system-packages python-docx      # once
python3 scripts/build_technical_doc.py               # from the repo root
python3 scripts/build_api_reference.py
```

Each writes its `.docx` and (if `libreoffice` / `soffice` is on `PATH`) its `.pdf` into
this folder. The document content lives in the scripts as structured Python, so it stays
diff-able and reviewable.

## Relationship to `docs/`

`docs/` is the chapter-by-chapter developer reference, each claim cited to a file. This
document is the consolidated narrative built from the same material. When they drift, keep
`docs/` authoritative and re-fold the changes here.
