# Testing

## Running tests

```bash
flutter test              # everything under test/
flutter analyze           # static checks — also a hard CI gate
```

Both run in CI on every push to `main`/`integration*` and every pull request
(`.github/workflows/ci.yml`, pinned to Flutter 3.41.4). A red CI blocks merge.

## What exists today

11 test files, ~1,450 lines, mirroring `lib/` under `test/`:

```
test/
├── widget_test.dart                              (smoke tests)
├── core/
│   ├── data/
│   │   ├── data_value_store_test.dart
│   │   ├── data_value_sync_test.dart
│   │   ├── data_value_push_test.dart
│   │   ├── completeness_test.dart
│   │   ├── ethiopian_calendar_test.dart
│   │   ├── ethiopian_period_service_test.dart
│   │   └── value_type_validator_test.dart
│   └── database/
│       └── data_element_roundtrip_test.dart
├── features/capture/
│   └── capture_repository_impl_test.dart
└── shared/
    └── resolve_date_filter_test.dart
```

**Coverage is deliberately weighted toward the offline-critical core** — the sync engine,
conflict resolution, completeness tracking, value validation, the Ethiopian calendar, and
Drift round-tripping — exactly the code where a bug would silently corrupt or lose field
data. This is the right prioritization for an app at this stage: it's also the code that's
hardest to manually verify by clicking through the UI.

**What's thin:** Bloc-level tests (`AuthBloc`, `DataEntryBloc` have no dedicated test files)
and full widget/integration tests beyond `widget_test.dart`'s smoke-level rendering checks.
If you're adding a new Bloc or a non-trivial widget, consider adding coverage — there isn't
an established pattern for it yet in this codebase, so you'd be setting the precedent.

## How the database tests work, and why they're fast

Every test that touches `AppDatabase` uses:
```dart
db = AppDatabase.forTesting(NativeDatabase.memory());
```
A fully in-memory SQLite database — no file I/O, no platform channel, no emulator required.
This is what lets `capture_repository_impl_test.dart` and the `core/data/*` tests run in
plain `flutter test` on CI (`ubuntu-latest`, no Android/iOS toolchain needed for these).

Typical shape (paraphrased from `data_value_sync_test.dart`):
```dart
late AppDatabase db;
late DataValueStore store;

setUp(() async {
  db = AppDatabase.forTesting(NativeDatabase.memory());
  store = DataValueStore(db);
});

tearDown(() async => db.close());

test('pull sync merges server values with local changes', () async {
  final result = await DataValueSync(db, fakeApiClient).syncForm(...);
  expect(result.pulledCount, 1);
});
```

Network-touching classes (`DataValueSync`, `CompletenessSync`, `MetadataSyncService`) accept
an `ApiClient` by constructor injection, so tests build one against a **canned/fake HTTP
adapter** rather than hitting a real server — the same manual-DI pattern used throughout the
app (see [Architecture](02-architecture.md#dependency-injection)) is what makes this testable
without a mocking framework.

## Writing a new test

Follow the existing pattern closest to what you're testing:

- **Pure logic, no I/O** (e.g. a new validator, a new calendar rule) → a plain `test()`
  function with no setup, mirroring `value_type_validator_test.dart`.
- **Anything touching `AppDatabase`** → `setUp`/`tearDown` with an in-memory database, as
  above.
- **Anything touching the network** → inject a fake/canned `ApiClient` rather than mocking
  Dio directly; check how `data_value_sync_test.dart` builds its fake response.
- **Repository implementations** → seed the in-memory database directly with the rows you
  need (see `capture_repository_impl_test.dart`'s helper functions), then assert against
  the repository's public interface — don't reach into private internals.

There is no `mockito`/`mocktail` dependency in `pubspec.yaml` — the project favors real
fakes/in-memory implementations over generated mocks. Follow that convention rather than
introducing a mocking library for a single test.
