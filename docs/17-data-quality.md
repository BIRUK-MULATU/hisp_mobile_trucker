# Data Quality

This chapter covers everything the app does to keep captured data correct *at the point of
entry*, before it ever reaches the server. All of it runs offline. Each mechanism has a
different contract — some warn, some block, some just record — and the differences are
deliberate: they mirror the DHIS2 web and Android clients.

| Mechanism | File | Contract |
|---|---|---|
| Value-type validation | `core/data/value_type_validator.dart` | **Blocks save** of the offending cell |
| Validation rules | `core/data/validation_service.dart` | **Warns** at completion, never blocks |
| Mandatory fields | `data_entry_repository_impl.dart` + `dataSetElement.compulsory` | **Blocks completion** |
| Grey fields | `SectionGreyFieldsTable` | Cell is non-editable |
| Controller elements | `core/data/controller_element_service.dart` | Hides/shows a group's other elements |
| Outlier detection | `core/data/outlier_detection_service.dart` | **Warns** on entry, user can keep or fix |
| Audit trail | `core/data/audit_log_store.dart`, `server_audit_service.dart` | Records only — no gate |

## Value-type validation

`validateDataValue()` mirrors DHIS2's own server-side `valueType` checks (NUMBER, INTEGER,
POSITIVE_INTEGER, PERCENTAGE, UNIT_INTERVAL, BOOLEAN, TRUE_ONLY, DATE, PHONE_NUMBER, EMAIL,
option-set membership, …). It runs:

1. inline in the cell widget as the user types, and
2. **again inside `DataEntryBloc`'s save path** — `invalidEditedValues()` re-checks every
   *user-edited* cell (`isModified == true`) before `_onSave` will call the use case. If
   anything fails, `DataEntryError` is emitted listing every problem and **nothing is
   saved**.

Gate 2 exists specifically so no invalid value can reach `DataValueStore` through the
Bloc even if the inline check is somehow bypassed. Unknown / `TEXT` / `LONG_TEXT` types are
accepted as-is — the server stays the final authority.

## Validation rules (offline)

`ValidationService.validateForm(...)` runs the synced DHIS2 validation rules against one
form instance's local values — fully offline, on exactly the data the user sees.

### The expression evaluator

`ExpressionEvaluator` implements **the same subset the official DHIS2 Android SDK evaluates
offline**: arithmetic (`+ - * /`, parentheses, unary minus) over data-element operands
(`#{deUid}` — the element total across its combos — or `#{deUid.cocUid}` — one cell) and
numeric literals. Anything beyond that (`d2:` functions, constants `C{...}`, indicators,
`[days]`, org-unit groups) throws `UnsupportedExpression` and **the rule is skipped, not
guessed at** — an informative check must never invent a violation from data it can't read.

### Which rules are considered

- `periodType` matches the dataset's (or is unset), **and**
- at least one operand is an element of this dataset.

Missing-value strategies are honoured per side: `NEVER_SKIP`, `SKIP_IF_ANY_VALUE_MISSING`,
`SKIP_IF_ALL_VALUES_MISSING` (the DHIS2 default). The pair operators `compulsory_pair`
(both sides filled or neither) and `exclusive_pair` (not both) are evaluated on **presence**,
not arithmetic.

### The contract

**Violations warn; they never block completing the form** — the same contract as the DHIS2
web and Android apps. Each `ValidationViolation` carries the rule name, a human-readable
comparison (`"ANC 1st visit (12) should be ≤ ANC follow-up (10)"`), the rule author's
instruction text, and importance (HIGH/MEDIUM/LOW).

`validateValues(...)` is the same evaluation against values held in memory (the Bloc's
current state) rather than the database — this is what lets the validation banner update
**live as the user types**, before anything is saved. The same check runs again at
completion against the saved local values.

## Mandatory fields

Two DHIS2 configuration shapes are synced and enforced:

- `dataSetElement.compulsory` — a whole data element required in the form
  (`DataSetElementsTable.compulsory`, added in schema v4).
- `dataSet.compulsoryDataElementOperands` — a specific element **+ category-option-combo**
  pair required (`CompulsoryDataElementOperandsTable`, schema v5).

`DataEntryRepository.missingMandatoryFields(...)` returns the compulsory fields with no
value saved locally, **across the whole dataset** (not just the current section —
completing acts dataset-wide). Unlike validation rules, **a missing mandatory field blocks
completing the form** — again matching the DHIS2 web / Android contract for compulsory
fields.

## Grey fields

`SectionGreyFieldsTable` holds the per-section disabled cells (DHIS2 `greyedFields`). They
sync like any other link table and render non-editable in the form exactly as the server
configures them.

