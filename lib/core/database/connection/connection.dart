/// Platform-appropriate database connection for [AppDatabase].
///
/// Native (Android/iOS/desktop): one SQLite file per user under the app
/// documents directory. Web: drift's WasmDatabase (sqlite3.wasm +
/// drift_worker.js served from web/), persisted in OPFS/IndexedDB.
///
/// All three operations MUST stay per-user-key so multi-user isolation
/// (metadata cache + pending unsynced data) holds on every platform.
library;

export 'native.dart' if (dart.library.js_interop) 'web.dart';
