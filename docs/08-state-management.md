# State Management

## flutter_bloc, consistently

The whole app uses the **Bloc** pattern (`flutter_bloc: ^8.1.6`) — events in, states out,
unidirectional. There is no use of the lighter-weight `Cubit` anywhere, and no other state
management library (no Provider-as-state-container, no Riverpod, no setState-only screens
for anything with real business logic — though plenty of purely-local UI state, like a
filter panel's expanded/collapsed flag, does legitimately use `StatefulWidget.setState`,
which is the correct tool for state with zero business meaning).

```
User action (tap, type)
        │
        ▼
   dispatch Event ──▶  Bloc  ──▶  emit State
                                       │
                                       ▼
                              BlocBuilder/BlocConsumer rebuilds
```

## The two Blocs

### `AuthBloc` (`lib/features/auth/presentation/bloc/auth_bloc.dart`)

Events (`auth_event.dart`): `AuthCheckRequested`, `LoginSubmitted(username, password)`,
`LogoutRequested`.

States (`auth_state.dart`): `AuthInitial`, `AuthCheckInProgress`, `AuthLoginInProgress`,
`AuthAuthenticated(UserEntity user)`, `AuthUnauthenticated`, `AuthFailureState(String
message)`, `AuthLoggedOut`.

`LoginPage` wires it with `BlocConsumer`:
```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) context.go(AppRouter.home);
  },
  builder: (context, state) {
    if (state is AuthInitial || state is AuthCheckInProgress) {
      return const AppLoader(color: Colors.white);
    }
    return _LoginBody(sessionExpired: sessionExpired);
  },
)
```
`listener` drives navigation (a one-time side effect); `builder` drives what's on screen. This
split is exactly why `BlocConsumer` (rather than just `BlocBuilder`) is used here — navigation
must not run again on every rebuild.

Error handling inside `_onLoginSubmitted` pattern-matches each `AppException` subtype in turn
(`UnauthorizedException`, `NetworkException`, `TimeoutException`, `ServerException`) before a
catch-all, so the message shown to the user is the specific, correct one rather than a
generic failure string.

### `DataEntryBloc` (`lib/features/data_entry/presentation/bloc/data_entry_bloc.dart`)

Events (`data_entry_event.dart`): `DataEntryLoad(dataSetId, orgUnitId, period, sectionId)`,
`DataEntryValueChanged(dataElementId, categoryOptionComboId, value)`, `DataEntrySave()`.

States (`data_entry_state.dart`): `DataEntryInitial`, `DataEntryLoading`,
`DataEntryLoaded(dataElements, dataValues, hasChanges, isSaving)`, `DataEntrySaved`,
`DataEntryError(String message)`.

Two behaviors worth knowing if you're extending this Bloc:

1. **Value edits are purely in-memory until Save.** `_onValueChanged` mutates a
   `Map<String, DataValueEntity>` held in `DataEntryLoaded` and re-emits a `copyWith` — it
   does **not** touch the database. Only `_onSave` calls through to
   `SaveDataValuesUseCase` → `DataValueStore.setValue(..., draft: true)`.
2. **Client-side validation gates the save**, not just the UI. `invalidEditedValues()` (a
   top-level function in the same file, reused by the page's Save button for a pre-flight
   check) runs `validateDataValue()` against every **user-edited** cell (`isModified ==
   true` — values that arrived from the server unedited are never re-validated) before
   `_onSave` will actually call the use case. If anything fails, it emits `DataEntryError`
   listing every problem, and nothing is saved — this is a second gate on top of whatever
   inline validation the form widgets do, specifically so no invalid value can reach
   `DataValueStore` through the Bloc's `DataEntrySave` path even if a UI check is bypassed.

## Adding a new Bloc

Follow the existing shape exactly:
1. `part 'x_event.dart'; part 'x_state.dart';` at the top of the Bloc file (all three files
   share one library via `part of`).
2. Events and States are plain classes (not `Equatable`-based) — equality isn't relied on for
   rebuild suppression here; `BlocBuilder` rebuilds on every emitted state by runtime type
   check (`state is XLoaded`), not value equality.
3. Constructor takes use cases (not the repository directly, when a use case exists for the
   operation) plus, if the page needs to call repository methods the Bloc doesn't wrap
   (like `DataEntryPage` calling `completeDataSet` directly), expose the repository as a
   public field the way `DataEntryBloc.repository` does.
4. Register event handlers in the constructor body with `on<EventType>(_handler)`.
5. Wire with `BlocProvider(create: (_) => XBloc(...))` at the page level, not higher — every
   page in this app constructs its own Bloc (and its own repository/use cases) rather than
   sharing a bloc instance across screens. See [Architecture](02-architecture.md#dependency-injection).

## Why Bloc, for this app specifically

State transitions here have real consequences (a `DataEntrySave` either lands in the
database as a draft or it doesn't) — expressing them as named, discrete events and states
makes every transition auditable and independently testable without needing a running
widget tree. It's also what makes it natural to write focused unit tests against
`invalidEditedValues()` or the resolve-conflict logic without booting a single `Widget`.
