import 'dart:convert';
import 'package:dio/dio.dart';
import '../../auth/app_session.dart';
import '../../router/app_router.dart';
import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Basic $token';
    }
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
      // Credentials rejected — drop the token AND end the in-memory
      // session (the router guard would otherwise bounce the user
      // straight back to home), then return to the login screen.
      // The local database and offline verifier are kept.
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
