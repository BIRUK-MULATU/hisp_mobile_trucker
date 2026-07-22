# Code Conventions

These are the patterns actually followed throughout the codebase — match them when adding
code, rather than introducing a new style for a new feature.

## Linting

`analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` with no
project-specific rule overrides currently active. `flutter analyze` must be clean — it's a
CI gate, not a suggestion.

## Feature module shape

When adding a new feature under `lib/features/<name>/`:
- If it has real business logic or more than one data source, give it the full
  `data/domain/presentation` split (see `auth`, `capture`, `data_entry` as references).
- If it's presentation-only — composing other features, with no persistence or business
  rules of its own — skip `data`/`domain` entirely (see `home`, `settings`). Don't create
  empty placeholder folders "for consistency"; `visualization` shows the middle ground (has
  `data`/`domain` because it owns real entities and a repository, but skipped a repository
  *interface* because there's only ever one implementation).

## Repository pattern

- Domain defines an **abstract class** with `Future<T>` methods and clear doc comments on
  each — these comments are load-bearing documentation, not decoration (see
  `CaptureRepository`, `DataEntryRepository` for the standard of detail expected).
  Interfaces stay small: 4–6 methods, one clear responsibility each.
- Data provides exactly one `XRepositoryImpl implements XRepository`. Constructor accepts
  its dependencies (session, network info, etc.) as **optional named parameters that default
  to the real singleton** — this is what makes the class constructible with fakes in tests
  without a DI container:
  ```dart
  CaptureRepositoryImpl({SessionService? session})
      : _session = session ?? AppSession.instance.service;
  ```
- Use cases are thin wrappers — validation plus a call-through, never business logic that
  belongs in the repository or the domain entity itself.

## Errors

- Data-layer code throws `AppException` subtypes from `lib/core/errors/exceptions.dart`
  (`NetworkException`, `UnauthorizedException`, `ServerException`, `TimeoutException`,
  `CacheException`) — don't throw a raw `Exception` or a `String`.
- Catch specific subtypes before a catch-all, in the order the user would want the most
  specific message (see `AuthBloc._onLoginSubmitted` for the reference pattern).
- A `DioException` should never leak past the data-source/repository boundary uncaught —
  catch it there and translate to an `AppException`, or (for sync-specific code) inspect the
  response for a parseable server verdict (see
  [Offline & Sync](07-offline-and-sync.md#server-verdict-parsing-pushdatavaluebatch)) before
  deciding it's a transport failure.

## Database access

- Never write raw SQL with string interpolation. Use Drift's query builder exclusively — the
  only acceptable `customStatement()` calls are fixed `PRAGMA` statements with no user input.
- New metadata types extend `MetadataResource<Row>` (`lib/core/metadata/metadata_resource.dart`)
  rather than writing bespoke sync code — you get `syncAll`/`syncDelta`/`getAll`/`getById`
  for free by implementing `resource`, `fields`, `table`, `uidColumn`, `lastUpdatedColumn`,
  and `companionFromJson`. See `data_element.dart` as the reference implementation.
- Adding a new table means: (1) define the `Table` subclass, (2) add it to
  `@DriftDatabase(tables: [...])` in `app_database.dart`, (3) if it's metadata, add it to
  `MetadataSyncService._clearMetadata()`'s explicit list, (4) bump `schemaVersion` and add a
  migration step, (5) regenerate. Skipping any of these steps produces a subtly broken app,
  not a compile error, in at least one case (step 3).

## Sync-state fields

Any new locally-queued write table should follow the existing `syncState` (`SyncState` enum:
`synced`/`pending`/`error`/`draft`) + `syncError` (nullable text) + `lastModified`
(`DateTime`, sourced from `PeriodAccess.effectiveNow()`, never raw `DateTime.now()`)
convention — this is what every sync-aware class in `core/sync/` and `core/data/` expects to
find.

## Bloc

- One `part of` triplet: `x_bloc.dart` + `x_event.dart` + `x_state.dart`.
- Events and States are plain classes with `const` constructors — no `Equatable`, no
  `freezed`. `BlocBuilder` logic in this app checks state type (`state is XLoaded`), not
  value equality, so don't rely on equality-based rebuild suppression.
- Construct the Bloc, its use cases, and its repository at the page level (see
  [Architecture — Dependency Injection](02-architecture.md#dependency-injection)), not
  higher up the widget tree.

## Naming

- Files: `snake_case.dart`. Classes: `UpperCamelCase`. Private classes/members:
  leading-underscore, same case rules.
- Repository interfaces: `XRepository`. Implementations: `XRepositoryImpl`. Use cases:
  `VerbNounUseCase` (e.g. `GetOrgUnitChildrenUseCase`, `SaveDataValuesUseCase`).
- Drift tables: `XTable` classes generating `@DataClassName('X')` row classes (e.g.
  `DataElementsTable` → generated `DataElement`).

## Comments

The existing codebase writes comments that explain **why**, not what — a constraint, an
invariant, a past bug being guarded against, or a non-obvious trade-off (see nearly every
file quoted in these docs for the standard). Match that: don't add comments restating what a
line of code already says; do add one when a reviewer six months from now would otherwise
ask "wait, why is this here?"

## Theming

Pull colors, text styles, spacing, and breakpoints from `lib/shared/theme/` (`AppColors`,
`AppTextStyles`, `AppDimensions`, `AppBreakpoints`) rather than hardcoding values in a
widget. Reusable UI pieces belong in `lib/shared/widgets/`, not duplicated per feature.