## Controller data elements

`ControllerElementService.controllersFor(elementUids)` resolves DHIS2 "controller data
elements": a **Boolean** data element tagged with the custom attribute
`"Controller Data Element Attribute" == "true"`, whose current value gates the visibility of
the *other* data elements in its **data element group**.

Example: `"RMNCH - Delivery services provided"` (Yes/No) controls every other element in its
`"CG_Delivery Services"` group — answering **No** hides them, and the caller clears any data
already entered for the hidden elements.

Purely a metadata lookup — it reads the same synced tables (`AttributeValuesTable`,
`DataElementGroupMembersTable`) every `MetadataResource` reads; no network.

## Outlier detection

The statistical companion to the rule check: as the user types a numeric value it is judged
against **that same cell's own recent history at that org unit**.

### History snapshot

`OutlierDetectionService.fetchHistory(...)`:

1. Pulls ~25 months (`_historyWindowDays = 770`) of the dataset's values for the org unit
   via `GET /api/dataValueSets.json` (date-windowed) — so a monthly dataset has two full
   years of the same season to compare against.
2. Groups the values by `<dataElementUid>_<cocUid>` cell (keeping only rows under the
   form's `attributeOptionCombo`) and reduces each to an `OutlierStats` (n, mean, stdDev,
   median, MAD, min, max).
3. Caches the whole snapshot under a `syncInfo` key (`outlierHistory_<ds>_<ou>_<aoc>`).

Offline, it returns the last cached snapshot. An empty result means **"check disabled"** —
never an error, same informative-only contract as validation rules.

> **The server's own `/api/outlierDetection` endpoint is deliberately not used** — it only
> scores values already stored server-side and cannot judge the value being typed right
> now.

### Algorithms

One **global** user setting (`OutlierConfig`, persisted in `SharedPreferences` via
`OutlierConfigStore` — a UI preference, not a credential, so it survives login/logout):

| Algorithm | How it flags | Notes |
|---|---|---|
| **Modified Z-score** (default) | distance from the **median** in scaled MADs | Robust to the very outliers it's looking for — DHIS2's `MODIFIED_Z_SCORE` |
| Z-score | distance from the **mean** in standard deviations | DHIS2's `Z_SCORE` |
| Min–Max | outside the historical `[min, max]` range, widened by a guard band of `threshold × stdDev` | A single past spike doesn't permanently stretch the range |

Threshold defaults to `3.0`. `OutlierDetectionService.judge(...)` returns `null` (no flag)
when the value parses to nothing, when `n < 3`, or when the spread the algorithm needs is
zero.

### Behaviour in the form

`DataEntryPage` debounces (~600 ms) after edits, re-judges every modified numeric cell, and
raises `showOutlierWarning(...)` for the first not-yet-acknowledged outlier. The dialog
shows the typical value (median), the historical range, and the acceptable bounds. The user
can **keep** the value (acknowledged once, not re-prompted) or correct it. Changing the
detection settings clears the acknowledgements and re-runs the check.

## Audit trail

The per-cell **"history" sheet** (`lib/features/audit_log/presentation/widgets/cell_history_sheet.dart`)
merges two sources into one timeline:

| Source | What it is | Scope |
|---|---|---|
| **`AuditLogStore`** (local) | Append-only trail of edits made on **this device** — old value, new value, who, when. Written by `DataValueStore.setValue` / `CompletenessStore.setComplete` themselves, so every write path is covered without call sites remembering to log. A no-op is recorded for an edit that changes nothing. | This device only. Works offline. |
| **`ServerAuditService`** (server) | DHIS2's own audit trail via `GET /api/audits/dataValue.json` — authoritative history reflecting edits from *every* client (web, other devices). CREATE / UPDATE / DELETE per entry. Scoped to one cell, same query DHIS2's own entry apps run for "Show history". | Server-wide. **Requires data-value auditing enabled server-side** — an empty result does not prove nothing changed. |

Both are keyed to the same field shape (`dataElement`/`period`/`orgUnit`/`categoryOptionCombo`
/`attributeOptionCombo` → value, timestamp, `modifiedBy`, `auditType`) so the two render
identically in the sheet. `AuditLogTable` (schema v2, with `auditType` added in v3) is never
cleared by a metadata sync.

## Form export

An open form can be exported for a paper backup or off-device review:

- **PDF** — `buildDataEntryPdf(...)` → the platform print / share sheet (`printing`).
- **Excel** — `buildDataEntryExcel(...)` → shared as an `.xlsx` file (`excel` + `share_plus`).
