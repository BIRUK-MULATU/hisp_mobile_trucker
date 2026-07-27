# Networking

## ApiClient

`lib/core/network/api_client.dart` is a singleton wrapping a single `Dio` instance.

```dart
class ApiClient {
  ApiClient._internal() { _init(); }
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ...
}
```

Base configuration (`_init()`):

```dart
BaseOptions(
  baseUrl: baseUrl ?? ApiConstants.baseUrl,       // https://hmis-staging.moh.gov.et/api
  connectTimeout: Duration(milliseconds: 30000),
  receiveTimeout: Duration(milliseconds: 30000),
  sendTimeout: Duration(milliseconds: 30000),
  headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
)
```

`_dio.transformer = BackgroundTransformer()` — large JSON responses (e.g. a full metadata
sync payload) are decoded on a background isolate so the UI thread, and any loading spinner,
never freezes.

`updateBaseUrl(String)` lets the app repoint at a different server at runtime (used by the
Settings screen and the login screen's server-URL dialog) without restarting.

A second constructor, `ApiClient.withBasicAuth({baseUrl, username, password})`, builds a
**plugin-free** Dio client with a fixed `Authorization` header and no `AuthInterceptor` (which
depends on `flutter_secure_storage`, a platform plugin unavailable under plain `flutter
test`). This is used for: (a) the one-shot credential-verification probe during login, (b)
the per-session sync API client held on `AppSession.instance.api`, and (c) tests/CLI tools.

## Interceptor chain

Applied in this order on the main `ApiClient()`:

1. **`AuthInterceptor`** (`lib/core/network/interceptors/auth_interceptor.dart`)
   - `onRequest`: sets `Content-Type`/`Accept` headers.
   - `onError`: if the response is a 401, deletes the legacy secure-storage token, ends the
     session (`AppSession.instance.service.logout()`), and redirects to
     `/login?reason=session-expired` (unless already there).
   - Also owns `buildBasicToken()`, the one place the Basic Auth header string is built.
2. **`LoggingInterceptor`** (`lib/core/network/interceptors/logging_interceptor.dart`)
   - Debug-mode only (`if (kDebugMode)`).
   - Logs method/URI/headers(redacted)/body preview on request; status/body preview on
     response; full detail on error.
   - `_preview()` never stringifies whole collections — lists/maps are summarized by size
     first, and any string form is truncated to 500 characters, so a huge payload can't
     block the UI isolate just to be logged and thrown away.

The `ApiClient.withBasicAuth` variant instead uses a private `_apiLogInterceptor()` static
helper with the same "never log headers" discipline, built directly into `api_client.dart`.

## Error handling

`lib/core/errors/exceptions.dart` defines two parallel hierarchies:

- **Data-layer exceptions** (thrown by data sources / repositories):
  `AppException` → `NetworkException`, `UnauthorizedException`, `ServerException`,
  `TimeoutException`, `CacheException`.
- **Domain-layer failures** (what a use case/Bloc should reason about, if it needs a typed
  failure rather than a caught exception): `Failure` → `NetworkFailure`, `AuthFailure`,
  `ServerFailure`, `TimeoutFailure`, `CacheFailure`, `UnknownFailure`.

In practice, most Bloc code catches the concrete `AppException` subtypes directly (see
`AuthBloc._onLoginSubmitted`, which pattern-matches on `UnauthorizedException`,
`NetworkException`, `TimeoutException`, `ServerException` in turn) rather than converting to
`Failure` first — the `Failure` hierarchy exists as the domain-layer vocabulary but isn't
uniformly used as an intermediate mapping step everywhere yet.

`DioException` itself is caught at the data-source/sync level, not left to propagate into
Presentation. See [Offline & Sync](07-offline-and-sync.md#error-and-conflict-handling) for
how sync-specific errors (409 conflicts) are handled — they are **not** transport failures,
they're server *verdicts* with a parseable body.

## A concrete request/response trace

Fetching org unit children (though in the *current* implementation this is a pure local
read — included here because it's the clearest example of the layering):

```
CaptureOrgUnitView (Presentation)
  → GetOrgUnitChildrenUseCase.call(parentId)              (Domain)
  → CaptureRepository.getOrgUnitChildren(parentId)         (Domain interface)
  → CaptureRepositoryImpl.getOrgUnitChildren(parentId)     (Data implementation)
  → OrgUnitResource(_db).getChildren(parentId)             (Core/metadata — Drift query,
                                                             NOT a network call)
  → OrgUnitTreeNode entities returned back up the chain
```

For an actual network-backed example — pulling fresh data values when a form opens
(`DataValueSync._pullAndResolve`):

```
DataEntryRepositoryImpl.getDataValues(...)
  → DataValueSync(db, api).syncForm(...)
  → ApiClient.get('/api/dataValueSets.json', queryParameters: {dataSet, period, orgUnit})
  → Dio → AuthInterceptor → LoggingInterceptor → network → DHIS2 server
  → response parsed as Map<String, dynamic>, dataValues list extracted
  → per-cell conflict resolution against local DataValuesTable rows
  → DataValueStore.applyServerValue(...) / markSynced(...) as each conflict resolves
  → caller (DataEntryRepositoryImpl) then reads the settled rows back from
    DataValueStore.valuesForForm(...) — the UI always renders from the LOCAL database,
    never directly from the API response
```

This last point is a recurring pattern in the codebase: **network responses are always
written to the local database first, then read back for display.** No screen renders a raw
API response directly.

## Connectivity detection — two different mechanisms, on purpose

There are two distinct connectivity concepts in this codebase; don't conflate them:

1. **`NetworkInfo`** (`lib/core/network/network_info.dart`) — a thin wrapper around
   `connectivity_plus`, answering "does the OS report a network interface". Used by
   `SyncCoordinator` to decide when to *attempt* a push, and by repositories
   (`DataEntryRepositoryImpl`, etc.) to decide whether to attempt a best-effort server call
   at all before falling back to local data.

2. **`ConnectivityService`** (`lib/core/network/connectivity_service.dart`) — the app-wide
   **ground truth** for the online/offline indicator shown in the UI. It does **not** trust
   the OS interface state (unreliable — "Linux Chrome often never fires [connectivity]
   events", per the code comment) and instead **actively probes** `GET
   {baseUrl}/system/ping` every 30 seconds, on every OS connectivity event, and on manual
   `checkNow()` calls. Any HTTP response — including a 401 — counts as "online", since it
   proves the server was reachable; only a transport-level failure (timeout, connection
   error) counts as offline. It deliberately uses a **bare** Dio client with no auth
   interceptor (a 401 here must never end the session) and sends
   `X-Requested-With: XMLHttpRequest` to stop an unauthenticated DHIS2 server from
   redirecting to an HTML login page that the browser would then block as mixed content —
   which would otherwise misread as "offline".

If you're adding a feature that needs to know "can I reach the server", prefer
`ConnectivityService.instance.online` for user-facing state and `NetworkInfo` for
sync-triggering logic — that's the existing split.
