import 'package:dio/dio.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/auth/session_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Auth backed by the offline layer's [SessionService]:
///   online  -> server-verified login + metadata sync (full on first
///              login, delta after) into the per-user SQLite database
///   offline -> verified against the stored credential hash; the app
///              runs entirely on local data
///
/// The legacy remote datasource is still called after ONLINE logins as
/// transitional glue: it persists the Basic token + full /me payload
/// that the not-yet-migrated remote datasources (capture, data entry)
/// depend on. It goes away when those features read from the database.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;
  final SessionService _session;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorage secureStorage,
    SessionService? sessionService,
    NetworkInfo? networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage,
        _session = sessionService ?? AppSession.instance.service,
        _networkInfo = networkInfo ?? ConnectivityNetworkInfo();

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
  }) async {
    final serverUrl = await _serverRootUrl();
    final online = await _networkInfo.isConnected;

    LoginResult result;
    try {
      result = await _session.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
        online: online,
      );
    } on DioException {
      // Connectivity said online but the server was unreachable
      // (captive portal, server down): fall back to the offline path.
      result = await _session.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
        online: false,
      );
    }

    switch (result) {
      case LoginResult.onlineFirstSync:
      case LoginResult.onlineReturning:
        final user = await _remoteDataSource.login(
          username: username,
          password: password,
        );
        _attachSyncApi(serverUrl, username, password);
        AppSession.instance.sessionChanged();
        return user;

      case LoginResult.offline:
        // Verifier accepted -> these ARE the real credentials; keep an
        // authorized client so auto-sync can push when we come online.
        _attachSyncApi(serverUrl, username, password);
        final user = await _userFromDatabase(username);
        // Persist so legacy screens reading SecureStorage keep working.
        await _secureStorage.saveUserData(user.toJson());
        await _secureStorage.saveUsername(username);
        AppSession.instance.sessionChanged();
        return user;

      case LoginResult.offlineNoCache:
        throw const NetworkException(
            message: 'No internet connection, and this account has never '
                'logged in on this device. The first login needs a '
                'connection.');

      case LoginResult.invalidCredentials:
        throw const UnauthorizedException();
    }
  }

  @override
  Future<void> logout() async {
    // Ends the session but KEEPS the local database and credential
    // verifier, so the same user can log back in offline.
    await _session.logout();
    await _secureStorage.clearSession();
    AppSession.instance.api = null;
    AppSession.instance.sessionChanged();
  }

  @override
  Future<bool> isAuthenticated() async => _session.isLoggedIn;

  @override
  Future<UserEntity?> getCurrentUser() async {
    final data = await _secureStorage.getUserData();
    if (data == null) return null;
    try {
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ── internals ──────────────────────────────────────────────────────

  void _attachSyncApi(String serverUrl, String username, String password) {
    AppSession.instance.api = ApiClient.withBasicAuth(
      baseUrl: serverUrl,
      username: username,
      password: password,
    );
  }

  /// SessionService expects the server ROOT (it appends /api/... itself),
  /// while ApiConstants.baseUrl / the stored URL include the /api suffix.
  Future<String> _serverRootUrl() async {
    final stored = await _secureStorage.getBaseUrl();
    final url =
        (stored == null || stored.isEmpty) ? ApiConstants.baseUrl : stored;
    return url.replaceAll(RegExp(r'/api/?$'), '');
  }

  /// Offline login has no /me response — rebuild the user from the
  /// local database (users + capture-root org units, both populated by
  /// the metadata sync on the last online login).
  Future<UserModel> _userFromDatabase(String username) async {
    final db = _session.db;
    final users = await db.select(db.usersTable).get();
    final row = users.isNotEmpty ? users.first : null;

    final roots = await (db.select(db.orgUnitsTable)
          ..where((t) => t.isUserCaptureRoot.equals(true)))
        .get();

    return UserModel(
      id: row?.uid ?? '',
      username: row?.username ?? username,
      firstName: row?.displayName ?? username,
      surname: '',
      organisationUnits: [
        for (final ou in roots)
          OrgUnitModel(
            id: ou.uid,
            name: ou.displayName,
            code: ou.code,
            path: ou.path,
          ),
      ],
    );
  }
}
