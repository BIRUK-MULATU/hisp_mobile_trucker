import 'dart:convert';
import 'package:dio/dio.dart';
import '../../auth/app_session.dart';
import '../../router/app_router.dart';
import '../../storage/secure_storage.dart';

/// No credential is stored for this interceptor's client anymore — the
/// only authenticated client is per-session (AppSession.api, built from
/// in-memory credentials at login); requests that need auth go through
/// it. This interceptor keeps the default headers and the 401
/// session-end behavior.
class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Credentials rejected — purge any legacy stored token and end
      // the in-memory session (the router guard would otherwise bounce
      // the user straight back to home), then return to the login
      // screen. The local database and offline verifier are kept.
      await _secureStorage.deleteToken();
      await AppSession.instance.service.logout();
      AppSession.instance.sessionChanged();
      final currentPath =
          AppRouter.router.routerDelegate.currentConfiguration.uri.path;
      if (currentPath != AppRouter.login) {
        AppRouter.router.go('${AppRouter.login}?reason=session-expired');
      }
    }
    handler.next(err);
  }

  /// Build Basic Auth token from username and password
  static String buildBasicToken(String username, String password) {
    final credentials = '$username:$password';
    return base64Encode(utf8.encode(credentials));
  }
}
